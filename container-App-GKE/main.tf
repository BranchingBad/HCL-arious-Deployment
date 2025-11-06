terraform {
  # RECOMMENDED: Add your GCS backend block here
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
# NETWORK (VPC-Native Standard + Cloud NAT)
# ==============================================================================
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/24"

  # Secondary ranges for VPC-native cluster
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.48.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.52.0.0/20"
  }

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# IMPROVEMENT: Cloud NAT for Private Nodes
# Since nodes won't have public IPs, they need NAT to pull external Docker images.
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# ==============================================================================
# BASTION HOST & IAP
# ==============================================================================
resource "google_service_account" "bastion_sa" {
  account_id   = "bastion-sa"
  display_name = "Bastion Service Account"
}

# Allow IAP to connect to instances with 'bastion' tag via SSH
resource "google_compute_firewall" "iap_ssh" {
  name    = "${var.cluster_name}-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion"]
}

# trivy:ignore:AVD-GCP-0030
resource "google_compute_instance" "bastion" {
  name         = "${var.cluster_name}-bastion"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  tags         = ["bastion"]

  metadata = {
    "block-project-ssh-keys" = "true"
  }

  # trivy:ignore:AVD-GCP-0033
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    # No access_config block ensures NO public IP
  }

  service_account {
    email  = google_service_account.bastion_sa.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin tinyproxy
    # Optional: Configure Tinyproxy to allow localhost for simple tunneling
    sed -i 's/Allow 127.0.0.1/#Allow 127.0.0.1/' /etc/tinyproxy/tinyproxy.conf
    echo "Allow localhost" >> /etc/tinyproxy/tinyproxy.conf
    systemctl restart tinyproxy
  EOT

  shielded_instance_config {
    enable_secure_boot          = true
    enable_integrity_monitoring = true
  }
}

# ==============================================================================
# IAM & SECURITY (GKE)
# ==============================================================================
resource "google_service_account" "gke_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

resource "google_project_iam_member" "artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# ==============================================================================
# GKE CLUSTER
# ==============================================================================
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name

  resource_labels = {
    env = var.cluster_name
  }

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # IMPROVEMENT: PRIVATE CLUSTER & ENDPOINT
  # Nodes have internal IPs ONLY.
  # Master endpoint is also PRIVATE, accessible only from within the VPC (e.g., Bastion).
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # IMPROVEMENT: RELEASE CHANNEL
  # Offloads K8s version management to Google.
  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  master_authorized_networks_config {
    cidr_blocks {
      # trivy:ignore:AVD-GCP-0053
      cidr_block   = google_compute_subnetwork.subnet.ip_cidr_range
      display_name = "VPC Subnet (Bastion Access)"
    }
  }

  # Network Policy (requires Dataplane V2 or Calico)
  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
  }

  depends_on = [
    google_project_iam_member.log_writer,
    google_project_iam_member.metric_writer
  ]
}

# ==============================================================================
# NODE POOL (AUTOSCALING)
# ==============================================================================
resource "google_container_node_pool" "primary_nodes" {
  name     = "${google_container_cluster.primary.name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name

  # IMPROVEMENT: AUTOSCALING
  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    image_type      = "COS_CONTAINERD"

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      env = var.cluster_name
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}