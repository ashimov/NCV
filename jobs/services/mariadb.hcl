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
  default = "mariadb:11.3"
}

variable "db_port" {
  type    = number
  default = 3306
}

# WARNING: Change this password in production!
# Consider using Vault for secrets: see jobs/examples/vault-template-example.hcl
variable "env_mariadb_root_password" {
  type    = string
  default = "change_me"  # TODO: Change before production deployment
}

job "mariadb" {
  datacenters = var.datacenters
  type = "service"

  group "mariadb" {
    count = var.count

    network {
      mode = "bridge"
      port "db" {
        to = var.db_port
      }
    }

    volume "data" {
      type   = "host"
      source = "mariadb_data"
    }

    service {
      name = "mariadb"
      port = "db"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "mariadb" {
      driver = "docker"

      config {
        image = var.image
        ports = ["db"]
      }

      env {
        MARIADB_ROOT_PASSWORD = var.env_mariadb_root_password
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/mysql"
        read_only   = false
      }
    }
  }
}
