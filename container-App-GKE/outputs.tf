output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The PRIVATE endpoint of the GKE cluster's master."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "bastion_ssh_command" {
  description = "Command to SSH into the bastion host via IAP."
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --zone ${google_compute_instance.bastion.zone} --tunnel-through-iap --project ${var.project_id}"
}

output "kubeconfig" {
  description = "Command to configure kubectl (MUST be run on the Bastion host)."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id} --internal-ip"
  sensitive   = true
}