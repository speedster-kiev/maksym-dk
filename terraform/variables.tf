variable "scaleway_access_key" {
  description = "Scaleway API access key"
  type        = string
  sensitive   = true
}

variable "scaleway_secret_key" {
  description = "Scaleway API secret key"
  type        = string
  sensitive   = true
}

variable "scaleway_region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "scaleway_zone" {
  description = "Scaleway zone"
  type        = string
  default     = "fr-par-1"
}

variable "project_name" {
  description = "Scaleway project name"
  type        = string
  default     = "maksym-dk"
}

variable "site_bucket_name" {
  description = "Public site bucket name"
  type        = string
  default     = "maksym-dk-site"
}

variable "logs_bucket_name" {
  description = "Private logs bucket name"
  type        = string
  default     = "maksym-dk-private"
}

variable "iam_publisher_name" {
  description = "IAM app for the publisher tool"
  type        = string
  default     = "publisher"
}

variable "iam_fn_chat_name" {
  description = "IAM app for the chat function"
  type        = string
  default     = "fn-chat"
}

variable "iam_log_reader_name" {
  description = "IAM app for the log reader tool"
  type        = string
  default     = "log-reader"
}

variable "function_namespace_name" {
  description = "Functions namespace name"
  type        = string
  default     = "maksym-dk"
}

variable "domain" {
  description = "Your domain (e.g., maksym.dk)"
  type        = string
}

variable "public_email" {
  description = "Public contact email shown on the site"
  type        = string
}

variable "alert_email" {
  description = "Email for billing alerts"
  type        = string
}
