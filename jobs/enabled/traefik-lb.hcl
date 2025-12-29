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

variable "cloudflare_api_token" {
  type    = string
  default = "N2fow3H2yoXewF7HMNxBHwSx_3d43dILPF-WxqQf"
}

variable "vault_domain" {
  type    = string
  default = "vault.ashimov.com"
}

variable "vault_backend" {
  type    = string
  # List of Vault servers
  default = "10.44.103.101:8200,10.44.103.102:8200,10.44.103.103:8200"
}

variable "auth_domain" {
  type    = string
  default = "auth.ashimov.com"
}

# Dashboard credentials - generate with: htpasswd -nB admin
# Then escape $ with $$
variable "dashboard_auth" {
  type    = string
  default = "admin:$$2y$$05$$LhayLxezLhK8hS6oPm.VyODzVnGBnFL3MBNv7jKl5A0rMmrd.r86K"
  # Default password: admin123 - CHANGE IN PRODUCTION!
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
          "--api.insecure=true",
          
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
          "--providers.consulcatalog.endpoint.address=127.0.0.1:8500",
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

      # Dynamic configuration
      template {
        data = <<EOF
http:
  middlewares:
    dashboard-auth:
      basicAuth:
        users:
          - "${var.dashboard_auth}"
    
    keycloak-auth:
      forwardAuth:
        address: "http://127.0.0.1:4181"
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

    dashboard-http:
      rule: "Host(`${var.dashboard_domain}`)"
      entryPoints:
        - traefik
      service: api@internal
      middlewares:
        - dashboard-auth

    keycloak:
      rule: "Host(`keycloak.ashimov.com`)"
      entryPoints:
        - websecure
      service: keycloak
      tls:
        certResolver: letsencrypt

    keycloak-http:
      rule: "Host(`keycloak.ashimov.com`)"
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
          - url: "http://10.44.103.103:8180"

    forward-auth:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:4181"

    # Vault cluster servers
    vault:
      loadBalancer:
        servers:
          - url: "https://10.44.103.101:8200"
          - url: "https://10.44.103.102:8200"
        serversTransport: insecureTransport

  serversTransports:
    insecureTransport:
      insecureSkipVerify: true

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
