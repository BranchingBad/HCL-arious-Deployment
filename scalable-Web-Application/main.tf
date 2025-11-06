terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "resume-app-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.project_id
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # The load balancer and health checker IP ranges.
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["web-server"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance_template" "web_server_template" {
  name_prefix  = "web-server-template-"
  machine_type = "e2-small"
  region       = var.region
  project      = var.project_id

  tags = ["web-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app_subnet.id
    access_config {} # Ephemeral public IP
  }

  // Install a simple web server on boot
  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web_server_mig" {
  name    = "web-server-mig"
  region  = var.region
  project = var.project_id

  version {
    instance_template = google_compute_instance_template.web_server_template.id
  }

  base_instance_name = "web-server"
  target_size        = 2
}

resource "google_compute_health_check" "http_health_check" {
  name    = "http-basic-check"
  project = var.project_id

  http_health_check {
    port = 80
  }
}

resource "google_compute_region_backend_service" "web_backend" {
  name                  = "web-backend-service"
  region                = var.region
  project               = var.project_id
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_health_check.http_health_check.id]

  backend {
    group = google_compute_region_instance_group_manager.web_server_mig.instance_group
  }
}

resource "google_compute_url_map" "web_map" {
  name            = "web-map"
  project         = var.project_id
  default_service = google_compute_region_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-lb-proxy"
  project = var.project_id
  url_map = google_compute_url_map.web_map.id
}

resource "google_compute_forwarding_rule" "http_forwarding_rule" {
  name                  = "http-content-rule"
  project               = var.project_id
  region                = var.region
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.http_proxy.id
  load_balancing_scheme = "EXTERNAL"
}

output "load_balancer_ip" {
  description = "The public IP address of the HTTP load balancer."
  value       = google_compute_forwarding_rule.http_forwarding_rule.ip_address
}
