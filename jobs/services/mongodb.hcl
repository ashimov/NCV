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
  default = "mongo:7"
}

variable "db_port" {
  type    = number
  default = 27017
}

variable "env_mongo_initdb_root_username" {
  type    = string
  default = "root"
}

# WARNING: Change this password in production!
# Consider using Vault for secrets: see jobs/examples/vault-template-example.hcl
variable "env_mongo_initdb_root_password" {
  type    = string
  default = "change_me"  # TODO: Change before production deployment
}

job "mongodb" {
  datacenters = var.datacenters
  type = "service"

  group "mongodb" {
    count = var.count

    network {
      mode = "bridge"
      port "db" {
        to = var.db_port
      }
    }

    volume "data" {
      type   = "host"
      source = "mongodb_data"
    }

    service {
      name = "mongodb"
      port = "db"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "mongodb" {
      driver = "docker"

      config {
        image = var.image
        ports = ["db"]
      }

      env {
        MONGO_INITDB_ROOT_USERNAME = var.env_mongo_initdb_root_username
        MONGO_INITDB_ROOT_PASSWORD = var.env_mongo_initdb_root_password
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/data/db"
        read_only   = false
      }
    }
  }
}
