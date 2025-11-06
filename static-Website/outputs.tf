output "website_url" {
  description = "The HTTPS URL of the static website."
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/index.html"
}

output "website_bucket_uri" {
  description = "The gs:// URI of the website bucket, useful for gsutil/gcloud commands."
  value       = "gs://${google_storage_bucket.website.name}"
}

output "website_bucket_name" {
  description = "The name of the GCS bucket hosting the website."
  value       = google_storage_bucket.website.name
}

output "logs_bucket_name" {
  description = "The name of the GCS bucket storing access logs."
  value       = google_storage_bucket.logs.name
}