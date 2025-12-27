variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 500
}

variable "memory" {
  type    = number
  default = 512
}

variable "image" {
  type    = string
  default = "wazuh/wazuh-manager:4.7.3"
}

variable "api_port" {
  type    = number
  default = 55000
}

job "wazuh" {
  datacenters = var.datacenters
  type = "service"

  group "wazuh" {
    count = var.count

    network {
      mode = "bridge"
      port "api" {
        to = var.api_port
      }
    }

    service {
      name = "wazuh"
      port = "api"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "wazuh" {
      driver = "docker"

      config {
        image = var.image
        ports = ["api"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
