terraform {
  # BACKEND CONFIGURATION: Replace placeholder with your actual state bucket name
  backend "gcs" {
    bucket = "YOUR_TERRAFORM_STATE_BUCKET"
    prefix = "terraform/state/static-website"
  }

  required_version = ">= 1.3.0"

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
  keepers = {
    prefix = var.bucket_name_prefix
  }
}

# ------------------------------------------------------------------------------
# LOGGING BUCKET
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "logs" {
  name                        = "${var.bucket_name_prefix}-logs-${random_pet.suffix.id}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  # IMPROVEMENT: Hardens security by explicitly blocking public access at the bucket level
  public_access_prevention = "enforced"

  # IMPROVEMENT: ARCHIVE class is much cheaper for data rarely accessed (like raw logs)
  storage_class = "ARCHIVE"

  labels = var.common_labels

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
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

  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  labels                      = var.common_labels

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "website-access/"
  }

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors {
    origin          = ["*"]
    # IMPROVEMENT: Tightened methods to only what is typically needed for static assets
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 2
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# ------------------------------------------------------------------------------
# INITIAL CONTENT UPLOAD (Demo Readiness)
# ------------------------------------------------------------------------------
# IMPROVEMENT: Uploads a basic index.html so the site works immediately upon apply.
resource "google_storage_bucket_object" "index" {
  name    = "index.html"
  bucket  = google_storage_bucket.website.name
  content = "<html><body><h1>Hello, World!</h1><p>Deployed via Terraform.</p></body></html>"
  content_type = "text/html"
}

resource "google_storage_bucket_object" "error" {
  name    = "404.html"
  bucket  = google_storage_bucket.website.name
  content = "<html><body><h1>404 - Not Found</h1></body></html>"
  content_type = "text/html"
}

# ------------------------------------------------------------------------------
# IAM CONFIGURATION
# ------------------------------------------------------------------------------
resource "google_storage_bucket_iam_member"