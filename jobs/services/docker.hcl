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
  default = "docker:26-dind"
}

job "docker" {
  datacenters = var.datacenters
  type = "service"

  group "docker" {
    count = var.count

    volume "data" {
      type   = "host"
      source = "docker_data"
    }

    task "docker" {
      driver = "docker"

      config {
        image = var.image
        privileged = true
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/docker"
        read_only   = false
      }
    }
  }
}
