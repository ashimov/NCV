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
  default = "hashicorp/consul:1.17.1"
}

variable "http_port" {
  type    = number
  default = 8500
}

variable "task_args" {
  type = list(string)
}

variable "consul_config" {
  type = string
}

variable "vault_tls_secret_path" {
  type    = string
  default = "secret/data/consul/tls"
}

variable "vault_tls_ca_field" {
  type    = string
  default = "ca"
}

variable "vault_tls_cert_field" {
  type    = string
  default = "cert"
}

variable "vault_tls_key_field" {
  type    = string
  default = "key"
}

job "consul-prod-tls" {
  datacenters = var.datacenters
  type = "service"

  group "consul" {
    count = var.count

    vault {
      policies = ["consul-tls"]
    }

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "consul"
      port = "http"
      check {
        type     = "http"
        path     = "/v1/status/leader"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "consul" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        args = var.task_args
      }

      template {
        data = var.consul_config
        destination = "secrets/consul.hcl"
        change_mode = "restart"
      }

      template {
        data = <<EOT
{{ with secret "${var.vault_tls_secret_path}" }}{{ index .Data.data "${var.vault_tls_ca_field}" }}{{ end }}
EOT
        destination = "secrets/ca.pem"
        change_mode = "restart"
        perms = "0644"
      }

      template {
        data = <<EOT
{{ with secret "${var.vault_tls_secret_path}" }}{{ index .Data.data "${var.vault_tls_cert_field}" }}{{ end }}
EOT
        destination = "secrets/consul.pem"
        change_mode = "restart"
        perms = "0644"
      }

      template {
        data = <<EOT
{{ with secret "${var.vault_tls_secret_path}" }}{{ index .Data.data "${var.vault_tls_key_field}" }}{{ end }}
EOT
        destination = "secrets/consul.key"
        change_mode = "restart"
        perms = "0600"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
