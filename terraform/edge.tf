# Edge Services: HTTPS + custom domain in front of the site bucket.
# Chain (request order): dns -> tls -> cache -> route -> waf -> backend (S3 bucket).
# DNS records at the registrar stay manual. www -> apex redirect is not configured here yet.

resource "scaleway_edge_services_pipeline" "web" {
  name       = "maksym-dk-web"
  project_id = scaleway_account_project.site.id
}

resource "scaleway_edge_services_backend_stage" "site" {
  pipeline_id = scaleway_edge_services_pipeline.web.id
  s3_backend_config {
    bucket_name   = scaleway_object_bucket.site.name
    bucket_region = var.region
  }
}

resource "scaleway_edge_services_waf_stage" "site" {
  pipeline_id      = scaleway_edge_services_pipeline.web.id
  backend_stage_id = scaleway_edge_services_backend_stage.site.id
  mode             = "disable"
  paranoia_level   = 1
}

resource "scaleway_edge_services_route_stage" "site" {
  pipeline_id  = scaleway_edge_services_pipeline.web.id
  waf_stage_id = scaleway_edge_services_waf_stage.site.id
  rule {
    backend_stage_id = scaleway_edge_services_backend_stage.site.id
    rule_http_match {
      method_filters = ["get", "head", "options"]
      path_filter {
        path_filter_type = "regex"
        value            = ".*"
      }
    }
  }
}

resource "scaleway_edge_services_cache_stage" "site" {
  pipeline_id    = scaleway_edge_services_pipeline.web.id
  route_stage_id = scaleway_edge_services_route_stage.site.id
}

resource "scaleway_edge_services_tls_stage" "site" {
  pipeline_id         = scaleway_edge_services_pipeline.web.id
  cache_stage_id      = scaleway_edge_services_cache_stage.site.id
  managed_certificate = true
}

resource "scaleway_edge_services_dns_stage" "site" {
  pipeline_id  = scaleway_edge_services_pipeline.web.id
  tls_stage_id = scaleway_edge_services_tls_stage.site.id
  fqdns        = [var.domain, "www.${var.domain}"]
}

resource "scaleway_edge_services_head_stage" "site" {
  pipeline_id   = scaleway_edge_services_pipeline.web.id
  head_stage_id = scaleway_edge_services_dns_stage.site.id
}
