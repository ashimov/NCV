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
  default = "pihole/pihole:2024.02.2"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "env_tz" {
  type    = string
  default = "UTC"
}

job "pihole" {
  datacenters = var.datacenters
  type = "service"

  group "pihole" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "pihole"
      port = "http"
      check {
        type     = "http"
        path     = "/admin"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "pihole" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
      }

      env {
        TZ = var.env_tz
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
