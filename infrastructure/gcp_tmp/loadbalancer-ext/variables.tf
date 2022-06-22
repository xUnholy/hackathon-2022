
variable "enabled" {
  type        = bool
  description = "To create or not to create"
}

variable "project_id" {
  type        = string
  description = "Service Project ID."
}


variable "name" {
  type        = string
  description = "Name of the loadbalancer"
}

variable "desc" {
  type        = string
  description = "Description for all loadbalancer resources"
}

variable "region" {
  type    = string
}

variable "ports" {
  type        = string
  description = "Port that Load balancer will listen to."
}



variable "hosts" {
  type        = list(string)
  description = "Hosts for the URL map"
}

variable "health_check" {
  type = object({
    //host = string
    path = string
    port = string
  })
  default = {
    //host = ""
    path = ""
    port = 15021
  }
}


variable "l7_ilb_ingress" {
  description = "Layer 7 HTTPS loadbalancer config"
  type = object({
    enabled        = bool
    #static_ip_name = string
    cert_version   = number
    key_version    = number
    backends = map(object({
      path_prefix           = string
      type                  = string
      priority              = number
      negs                  = list(string)
      max_rate_per_endpoint = number
    }))
    hosts = list(string)
    health_check = object({
      //  host = string
      path = string
      port = string
    })
  })
  default = {
    enabled        = true
    static_ip_name = ""
    cert_version   = 1
    key_version    = 1
    backends       = {}
    hosts          = []
    health_check = {
      //  host = ""
      path = ""
      port = ""
    }
  }
}
