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
  default = "jupyterhub/jupyterhub:4.0.2"
}

variable "http_port" {
  type    = number
  default = 8000
}

job "jupyterhub" {
  datacenters = var.datacenters
  type = "service"

  group "jupyterhub" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "jupyterhub"
      port = "http"
      check {
        type     = "http"
        path     = "/hub"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "jupyterhub" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
