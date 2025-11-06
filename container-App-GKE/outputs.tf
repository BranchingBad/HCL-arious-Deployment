output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The public endpoint of the GKE cluster."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "get_credentials_command" {
  description = "Command to configure kubectl."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}