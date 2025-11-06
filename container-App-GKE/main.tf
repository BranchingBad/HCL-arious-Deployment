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
  description = "The region to create the GKE cluster in."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name for the GKE cluster."
  type        = string
  default     = "resume-gke-cluster"
}

variable "gke_num_nodes" {
  description = "The number of nodes in the GKE node pool."
  type        = number
  default     = 1
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # We are using a separately managed node pool, so we will remove the default one.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = google_container_cluster.primary.location
  cluster    = google_container_cluster.primary.name
  project    = var.project_id
  node_count = var.gke_num_nodes

  # Configuration for the nodes in the pool
  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Required for regional clusters
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

output "kubeconfig" {
  description = "A command to configure kubectl for this cluster."
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
  sensitive = true
}

output "cluster_endpoint" {
  description = "The public endpoint of the GKE cluster."
  value       = google_container_cluster.primary.endpoint
}
