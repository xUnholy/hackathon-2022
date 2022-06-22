

resource "google_compute_subnetwork" "gke_subnet_a" {
  name          = var.subnetwork_name_a.name
  ip_cidr_range = var.subnetwork_name_a.range
  region        = var.region
  network       = google_compute_network.my_gke.id

  dynamic "secondary_ip_range" {
    for_each = var.secondary_ranges_a
    content {
      range_name =   secondary_ip_range.value.name
      ip_cidr_range =  secondary_ip_range.value.cidr
    }

  }
}

resource "google_compute_subnetwork" "gke_subnet_b" {
  name          = var.subnetwork_name_b.name
  ip_cidr_range = var.subnetwork_name_b.range
  region        = var.region
  network       = google_compute_network.my_gke.id

  dynamic "secondary_ip_range" {
    for_each = var.secondary_ranges_b
    content {
      range_name =   secondary_ip_range.value.name
      ip_cidr_range =  secondary_ip_range.value.cidr
    }

  }
}

//auto_create_subnetworks - (Optional) When set to true,
//the network is created in "auto subnet mode"
//and it will create a subnet for each region automatically across the 10.128.0.0/9 address range.
resource "google_compute_network" "my_gke" {
  name                    = var.network_name
  auto_create_subnetworks = false
}


resource "google_compute_global_address" "ip_address" {
  name = "external-lb-ip"
}
