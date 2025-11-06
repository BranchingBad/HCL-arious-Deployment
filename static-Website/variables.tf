variable "project_id" {
  description = "The GCP project ID."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id must not be empty."
  }
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "US"

  validation {
    condition     = length(var.region) > 0
    error_message = "The region must not be empty."
  }
}

variable "bucket_name_prefix" {
  description = "Prefix for the GCS bucket name. A random suffix will be appended."
  type        = string
  default     = "resume-website"

  validation {
    condition     = length(var.bucket_name_prefix) > 0 && can(regex("^[a-z0-9-]+$", var.bucket_name_prefix))
    error_message = "Bucket prefix must not be empty and can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "common_labels" {
  description = "Labels to apply to all resources for billing and organization."
  type        = map(string)
  default = {
    environment = "dev"
    project     = "resume-website"
    managed_by  = "terraform"
  }
}