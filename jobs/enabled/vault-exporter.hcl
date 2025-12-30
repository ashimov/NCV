variable "image" {
  type    = string
  default = "danielmichaels/vault-exporter:0.7.0"
}

variable "vault_addr" {
  type    = string
  default = "https://vault.service.consul:8200"
}

variable "vault_tls_ca_src" {
  type    = string
  default = "/etc/vault.d/tls/ca.pem"
}

variable "vault_tls_cert_src" {
  type    = string
  default = "/etc/vault.d/tls/cert.pem"
}

variable "vault_tls_key_src" {
  type    = string
  default = "/etc/vault.d/tls/key.pem"
}

# Required: set a token with metrics read access
variable "vault_token" {
  type    = string
  default = ""
}

variable "vault_cacert" {
  type    = string
  default = "/secrets/vault/ca.pem"
}

variable "vault_client_cert" {
  type    = string
  default = "/secrets/vault/cert.pem"
}

variable "vault_client_key" {
  type    = string
  default = "/secrets/vault/key.pem"
}

job "vault-exporter" {
  datacenters = ["dc1"]
  type = "service"
  group "vault-exporter" {
    count = 1
    network {
      mode = "host"
      port "metrics" {
        static = 9410
      }
    }
    service {
      name = "vault-exporter"
      port = "metrics"
      tags = ["traefik.enable=false"]
    }
    task "vault-exporter" {
      driver = "docker"
      config {
        image = var.image
        ports = ["metrics"]
        env = {
          VAULT_ADDR        = var.vault_addr
          VAULT_TOKEN       = var.vault_token
          VAULT_CACERT      = var.vault_cacert
          VAULT_CLIENT_CERT = var.vault_client_cert
          VAULT_CLIENT_KEY  = var.vault_client_key
        }
      }

      template {
        data = <<EOF
{{ file "${var.vault_tls_ca_src}" }}
EOF
        destination = "secrets/vault/ca.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.vault_tls_cert_src}" }}
EOF
        destination = "secrets/vault/cert.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.vault_tls_key_src}" }}
EOF
        destination = "secrets/vault/key.pem"
        perms = "0600"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
