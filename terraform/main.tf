terraform {
  required_version = ">= 1.0"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  zone       = var.scaleway_zone
  region     = var.scaleway_region
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key
}

# Project
resource "scaleway_account_project" "maksym_dk" {
  name        = var.project_name
  description = "Personal homepage with AI chat assistant"
}

# ============================================================================
# Object Storage Buckets
# ============================================================================

# Bucket A: Public site + profile
resource "scaleway_object_bucket" "site" {
  name   = var.site_bucket_name
  region = var.scaleway_region

  tags = {
    environment = "production"
    purpose     = "website"
  }
}

resource "scaleway_object_bucket_website_configuration" "site" {
  bucket = scaleway_object_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

# Make Bucket A public
resource "scaleway_object_bucket_public_access_block" "site" {
  bucket = scaleway_object_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket A policy: allow public read
resource "scaleway_object_bucket_policy" "site" {
  bucket = scaleway_object_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${scaleway_object_bucket.site.arn}/*"
      }
    ]
  })
}

# Upload placeholder
resource "scaleway_object" "placeholder" {
  bucket = scaleway_object_bucket.site.id
  key    = "index.html"
  content = "<h1>maksym.dk — coming soon</h1>"
  content_type = "text/html"
}

# Bucket B: Private logs
resource "scaleway_object_bucket" "logs" {
  name   = var.logs_bucket_name
  region = var.scaleway_region

  tags = {
    environment = "production"
    purpose     = "logs"
  }
}

# Make Bucket B private
resource "scaleway_object_bucket_public_access_block" "logs" {
  bucket = scaleway_object_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 90-day lifecycle rule for logs
resource "scaleway_object_bucket_lifecycle_configuration" "logs" {
  bucket = scaleway_object_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    expiration {
      days = 90
    }
  }
}

# ============================================================================
# IAM Applications (least privilege)
# ============================================================================

# Publisher app: write to Bucket A + Generative APIs
resource "scaleway_iam_application" "publisher" {
  name        = var.iam_publisher_name
  description = "Publish script: upload site and profile to Bucket A"
}

resource "scaleway_iam_policy" "publisher_bucket_a" {
  name           = "publisher-bucket-a"
  application_id = scaleway_iam_application.publisher.id

  rule {
    project_ids = [scaleway_account_project.maksym_dk.id]
    permissions = [
      "ObjectStorageObjectsWrite",
      "ObjectStorageObjectsRead"
    ]
    resources = [
      scaleway_object_bucket.site.arn,
      "${scaleway_object_bucket.site.arn}/*"
    ]
  }
}

resource "scaleway_iam_policy" "publisher_genai" {
  name           = "publisher-genai"
  application_id = scaleway_iam_application.publisher.id

  rule {
    project_ids = [scaleway_account_project.maksym_dk.id]
    permissions = [
      "aiGenerativeApisLLMUsersManage"
    ]
  }
}

# Chat function app: write to Bucket B only + Generative APIs
resource "scaleway_iam_application" "fn_chat" {
  name        = var.iam_fn_chat_name
  description = "Chat function: log questions to Bucket B, call LLM"
}

resource "scaleway_iam_policy" "fn_chat_bucket_b" {
  name           = "fn-chat-bucket-b"
  application_id = scaleway_iam_application.fn_chat.id

  rule {
    project_ids = [scaleway_account_project.maksym_dk.id]
    permissions = [
      "ObjectStorageObjectsWrite"
    ]
    resources = [
      scaleway_object_bucket.logs.arn,
      "${scaleway_object_bucket.logs.arn}/*"
    ]
  }
}

resource "scaleway_iam_policy" "fn_chat_genai" {
  name           = "fn-chat-genai"
  application_id = scaleway_iam_application.fn_chat.id

  rule {
    project_ids = [scaleway_account_project.maksym_dk.id]
    permissions = [
      "aiGenerativeApisLLMUsersManage"
    ]
  }
}

# Log reader app: read Bucket B only
resource "scaleway_iam_application" "log_reader" {
  name        = var.iam_log_reader_name
  description = "Logs CLI: read question logs from Bucket B"
}

resource "scaleway_iam_policy" "log_reader_bucket_b" {
  name           = "log-reader-bucket-b"
  application_id = scaleway_iam_application.log_reader.id

  rule {
    project_ids = [scaleway_account_project.maksym_dk.id]
    permissions = [
      "ObjectStorageObjectsRead"
    ]
    resources = [
      scaleway_object_bucket.logs.arn,
      "${scaleway_object_bucket.logs.arn}/*"
    ]
  }
}

# API keys for each app
resource "scaleway_iam_api_key" "publisher" {
  application_id = scaleway_iam_application.publisher.id
  description    = "Publisher API key for npm run publish"
}

resource "scaleway_iam_api_key" "fn_chat" {
  application_id = scaleway_iam_application.fn_chat.id
  description    = "Chat function API key"
}

resource "scaleway_iam_api_key" "log_reader" {
  application_id = scaleway_iam_application.log_reader.id
  description    = "Log reader API key for npm run logs"
}

# ============================================================================
# Functions Namespace
# ============================================================================

resource "scaleway_function_namespace" "chat" {
  name        = var.function_namespace_name
  description = "Chat function and environment"
  region      = var.scaleway_region

  environment_variables = {
    LLM_BASE_URL       = "https://api.scaleway.ai/v1"
    CHAT_MODEL         = "gemma-4-26b-a4b-it"
    PROFILE_URL        = "https://${var.domain}/data/profile.json"
    ALLOWED_ORIGINS    = "https://${var.domain},https://www.${var.domain}"
    CHAT_ENABLED       = "true"
    PUBLIC_EMAIL       = var.public_email
    S3_ENDPOINT        = "https://s3.${var.scaleway_region}.scw.cloud"
    S3_REGION          = var.scaleway_region
    SITE_BUCKET        = scaleway_object_bucket.site.name
    LOG_BUCKET         = scaleway_object_bucket.logs.name
  }

  secret_environment_variables = {
    LLM_API_KEY    = scaleway_iam_api_key.fn_chat.secret_key
    S3_ACCESS_KEY  = scaleway_iam_api_key.fn_chat.access_key
    S3_SECRET_KEY  = scaleway_iam_api_key.fn_chat.secret_key
  }

  tags = {
    environment = "production"
  }
}

# ============================================================================
# Billing Alerts
# ============================================================================

resource "scaleway_billing_alert" "one_euro" {
  alert_threshold_in_cents = 100
  alert_email              = var.alert_email
}

resource "scaleway_billing_alert" "five_euros" {
  alert_threshold_in_cents = 500
  alert_email              = var.alert_email
}
