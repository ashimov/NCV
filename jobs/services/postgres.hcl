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
  default = "postgres:16"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "env_postgres_password" {
  type    = string
  default = "change_me"
}

job "postgres" {
  datacenters = var.datacenters
  type = "service"

  group "postgres" {
    count = var.count

    network {
      mode = "bridge"
      port "db" {
        to = var.db_port
      }
    }

    volume "data" {
      type   = "host"
      source = "postgres_data"
    }

    service {
      name = "postgres"
      port = "db"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "postgres" {
      driver = "docker"

      config {
        image = var.image
        ports = ["db"]
      }

      env {
        POSTGRES_PASSWORD = var.env_postgres_password
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }
    }
  }
}
