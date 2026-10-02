output "project_id" {
  description = "Scaleway project ID"
  value       = scaleway_account_project.maksym_dk.id
}

output "site_bucket_name" {
  description = "Public site bucket name"
  value       = scaleway_object_bucket.site.name
}

output "site_bucket_endpoint" {
  description = "Public site bucket website endpoint"
  value       = "https://${scaleway_object_bucket.site.name}.fr-par.scw.cloud"
}

output "logs_bucket_name" {
  description = "Private logs bucket name"
  value       = scaleway_object_bucket.logs.name
}

output "logs_bucket_endpoint" {
  description = "Logs bucket S3 endpoint"
  value       = "https://s3.${var.scaleway_region}.scw.cloud"
}

output "publisher_api_key" {
  description = "Publisher app API access key (for .env S3_ACCESS_KEY)"
  value       = scaleway_iam_api_key.publisher.access_key
  sensitive   = true
}

output "publisher_secret_key" {
  description = "Publisher app API secret key (for .env S3_SECRET_KEY)"
  value       = scaleway_iam_api_key.publisher.secret_key
  sensitive   = true
}

output "fn_chat_api_key" {
  description = "Chat function API access key (for function secrets)"
  value       = scaleway_iam_api_key.fn_chat.access_key
  sensitive   = true
}

output "fn_chat_secret_key" {
  description = "Chat function API secret key (for function secrets)"
  value       = scaleway_iam_api_key.fn_chat.secret_key
  sensitive   = true
}

output "log_reader_api_key" {
  description = "Log reader app API access key (for .env LOG_S3_ACCESS_KEY)"
  value       = scaleway_iam_api_key.log_reader.access_key
  sensitive   = true
}

output "log_reader_secret_key" {
  description = "Log reader app API secret key (for .env LOG_S3_SECRET_KEY)"
  value       = scaleway_iam_api_key.log_reader.secret_key
  sensitive   = true
}

output "function_namespace_id" {
  description = "Functions namespace ID"
  value       = scaleway_function_namespace.chat.id
}

output "function_namespace_name" {
  description = "Functions namespace name"
  value       = scaleway_function_namespace.chat.name
}

output "env_file_template" {
  description = "Template for .env file with values from Terraform"
  value = "# Generated from Terraform — fill in your domain and email\n\nLLM_BASE_URL=https://api.scaleway.ai/v1\nLLM_API_KEY=${scaleway_iam_api_key.publisher.secret_key}\nCHAT_MODEL=gemma-4-26b-a4b-it\nEXPORT_MODEL=gemma-4-26b-a4b-it\n\nPROFILE_URL=https://${var.domain}/data/profile.json\nALLOWED_ORIGINS=https://${var.domain},https://www.${var.domain}\nCHAT_ENABLED=true\nPUBLIC_EMAIL=${var.public_email}\n\nS3_ENDPOINT=https://s3.${var.scaleway_region}.scw.cloud\nS3_REGION=${var.scaleway_region}\nS3_ACCESS_KEY=${scaleway_iam_api_key.publisher.access_key}\nS3_SECRET_KEY=${scaleway_iam_api_key.publisher.secret_key}\nSITE_BUCKET=${scaleway_object_bucket.site.name}\nLOG_BUCKET=${scaleway_object_bucket.logs.name}\n\nSOURCE_DIR=/path/to/your/markdown/files\nSOURCE_IGNORE=node_modules/**,.*\n"
  sensitive   = true
}
