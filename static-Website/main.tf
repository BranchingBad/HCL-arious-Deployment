terraform {
  # BACKEND CONFIGURATION: Replace placeholder with your actual state bucket name
  backend "gcs" {
    bucket = "YOUR_TERRAFORM_STATE_BUCKET"
    prefix = "terraform/state/static-website"
  }

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

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "random_pet" "suffix" {
  length = 2
}

# ------------------------------------------------------------------------------
# LOGGING BUCKET
# ------------------------------------------------------------------------------
# A separate bucket to store access logs for the website.
resource "google_storage_bucket" "logs" {
  name          = "${var.bucket_name_prefix}-logs-${random_pet.suffix.id}"
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true

  # Automatically delete logs older than 30 days to save costs
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# ------------------------------------------------------------------------------
# MAIN WEBSITE BUCKET
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "website" {
  name          = "${var.bucket_name_prefix}-${random_pet.suffix.id}"
  location      = var.region
  force_destroy = true

  # Enable uniform bucket-level access for better security management
  uniform_bucket_level_access = true

  # Enable versioning to recover from accidental overwrites/deletes
  versioning {
    enabled = true
  }

  # Configure access logging to the logs bucket created above
  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "website-access/"
  }

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# ------------------------------------------------------------------------------
# IAM CONFIGURATION
# ------------------------------------------------------------------------------
# Makes the bucket content publicly readable.
# Uses 'google_storage_bucket_iam_member' for non-authoritative updates.
resource "google_storage_bucket_iam_member" "public_rule" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}