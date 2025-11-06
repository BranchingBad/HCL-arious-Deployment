terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
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

resource "random_pet" "suffix" {
  length = 2
}

resource "google_storage_bucket" "website" {
  # Bucket names must be globally unique. We append a random pet name to the prefix.
  name          = "${var.bucket_name_prefix}-${random_pet.suffix.id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  # Uniform bucket-level access is recommended for new buckets.
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "public_rule" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
}

output "website_url" {
  description = "The URL of the static website."
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/"
}
