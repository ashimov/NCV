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
  default = "sonarqube:10.5-community"
}

variable "http_port" {
  type    = number
  default = 9000
}

job "sonarqube" {
  datacenters = var.datacenters
  type = "service"

  group "sonarqube" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "sonarqube_data"
    }

    service {
      name = "sonarqube"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "sonarqube" {
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
        destination = "/opt/sonarqube/data"
        read_only   = false
      }
    }
  }
}
