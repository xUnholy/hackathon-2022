
resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}




resource "google_container_cluster" "primary_a" {
  provider = google-beta
  name     = var.cluster_name_a
  location = var.zone
  min_master_version = data.google_container_engine_versions.versions.latest_node_version
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network = data.google_compute_subnetwork.my_gke_subnet_a.network
  subnetwork = data.google_compute_subnetwork.my_gke_subnet_a.self_link
  project = var.project_id
  networking_mode = "VPC_NATIVE"

  enable_kubernetes_alpha = false

  ip_allocation_policy {
    cluster_secondary_range_name = data.google_compute_subnetwork.my_gke_subnet_a.secondary_ip_range[0].range_name
    services_secondary_range_name = data.google_compute_subnetwork.my_gke_subnet_a.secondary_ip_range[1].range_name
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  workload_identity_config {
    workload_pool= "${var.project_id}.svc.id.goog"
  }

}

resource "google_container_node_pool" "primary_nodes_a" {
  name       = var.nodepool_name_a
  location   = var.zone
  cluster    = google_container_cluster.primary_a.name
  node_count = 2
  version = data.google_container_engine_versions.versions.latest_node_version

  node_config {
    #preemptible  = true
    #machine_type = "e2-medium"
    machine_type = "e2-standard-4"


    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}


resource "google_container_cluster" "primary_b" {
  provider = google-beta
  name     = var.cluster_name_b
  location = var.zone
  min_master_version = data.google_container_engine_versions.versions.latest_node_version
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  network = data.google_compute_subnetwork.my_gke_subnet_b.network
  subnetwork = data.google_compute_subnetwork.my_gke_subnet_b.self_link
  project = var.project_id
  networking_mode = "VPC_NATIVE"

  enable_kubernetes_alpha = false

  ip_allocation_policy {
    cluster_secondary_range_name = data.google_compute_subnetwork.my_gke_subnet_b.secondary_ip_range[0].range_name
    services_secondary_range_name = data.google_compute_subnetwork.my_gke_subnet_b.secondary_ip_range[1].range_name
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  workload_identity_config {
    workload_pool= "${var.project_id}.svc.id.goog"
  }

}

resource "google_container_node_pool" "primary_nodes_b" {
  name       = var.nodepool_name_b
  location   = var.zone
  cluster    = google_container_cluster.primary_b.name
  node_count = 2
  version = data.google_container_engine_versions.versions.latest_node_version

  node_config {
    #preemptible  = true
    #machine_type = "e2-medium"
    machine_type = "e2-standard-4"


    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
