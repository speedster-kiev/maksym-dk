# Edge Services: HTTPS + custom domain in front of the site bucket.
# Chain (request order): [dns] -> tls -> cache -> route -> waf -> backend (S3 bucket).
# The DNS stage (custom domains) and head stage are NOT managed here: the Scaleway API
# returns 404 "Not Implemented" on POST /dns-stages (2026-10-02, provider 2.84.0).
# Attach maksym.dk and www.maksym.dk in the console (Edge Services > pipeline > Custom domain).
# DNS records at the registrar and the www -> apex redirect are manual too.

resource "scaleway_edge_services_plan" "site" {
  name       = "starter"
  project_id = scaleway_account_project.site.id
}

resource "scaleway_edge_services_pipeline" "web" {
  name       = "maksym-dk-web"
  project_id = scaleway_account_project.site.id
  depends_on = [scaleway_edge_services_plan.site]
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
