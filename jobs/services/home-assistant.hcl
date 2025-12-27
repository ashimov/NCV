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
  default = "ghcr.io/home-assistant/home-assistant:2024.5.5"
}

variable "http_port" {
  type    = number
  default = 8123
}

job "home-assistant" {
  datacenters = var.datacenters
  type = "service"

  group "home-assistant" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "home-assistant_data"
    }

    service {
      name = "home-assistant"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "home-assistant" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/config"
        read_only   = false
      }
    }
  }
}
