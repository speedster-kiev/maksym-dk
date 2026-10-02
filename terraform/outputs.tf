output "site_project_id" {
  value = scaleway_account_project.site.id
}

output "private_project_id" {
  value = scaleway_account_project.private.id
}

output "site_bucket_website_endpoint" {
  value = scaleway_object_bucket_website_configuration.site.website_endpoint
}

output "edge_pipeline_id" {
  value = scaleway_edge_services_pipeline.web.id
}

output "publisher_access_key" {
  value = scaleway_iam_api_key.publisher.access_key
}

output "publisher_secret_key" {
  value     = scaleway_iam_api_key.publisher.secret_key
  sensitive = true
}

output "log_reader_access_key" {
  value = scaleway_iam_api_key.log_reader.access_key
}

output "log_reader_secret_key" {
  value     = scaleway_iam_api_key.log_reader.secret_key
  sensitive = true
}
