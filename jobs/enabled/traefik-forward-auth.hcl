# Traefik Forward Auth with Keycloak OIDC
# This provides OIDC authentication for Traefik dashboard and other services

variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "keycloak_url" {
  type    = string
  default = "https://keycloak.ashimov.com"
}

variable "keycloak_realm" {
  type    = string
  default = "ncv"
}

variable "client_id" {
  type    = string
  default = "traefik"
}

# Required: set after running setup-keycloak.sh
variable "client_secret" {
  type    = string
  default = ""
}

# Required: generate with `openssl rand -hex 32`
variable "secret" {
  type    = string
  default = ""
}

variable "cookie_domain" {
  type    = string
  default = "ashimov.com"
}

variable "auth_host" {
  type    = string
  default = "auth.ashimov.com"
}

# Whitelist for allowed email domains/addresses
variable "whitelist" {
  type    = string
  default = ""
}

job "traefik-forward-auth" {
  datacenters = var.datacenters
  type        = "system"

  group "forward-auth" {
    network {
      mode = "host"
      port "auth" {
        static = 4181
      }
    }

    service {
      name = "traefik-forward-auth"
      port = "auth"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "forward-auth" {
      driver = "docker"

      config {
        image        = "thomseddon/traefik-forward-auth:2"
        network_mode = "host"
      }

      env {
        # OIDC Provider (Keycloak)
        PROVIDERS_OIDC_ISSUER_URL    = "${var.keycloak_url}/realms/${var.keycloak_realm}"
        PROVIDERS_OIDC_CLIENT_ID     = var.client_id
        PROVIDERS_OIDC_CLIENT_SECRET = var.client_secret
        
        # Default provider
        DEFAULT_PROVIDER = "oidc"
        
        # Secret for cookie encryption
        SECRET = var.secret
        
        # Cookie settings
        COOKIE_DOMAIN = var.cookie_domain
        
        # Auth host for centralized authentication
        AUTH_HOST = var.auth_host
        URL_PATH  = "/_oauth"
        
        # Whitelist - only allow specific users
        WHITELIST = var.whitelist
        
        # Log level
        LOG_LEVEL = "info"
        
        # Use secure cookies with HTTPS
        INSECURE_COOKIE = "false"
        
        # Lifetime - 12 hours
        LIFETIME = "43200"
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
