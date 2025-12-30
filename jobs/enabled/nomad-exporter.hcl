variable "image" {
  type    = string
  default = "fredrikhgrelland/nomad-exporter:0.4.0"
}

variable "nomad_addr" {
  type    = string
  default = "https://127.0.0.1:4646"
}

variable "nomad_tls_ca_src" {
  type    = string
  default = "/etc/nomad.d/tls/ca.pem"
}

variable "nomad_tls_cert_src" {
  type    = string
  default = "/etc/nomad.d/tls/cert.pem"
}

variable "nomad_tls_key_src" {
  type    = string
  default = "/etc/nomad.d/tls/key.pem"
}

variable "nomad_token" {
  type    = string
  default = ""
}

variable "nomad_cacert" {
  type    = string
  default = "/secrets/nomad/ca.pem"
}

variable "nomad_client_cert" {
  type    = string
  default = "/secrets/nomad/cert.pem"
}

variable "nomad_client_key" {
  type    = string
  default = "/secrets/nomad/key.pem"
}

job "nomad-exporter" {
  datacenters = ["dc1"]
  type = "service"
  group "nomad-exporter" {
    count = 1
    network {
      mode = "host"
      port "metrics" {
        static = 9108
      }
    }
    service {
      name = "nomad-exporter"
      port = "metrics"
      tags = ["traefik.enable=false"]
    }
    task "nomad-exporter" {
      driver = "docker"
      config {
        image = var.image
        ports = ["metrics"]
        env = {
          NOMAD_ADDR        = var.nomad_addr
          NOMAD_TOKEN       = var.nomad_token
          NOMAD_CACERT      = var.nomad_cacert
          NOMAD_CLIENT_CERT = var.nomad_client_cert
          NOMAD_CLIENT_KEY  = var.nomad_client_key
        }
      }

      template {
        data = <<EOF
{{ file "${var.nomad_tls_ca_src}" }}
EOF
        destination = "secrets/nomad/ca.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.nomad_tls_cert_src}" }}
EOF
        destination = "secrets/nomad/cert.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.nomad_tls_key_src}" }}
EOF
        destination = "secrets/nomad/key.pem"
        perms = "0600"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
