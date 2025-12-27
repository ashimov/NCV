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
  default = "quay.io/keycloak/keycloak:24.0.4"
}

variable "http_port" {
  type    = number
  default = 8080
}

variable "env_keycloak_admin" {
  type    = string
  default = "admin"
}

# WARNING: Change this password in production!
# Consider using Vault for secrets: see jobs/examples/vault-template-example.hcl
variable "env_keycloak_admin_password" {
  type    = string
  default = "change_me"  # TODO: Change before production deployment
}

variable "task_args" {
  type    = list(string)
  default = ["start-dev"]
}

job "keycloak" {
  datacenters = var.datacenters
  type = "service"

  group "keycloak" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "keycloak"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "keycloak" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        args = var.task_args
      }

      env {
        KEYCLOAK_ADMIN = var.env_keycloak_admin
        KEYCLOAK_ADMIN_PASSWORD = var.env_keycloak_admin_password
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
