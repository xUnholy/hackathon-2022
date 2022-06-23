// Forwarding rule for Internal Load Balancing
resource "google_compute_global_forwarding_rule" "my-global-fr" {
  count       = var.enabled ? 1 : 0
  provider    = google-beta
  name        = var.name
  description = var.desc
  ip_address = data.google_compute_global_address.external-lb-ip.address
  #ip_address  = "34.107.244.107"
  project = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = var.ports
  target                = google_compute_target_http_proxy.proxy[0].id
}

resource "google_compute_target_http_proxy" "proxy" {
  count            = var.enabled ? 1 : 0
  provider = google-beta
  #region           = "australia-southeast2"
  name             = var.name
  description      = var.desc
  url_map          = google_compute_url_map.url_map[0].id
  #ssl_certificates = [google_compute_ssl_certificate.default.id]
}


resource "google_compute_url_map" "url_map" {
  count    = var.enabled ? 1 : 0
  provider = google-beta


  project = var.project_id

  name        = var.name
  description = var.desc
  host_rule {
    hosts        = ["cluster-a.chaosmonkeys.net"  ]
    path_matcher = "cluster-a"
  }
  host_rule {
    hosts        = ["cluster-b.chaosmonkeys.net" ]
    path_matcher = "cluster-b"
  }
  default_service = google_compute_backend_service.neg_backend_a.id

  path_matcher {
    name = "cluster-a"
    default_service = google_compute_backend_service.neg_backend_a.id

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
      }

      service = google_compute_backend_service.neg_backend_a.id
    }
  }

  path_matcher {
    name = "cluster-b"
    default_service = google_compute_backend_service.neg_backend_b.id

    route_rules {
      priority = 1
      match_rules {
        prefix_match = "/"
      }

      service = google_compute_backend_service.neg_backend_b.id
    }
  }

}

resource "google_compute_backend_service" "neg_backend_a" {

  provider = google-beta
  project = var.project_id

  load_balancing_scheme = "EXTERNAL"

  backend {
    group = "https://www.googleapis.com/compute/v1/projects/rising-capsule-353505/zones/australia-southeast2-b/networkEndpointGroups/neg-a-80"
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 50

  }

  name     = var.name
  protocol = "HTTP"

  log_config {
    enable      = true
    sample_rate = 1
  }
  
  timeout_sec = 30

  health_checks = [google_compute_health_check.health_check[0].id]
}


resource "google_compute_backend_service" "neg_backend_b" {

  provider = google-beta
  project = var.project_id

  load_balancing_scheme = "EXTERNAL"

  backend {
    group = "https://www.googleapis.com/compute/v1/projects/rising-capsule-353505/zones/australia-southeast2-b/networkEndpointGroups/neg-b-80"
    balancing_mode        = "RATE"
    max_rate_per_endpoint = 50

  }

  name     = "backend-b"
  protocol = "HTTP"

  log_config {
    enable      = true
    sample_rate = 1
  }

  timeout_sec = 30

  health_checks = [google_compute_health_check.health_check_b.id]
}



resource "google_compute_health_check" "health_check" {
  count       = var.enabled ? 1 : 0
  name        = var.name
  description = "Health check via http"

  project = var.project_id
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 4
  unhealthy_threshold = 5

  http_health_check {
    port         = 15021
    request_path = "/healthz/ready"
  }

}

resource "google_compute_health_check" "health_check_b" {
  name        = "hc-b"
  description = "Health check via http"

  project = var.project_id
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 4
  unhealthy_threshold = 5

  http_health_check {
    port         = 15021
    request_path = "/healthz/ready"
  }

}
