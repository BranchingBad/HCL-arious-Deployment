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
}

variable "bucket_name_prefix" {
  description = "Prefix for the GCS bucket name. A random suffix will be appended."
  type        = string
  default     = "resume-website"
}