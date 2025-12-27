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
  default = "prom/alertmanager:v0.27.0"
}

variable "http_port" {
  type    = number
  default = 9093
}

job "alertmanager" {
  datacenters = var.datacenters
  type = "service"

  group "alertmanager" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "alertmanager_data"
    }

    service {
      name = "alertmanager"
      port = "http"
      check {
        type     = "http"
        path     = "/-/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "alertmanager" {
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
        destination = "/alertmanager"
        read_only   = false
      }
    }
  }
}
