terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.3.0"
    }
  }

  backend "gcs" {
    bucket = "tf-test-chaosmonkey"
    prefix = "test-elb"
    credentials = "../rising-capsule.json"
  }

}

provider "google" {
  credentials = file("../rising-capsule.json")

  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  credentials = file("../rising-capsule.json")
  project = var.project_id
  region  = var.region

}
