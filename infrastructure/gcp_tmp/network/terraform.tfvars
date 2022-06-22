project_id = "rising-capsule-353505"
region     = "australia-southeast2"
zone    = "australia-southeast2-b"
network_name = "gke-network"

subnetwork_name_a = {
  name = "gke-subnetwork-a"
  range =  "10.166.41.0/25"
}

subnetwork_name_b = {
  name = "gke-subnetwork-b"
  range =  "10.166.40.128/25"
}



secondary_ranges_a = {
  services_range = {
    name = "services-range"
    cidr = "100.118.64.0/20"
  },
  pod_range = {
    name = "pod-range"
    cidr = "100.118.136.0/23"
  }
}

secondary_ranges_b = {
  services_range = {
    name = "services-range"
    cidr = "100.118.48.0/20"
  },
  pod_range = {
    name = "pod-range"
    cidr = "100.118.134.0/23"
  }
}
