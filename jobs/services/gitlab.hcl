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
  default = "gitlab/gitlab-ce:17.0.0-ce.0"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "ssh_port" {
  type    = number
  default = 22
}

job "gitlab" {
  datacenters = var.datacenters
  type = "service"

  group "gitlab" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
      port "ssh" {
        to = var.ssh_port
      }
    }

    volume "data" {
      type   = "host"
      source = "gitlab_data"
    }

    service {
      name = "gitlab"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "gitlab" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http", "ssh"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/var/opt/gitlab"
        read_only   = false
      }
    }
  }
}
