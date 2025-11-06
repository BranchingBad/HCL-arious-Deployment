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

variable "machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

# IMPROVEMENT: Replaced fixed node count with scaling ranges
variable "min_nodes" {
  description = "Minimum number of nodes per zone."
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes per zone."
  type        = number
  default     = 3
}