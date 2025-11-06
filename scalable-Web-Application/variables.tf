variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy resources."
  type        = string
  default     = "us-central1"
}

# IMPROVEMENT: Environment prefix for resource naming
variable "env_prefix" {
  description = "Prefix for resource names (e.g., prod, dev, staging)."
  type        = string
  default     = "dev"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-small"
}

variable "min_replicas" {
  description = "Minimum number of MIG instances."
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of MIG instances."
  type        = number
  default     = 5
}