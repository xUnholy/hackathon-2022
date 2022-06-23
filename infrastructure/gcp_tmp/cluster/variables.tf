variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "subnet_name_a" {
  description = "subnet"
  type = string
}

variable "cluster_name_a" {

}

variable "nodepool_name_a" {

}


variable "subnet_name_b" {
  description = "subnet"
  type = string
}

variable "cluster_name_b" {

}

variable "nodepool_name_b" {

}
variable "min_gke_version" {
  type = string
}
