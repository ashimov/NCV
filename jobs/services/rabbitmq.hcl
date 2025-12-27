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
  default = "rabbitmq:3.13-management"
}

variable "amqp_port" {
  type    = number
  default = 5672
}

variable "mgmt_port" {
  type    = number
  default = 15672
}

job "rabbitmq" {
  datacenters = var.datacenters
  type = "service"

  group "rabbitmq" {
    count = var.count

    network {
      mode = "bridge"
      port "amqp" {
        to = var.amqp_port
      }
      port "mgmt" {
        to = var.mgmt_port
      }
    }

    service {
      name = "rabbitmq"
      port = "mgmt"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "rabbitmq" {
      driver = "docker"

      config {
        image = var.image
        ports = ["amqp", "mgmt"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
