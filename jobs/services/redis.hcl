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
  default = "redis:7.2-alpine"
}

variable "redis_port" {
  type    = number
  default = 6379
}

job "redis" {
  datacenters = var.datacenters
  type = "service"

  group "redis" {
    count = var.count

    network {
      mode = "bridge"
      port "redis" {
        to = var.redis_port
      }
    }

    volume "data" {
      type   = "host"
      source = "redis_data"
    }

    service {
      name = "redis"
      port = "redis"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = var.image
        ports = ["redis"]
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
        read_only   = false
      }
    }
  }
}
