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
  default = "traefik:v3.0"
}

variable "web_port" {
  type    = number
  default = 80
}

variable "websecure_port" {
  type    = number
  default = 443
}

variable "dashboard_port" {
  type    = number
  default = 8080
}

job "traefik" {
  datacenters = var.datacenters
  type = "service"

  group "traefik" {
    count = var.count

    network {
      mode = "bridge"
      port "web" {
        to = var.web_port
      }
      port "websecure" {
        to = var.websecure_port
      }
      port "dashboard" {
        to = var.dashboard_port
      }
    }

    service {
      name = "traefik"
      port = "dashboard"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = var.image
        ports = ["web", "websecure", "dashboard"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
