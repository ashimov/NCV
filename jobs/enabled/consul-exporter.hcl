variable "image" {
  type    = string
  default = "prom/consul-exporter:v0.9.0"
}

variable "consul_address" {
  type    = string
  default = "https://127.0.0.1:8501"
}

variable "consul_tls_ca_src" {
  type    = string
  default = "/etc/consul.d/tls/ca.pem"
}

variable "consul_tls_cert_src" {
  type    = string
  default = "/etc/consul.d/tls/cert.pem"
}

variable "consul_tls_key_src" {
  type    = string
  default = "/etc/consul.d/tls/key.pem"
}

variable "consul_ca_file" {
  type    = string
  default = "/secrets/consul/ca.pem"
}

variable "consul_cert_file" {
  type    = string
  default = "/secrets/consul/cert.pem"
}

variable "consul_key_file" {
  type    = string
  default = "/secrets/consul/key.pem"
}

variable "consul_token" {
  type    = string
  default = ""
}

job "consul-exporter" {
  datacenters = ["dc1"]
  type = "service"
  group "consul-exporter" {
    count = 1
    network {
      mode = "host"
      port "metrics" {
        static = 9107
      }
    }
    service {
      name = "consul-exporter"
      port = "metrics"
      tags = ["traefik.enable=false"]
    }
    task "consul-exporter" {
      driver = "docker"
      config {
        image = var.image
        ports = ["metrics"]
        args = concat(
          ["--consul.server=${var.consul_address}"],
          var.consul_ca_file != "" ? ["--consul.ca-file=${var.consul_ca_file}"] : [],
          var.consul_cert_file != "" ? ["--consul.cert-file=${var.consul_cert_file}"] : [],
          var.consul_key_file != "" ? ["--consul.key-file=${var.consul_key_file}"] : [],
          var.consul_token != "" ? ["--consul.token=${var.consul_token}"] : []
        )
      }

      template {
        data = <<EOF
{{ file "${var.consul_tls_ca_src}" }}
EOF
        destination = "secrets/consul/ca.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.consul_tls_cert_src}" }}
EOF
        destination = "secrets/consul/cert.pem"
        perms = "0600"
      }

      template {
        data = <<EOF
{{ file "${var.consul_tls_key_src}" }}
EOF
        destination = "secrets/consul/key.pem"
        perms = "0600"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
