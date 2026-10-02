terraform {
  required_version = ">= 1.3"
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  access_key      = var.scaleway_access_key
  secret_key      = var.scaleway_secret_key
  organization_id = var.organization_id
  region          = var.region
}

# Two projects: IAM scopes to projects, not buckets, so the private log bucket
# lives in its own project to keep it isolated from the public site bucket.
resource "scaleway_account_project" "site" {
  name        = var.project_name
  description = "maksym.dk site, chat function, edge"
}

resource "scaleway_account_project" "private" {
  name        = "${var.project_name}-private"
  description = "maksym.dk private chat logs"
}

# ---------------------------------------------------------------- Buckets

resource "scaleway_object_bucket" "site" {
  name       = var.site_bucket_name
  project_id = scaleway_account_project.site.id
}

resource "scaleway_object_bucket_acl" "site" {
  bucket     = scaleway_object_bucket.site.name
  project_id = scaleway_account_project.site.id
  acl        = "public-read"
}

resource "scaleway_object_bucket_policy" "site_public_read" {
  bucket     = scaleway_object_bucket.site.name
  project_id = scaleway_account_project.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "PublicRead"
    Statement = [{
      Sid       = "GrantToEveryone"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = ["${scaleway_object_bucket.site.name}/*"]
    }]
  })
}

resource "scaleway_object_bucket_website_configuration" "site" {
  bucket     = scaleway_object_bucket.site.name
  project_id = scaleway_account_project.site.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}

resource "scaleway_object" "placeholder" {
  bucket       = scaleway_object_bucket.site.name
  project_id   = scaleway_account_project.site.id
  key          = "index.html"
  content      = "<!doctype html><meta charset=\"utf-8\"><title>maksym.dk</title><h1>maksym.dk - coming soon</h1>"
  content_type = "text/html"
  visibility   = "public-read"
}

resource "scaleway_object_bucket" "logs" {
  name       = var.logs_bucket_name
  project_id = scaleway_account_project.private.id

  lifecycle_rule {
    id      = "expire-logs"
    prefix  = "logs/"
    enabled = true
    expiration {
      days = 90
    }
  }
}

# ---------------------------------------------------------------- IAM

resource "scaleway_iam_application" "publisher" {
  name        = "publisher"
  description = "npm run publish: uploads site to the site bucket, calls the export LLM"
}

resource "scaleway_iam_application" "fn_chat" {
  name        = "fn-chat"
  description = "Chat function: writes logs, calls the chat LLM"
}

resource "scaleway_iam_application" "log_reader" {
  name        = "log-reader"
  description = "npm run logs: reads question logs"
}

# NOTE: permission set names are not verifiable offline. If apply rejects one,
# list valid names with the Scaleway console policy editor or `scw iam permission-set list`.
resource "scaleway_iam_policy" "publisher" {
  name           = "publisher"
  application_id = scaleway_iam_application.publisher.id
  rule {
    project_ids          = [scaleway_account_project.site.id]
    permission_set_names = ["ObjectStorageObjectsRead", "ObjectStorageObjectsWrite", "ObjectStorageObjectsDelete", "GenerativeApisModelAccess"]
  }
}

resource "scaleway_iam_policy" "fn_chat" {
  name           = "fn-chat"
  application_id = scaleway_iam_application.fn_chat.id
  rule {
    project_ids          = [scaleway_account_project.private.id]
    permission_set_names = ["ObjectStorageObjectsWrite"]
  }
  rule {
    project_ids          = [scaleway_account_project.site.id]
    permission_set_names = ["GenerativeApisModelAccess"]
  }
}

resource "scaleway_iam_policy" "log_reader" {
  name           = "log-reader"
  application_id = scaleway_iam_application.log_reader.id
  rule {
    project_ids          = [scaleway_account_project.private.id]
    permission_set_names = ["ObjectStorageObjectsRead", "ObjectStorageBucketsRead"]
  }
}

resource "scaleway_iam_api_key" "publisher" {
  application_id     = scaleway_iam_application.publisher.id
  description        = "publisher"
  default_project_id = scaleway_account_project.site.id

  lifecycle {
    ignore_changes = [expires_at]
  }
}

resource "scaleway_iam_api_key" "fn_chat" {
  application_id     = scaleway_iam_application.fn_chat.id
  description        = "fn-chat"
  default_project_id = scaleway_account_project.private.id

  lifecycle {
    ignore_changes = [expires_at]
  }
}

resource "scaleway_iam_api_key" "log_reader" {
  application_id     = scaleway_iam_application.log_reader.id
  description        = "log-reader"
  default_project_id = scaleway_account_project.private.id

  lifecycle {
    ignore_changes = [expires_at]
  }
}

# ---------------------------------------------------------------- Functions

resource "scaleway_function_namespace" "chat" {
  name       = var.function_namespace_name
  project_id = scaleway_account_project.site.id
  region     = var.region

  environment_variables = {
    LLM_BASE_URL    = "https://api.scaleway.ai/v1"
    CHAT_MODEL      = "gemma-4-26b-a4b-it"
    PROFILE_URL     = "https://${var.domain}/data/profile.json"
    ALLOWED_ORIGINS = "https://${var.domain},https://www.${var.domain}"
    CHAT_ENABLED    = "true"
    PUBLIC_EMAIL    = var.public_email
    S3_ENDPOINT     = "https://s3.${var.region}.scw.cloud"
    S3_REGION       = var.region
    LOG_BUCKET      = scaleway_object_bucket.logs.name
  }

  secret_environment_variables = {
    LLM_API_KEY   = scaleway_iam_api_key.fn_chat.secret_key
    S3_ACCESS_KEY = scaleway_iam_api_key.fn_chat.access_key
    S3_SECRET_KEY = scaleway_iam_api_key.fn_chat.secret_key
  }
}
