# Traefik Load Balancer with Let's Encrypt (Cloudflare DNS Challenge)
# Designed for Keepalived VIP setup

variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
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
  default = "traefik:v3.0"
}

variable "web_port" {
  type    = number
  default = 80
}

variable "websecure_port" {
  type    = number
  default = 443
}

variable "dashboard_port" {
  type    = number
  default = 8080
}

variable "consul_catalog_address" {
  type    = string
  default = "127.0.0.1:8501"
}

variable "consul_catalog_scheme" {
  type    = string
  default = "https"
}

variable "consul_tls_insecure" {
  type    = bool
  default = false
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

variable "consul_tls_ca_file" {
  type    = string
  default = "/secrets/consul/ca.pem"
}

variable "consul_tls_cert_file" {
  type    = string
  default = "/secrets/consul/cert.pem"
}

variable "consul_tls_key_file" {
  type    = string
  default = "/secrets/consul/key.pem"
}

variable "domain" {
  type    = string
  default = "ashimov.com"
}

variable "dashboard_domain" {
  type    = string
  default = "traefik.ashimov.com"
}

variable "acme_email" {
  type    = string
  default = "berik@ashimov.com"
}

variable "cloudflare_email" {
  type    = string
  default = "berik@ashimov.com"
}

# Required for ACME DNS challenge
variable "cloudflare_api_token" {
  type    = string
  default = ""
}

variable "vault_domain" {
  type    = string
  default = "vault.ashimov.com"
}

variable "vault_backend" {
  type    = string
  # Comma-separated list of Vault server URLs
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

variable "vault_tls_insecure" {
  type    = bool
  default = false
}

variable "vault_tls_ca_file" {
  type    = string
  default = "/secrets/vault/ca.pem"
}

variable "vault_tls_cert_file" {
  type    = string
  default = "/secrets/vault/cert.pem"
}

variable "vault_tls_key_file" {
  type    = string
  default = "/secrets/vault/key.pem"
}

variable "auth_domain" {
  type    = string
  default = "auth.ashimov.com"
}

variable "keycloak_domain" {
  type    = string
  default = "keycloak.ashimov.com"
}

variable "keycloak_backend" {
  type    = string
  default = "http://keycloak.service.consul:8180"
}

variable "forward_auth_backend" {
  type    = string
  default = "http://127.0.0.1:4181"
}

# Dashboard credentials - generate with: htpasswd -nB admin (escape $ with $$)
# Optional basic auth for the local dashboard entrypoint
variable "dashboard_auth" {
  type    = string
  default = ""
}

job "traefik-lb" {
  datacenters = var.datacenters
  type        = "system"

  group "traefik" {
    network {
      mode = "host"

      port "web" {
        static = var.web_port
      }
      port "websecure" {
        static = var.websecure_port
      }
      port "dashboard" {
        static = var.dashboard_port
      }
    }

    volume "traefik-data" {
      type      = "host"
      source    = "traefik-data"
      read_only = false
    }

    service {
      name = "traefik"
      port = "web"

      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "3s"
        port     = "dashboard"
      }

      check_restart {
        limit = 3
        grace = "30s"
      }
    }

    service {
      name = "traefik-https"
      port = "websecure"
      
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      volume_mount {
        volume      = "traefik-data"
        destination = "/letsencrypt"
        read_only   = false
      }

      config {
        image        = var.image
        network_mode = "host"
        
        args = [
          # API and Dashboard
          "--api=true",
          "--api.dashboard=true",
          "--api.insecure=false",
          
          # Ping for healthchecks
          "--ping=true",
          "--ping.entrypoint=traefik",
          
          # Entrypoints
          "--entrypoints.web.address=:${var.web_port}",
          "--entrypoints.websecure.address=:${var.websecure_port}",
          "--entrypoints.traefik.address=:${var.dashboard_port}",
          
          # HTTP to HTTPS redirect
          "--entrypoints.web.http.redirections.entrypoint.to=websecure",
          "--entrypoints.web.http.redirections.entrypoint.scheme=https",
          "--entrypoints.web.http.redirections.entrypoint.permanent=true",
          
          # Let's Encrypt ACME with Cloudflare DNS Challenge
          "--certificatesresolvers.letsencrypt.acme.email=${var.acme_email}",
          "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare",
          "--certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53",
          
          # File provider for configuration
          "--providers.file.directory=/etc/traefik/dynamic",
          "--providers.file.watch=true",
          
          # Logging
          "--log.level=INFO",
          "--log.format=json",
          "--accesslog=true",
          "--accesslog.format=json",
          
          # Metrics
          "--metrics.prometheus=true",
          "--metrics.prometheus.entrypoint=traefik",
          "--metrics.prometheus.addEntryPointsLabels=true",
          "--metrics.prometheus.addServicesLabels=true",
          
          # Consul Catalog provider for automatic service discovery
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.endpoint.address=${var.consul_catalog_address}",
          "--providers.consulcatalog.endpoint.scheme=${var.consul_catalog_scheme}",
          "--providers.consulcatalog.endpoint.tls.ca=${var.consul_tls_ca_file}",
          "--providers.consulcatalog.endpoint.tls.cert=${var.consul_tls_cert_file}",
          "--providers.consulcatalog.endpoint.tls.key=${var.consul_tls_key_file}",
          "--providers.consulcatalog.endpoint.tls.insecureSkipVerify=${var.consul_tls_insecure}",
          "--providers.consulcatalog.exposedByDefault=false",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.defaultrule=Host(`{{ .Name }}.${var.domain}`)",
        ]

        volumes = [
          "local/dynamic:/etc/traefik/dynamic:ro",
        ]
      }

      # Cloudflare credentials
      env {
        CF_API_EMAIL     = var.cloudflare_email
        CF_DNS_API_TOKEN = var.cloudflare_api_token
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

      # Dynamic configuration
      template {
        data = <<EOF
http:
  middlewares:
%{ if var.dashboard_auth != "" }
    dashboard-auth:
      basicAuth:
        users:
          - "${var.dashboard_auth}"
%{ endif }
    keycloak-auth:
      forwardAuth:
        address: "${var.forward_auth_backend}"
        trustForwardHeader: true
        authResponseHeaders:
          - X-Forwarded-User

    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
    
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
        period: 1s
    
    compress:
      compress:
        excludedContentTypes:
          - text/event-stream

  routers:
    dashboard:
      rule: "Host(`${var.dashboard_domain}`)"
      entryPoints:
        - websecure
      service: api@internal
      middlewares:
        - keycloak-auth
        - security-headers
      tls:
        certResolver: letsencrypt
%{ if var.dashboard_auth != "" }
    dashboard-http:
      rule: "Host(`${var.dashboard_domain}`)"
      entryPoints:
        - traefik
      service: api@internal
      middlewares:
        - dashboard-auth
%{ endif }

    keycloak:
      rule: "Host(`${var.keycloak_domain}`)"
      entryPoints:
        - websecure
      service: keycloak
      tls:
        certResolver: letsencrypt

    keycloak-http:
      rule: "Host(`${var.keycloak_domain}`)"
      entryPoints:
        - web
      service: keycloak

    # Auth endpoint for traefik-forward-auth
    auth:
      rule: "Host(`${var.auth_domain}`)"
      entryPoints:
        - websecure
      service: forward-auth
      tls:
        certResolver: letsencrypt

    # Vault UI and API
    vault:
      rule: "Host(`${var.vault_domain}`)"
      entryPoints:
        - websecure
      service: vault
      middlewares:
        - security-headers
      tls:
        certResolver: letsencrypt

  services:
    keycloak:
      loadBalancer:
        servers:
          - url: "${var.keycloak_backend}"

    forward-auth:
      loadBalancer:
        servers:
          - url: "${var.forward_auth_backend}"

    # Vault cluster servers
    vault:
      loadBalancer:
        servers:
%{ for backend in split(",", var.vault_backend) ~}
          - url: "${trimspace(backend)}"
%{ endfor ~}
        serversTransport: vaultTransport

  serversTransports:
    vaultTransport:
      insecureSkipVerify: ${var.vault_tls_insecure}
%{ if var.vault_tls_ca_file != "" }
      rootCAs:
        - "${var.vault_tls_ca_file}"
%{ endif }
%{ if var.vault_tls_cert_file != "" && var.vault_tls_key_file != "" }
      certificates:
        - certFile: "${var.vault_tls_cert_file}"
          keyFile: "${var.vault_tls_key_file}"
%{ endif }

tls:
  options:
    default:
      minVersion: VersionTLS12
      sniStrict: true
EOF
        destination = "local/dynamic/config.yml"
        change_mode = "noop"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      kill_timeout = "30s"
    }

    restart {
      attempts = 3
      delay    = "15s"
      interval = "5m"
      mode     = "fail"
    }

    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "30s"
      healthy_deadline = "5m"
      auto_revert      = true
    }
  }
}
