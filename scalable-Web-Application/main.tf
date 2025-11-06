terraform {
  # backend "gcs" { ... }

  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ==============================================================================
# IAM & SECURITY
# ==============================================================================
resource "google_service_account" "web_sa" {
  account_id   = "${var.env_prefix}-web-sa"
  display_name = "Web Server SA (${var.env_prefix})"
}

resource "google_project_iam_member" "web_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.web_sa.email}"
}

resource "google_project_iam_member" "web_sa_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.web_sa.email}"
}

# ==============================================================================
# NETWORK
# ==============================================================================
resource "google_compute_network" "vpc_network" {
  name                    = "${var.env_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "${var.env_prefix}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "router" {
  name    = "${var.env_prefix}-router"
  region  = var.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.env_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_lb" {
  name    = "${var.env_prefix}-allow-lb"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Google Load Balancer IP ranges
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-server"]
}

# IMPROVEMENT: ALLOW IAP SSH
# Enables secure SSH access via Google Cloud Console without public IPs
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.env_prefix}-allow-iap-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IP range used by Identity-Aware Proxy
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["web-server"]
}

# ==============================================================================
# COMPUTE
# ==============================================================================
resource "google_compute_instance_template" "web_server" {
  name_prefix  = "${var.env_prefix}-template-"
  machine_type = var.machine_type
  region       = var.region
  tags         = ["web-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnet.id
    # Implicitly private because no access_config block is present
  }

  service_account {
    email  = google_service_account.web_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update && apt-get install -y nginx
    echo "<h1>${var.env_prefix} environment</h1><p>Host: $(hostname)</p>" > /var/www/html/index.html
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web_mig" {
  name   = "${var.env_prefix}-mig"
  region = var.region
  version {
    instance_template = google_compute_instance_template.web_server.id
  }
  base_instance_name = "${var.env_prefix}-web"

  # IMPROVEMENT: ROLLING UPDATE POLICY
  # Ensures zero-downtime updates by creating new instances before deleting old ones
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }
}

resource "google_compute_region_autoscaler" "web_autoscaler" {
  name   = "${var.env_prefix}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.web_mig.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = 60
    cpu_utilization {
      target = 0.6
    }
  }
}

# ==============================================================================
# LOAD BALANCER
# ==============================================================================
resource "google_compute_health_check" "http_basic" {
  name = "${var.env_prefix}-health-check"

  # IMPROVEMENT: TUNED HEALTH CHECK
  # Faster detection of failures than default settings
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port = 80
  }
}

resource "google_compute_region_backend_service" "web_backend" {
  name                  = "${var.env_prefix}-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.http_basic.id]
  backend {
    group          = google_compute_region_instance_group_manager.web_mig.instance_group
    balancing_mode = "UTILIZATION"
  }
}

resource "google_compute_url_map" "web_map" {
  name            = "${var.env_prefix}-url-map"
  default_service = google_compute_region_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.env_prefix}-http-proxy"
  url_map = google_compute_url_map.web_map.id
}

resource "google_compute_forwarding_rule" "http_rule" {
  name                  = "${var.env_prefix}-forwarding-rule"
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL"
}