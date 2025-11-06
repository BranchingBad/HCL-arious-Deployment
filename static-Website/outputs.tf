output "website_url" {
  description = "The public URL of the static website."
  value       = "https://storage.googleapis.com/${google_storage_bucket.website.name}/"
}

output "website_bucket_name" {
  description = "The name of the GCS bucket hosting the website."
  value       = google_storage_bucket.website.name
}
