data "google_compute_subnetwork" "my_gke_subnet_a" {
  name    = var.subnet_name_a
  project = var.project_id
}

data "google_compute_subnetwork" "my_gke_subnet_b" {
  name    = var.subnet_name_b
  project = var.project_id
}


data "google_container_engine_versions" "versions"{
  provider = google-beta
  location = var.region
  version_prefix = var.min_gke_version
}
