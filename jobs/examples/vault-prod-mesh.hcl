variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "count" {
  type    = number
  default = 3
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
  default = "hashicorp/vault:1.16.1"
}

variable "http_port" {
  type    = number
  default = 8200
}

variable "task_args" {
  type = list(string)
}

variable "vault_config" {
  type = string
}

job "vault-prod-mesh" {
  datacenters = var.datacenters
  type = "service"

  group "vault" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "vault"
      port = "http"
      connect {
        sidecar_service {}
      }
      check {
        type     = "http"
        path     = "/v1/sys/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "vault" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        args = var.task_args
        cap_add = ["IPC_LOCK"]
      }

      template {
        data = var.vault_config
        destination = "secrets/vault.hcl"
        change_mode = "restart"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
