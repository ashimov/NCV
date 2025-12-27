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
  default = "jenkins/jenkins:lts-jdk17"
}

variable "http_port" {
  type    = number
  default = 8080
}

job "jenkins" {
  datacenters = var.datacenters
  type = "service"

  group "jenkins" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "jenkins_data"
    }

    service {
      name = "jenkins"
      port = "http"
      check {
        type     = "http"
        path     = "/login"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "jenkins" {
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
        destination = "/var/jenkins_home"
        read_only   = false
      }
    }
  }
}
