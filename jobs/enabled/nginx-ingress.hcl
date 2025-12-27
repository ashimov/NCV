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
  default = "k8s.gcr.io/ingress-nginx/controller:v1.10.0"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "https_port" {
  type    = number
  default = 443
}

job "nginx-ingress" {
  datacenters = var.datacenters
  type = "service"

  group "nginx-ingress" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
      port "https" {
        to = var.https_port
      }
    }

    service {
      name = "nginx-ingress"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx-ingress" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http", "https"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
