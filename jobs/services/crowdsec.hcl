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
  default = "crowdsecurity/crowdsec:1.6.3"
}

variable "http_port" {
  type    = number
  default = 8080
}

job "crowdsec" {
  datacenters = var.datacenters
  type = "service"

  group "crowdsec" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "crowdsec"
      port = "http"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "crowdsec" {
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
