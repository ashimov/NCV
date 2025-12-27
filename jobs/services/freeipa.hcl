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
  default = "freeipa/freeipa-server:almalinux-9"
}

variable "https_port" {
  type    = number
  default = 443
}

job "freeipa" {
  datacenters = var.datacenters
  type = "service"

  group "freeipa" {
    count = var.count

    network {
      mode = "bridge"
      port "https" {
        to = var.https_port
      }
    }

    service {
      name = "freeipa"
      port = "https"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "freeipa" {
      driver = "docker"

      config {
        image = var.image
        ports = ["https"]
        privileged = true
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
