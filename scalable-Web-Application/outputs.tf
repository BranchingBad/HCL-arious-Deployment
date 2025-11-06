output "load_balancer_ip" {
  description = "The public IP address of the HTTP load balancer."
  value       = "http://${google_compute_forwarding_rule.http_rule.ip_address}"
}

output "mig_self_link" {
  description = "The self-link of the managed instance group."
  value       = google_compute_region_instance_group_manager.web_mig.instance_group
}