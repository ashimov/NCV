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
  default = "clickhouse/clickhouse-server:24.3"
}

variable "http_port" {
  type    = number
  default = 8123
}

job "clickhouse" {
  datacenters = var.datacenters
  type = "service"

  group "clickhouse" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "clickhouse_data"
    }

    service {
      name = "clickhouse"
      port = "http"
      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "clickhouse" {
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
        destination = "/var/lib/clickhouse"
        read_only   = false
      }
    }
  }
}
