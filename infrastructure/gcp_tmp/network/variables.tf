variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "zone" {
  description = "zone"
}

variable "network_name" {
  description = "network name"
}


variable "subnetwork_name_a" {
  description = "subnetwork name"
  type = map
 
}

variable "secondary_ranges_a" {
  type = map(object({
      name = string
      cidr = string
  }) )
}



variable "subnetwork_name_b" {
  description = "subnetwork name"
  type = map

}

variable "secondary_ranges_b" {
  type = map(object({
    name = string
    cidr = string
  }) )
}
