terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.3.0"
    }
  }

  backend "gcs" {
    bucket = "tf-test-chaosmonkey"
    prefix = "test-gke"
    credentials = "../rising-capsule.json"
  }

}

provider "google" {
  credentials = file("../rising-capsule.json")

  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  credentials = file("../rising-capsule.json")
  project = var.project_id
  region  = var.region

}
