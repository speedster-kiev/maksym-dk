variable "scaleway_access_key" {
  type      = string
  sensitive = true
}

variable "scaleway_secret_key" {
  type      = string
  sensitive = true
}

variable "organization_id" {
  description = "Scaleway organization ID (console > Organization settings)"
  type        = string
}

variable "region" {
  type    = string
  default = "fr-par"
}

variable "project_name" {
  type    = string
  default = "maksym-dk"
}

variable "site_bucket_name" {
  type    = string
  default = "maksym-dk-site"
}

variable "logs_bucket_name" {
  type    = string
  default = "maksym-dk-private"
}

variable "function_namespace_name" {
  type    = string
  default = "maksym-dk"
}

variable "domain" {
  type    = string
  default = "maksym.dk"
}

variable "public_email" {
  description = "Public contact email shown on the site"
  type        = string
}
