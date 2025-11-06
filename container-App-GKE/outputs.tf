output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The public endpoint of the GKE cluster's master."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "A command to configure kubectl for this cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
  sensitive   = true
}