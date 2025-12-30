variable "image" {
  type    = string
  default = "grafana/grafana-oss:10.4.3"
}

variable "grafana_domain" {
  type    = string
  default = "grafana.ashimov.com"
}

variable "keycloak_base_url" {
  type    = string
  default = "https://keycloak.ashimov.com"
}

variable "keycloak_realm" {
  type    = string
  default = "ncv"
}

variable "oauth_client_id" {
  type    = string
  default = "grafana"
}

# Required: set after creating the Keycloak client
variable "oauth_client_secret" {
  type    = string
  default = ""
}

job "grafana" {
  datacenters = ["dc1"]
  type = "service"

  group "grafana" {
    count = 2

    network {
      mode = "host"
      port "http" {
        static = 3000
      }
    }

    service {
      name = "grafana"
      port = "http"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.grafana.rule=Host(`${var.grafana_domain}`)",
        "traefik.http.routers.grafana.entrypoints=websecure",
        "traefik.http.routers.grafana.tls=true",
        "traefik.http.routers.grafana.middlewares=forward-auth@file"
      ]
      check {
        type     = "http"
        path     = "/login"
        interval = "10s"
        timeout  = "2s"
      }
    }


    task "grafana" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        # no host-volume to avoid scheduling constraints; data will be ephemeral
        env = {
          GF_SERVER_ROOT_URL = "https://${var.grafana_domain}"
          GF_AUTH_GENERIC_OAUTH_ENABLED = "true"
          GF_AUTH_GENERIC_OAUTH_NAME = "Keycloak"
          GF_AUTH_GENERIC_OAUTH_CLIENT_ID = var.oauth_client_id
          GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = var.oauth_client_secret
          GF_AUTH_GENERIC_OAUTH_AUTH_URL = "${var.keycloak_base_url}/realms/${var.keycloak_realm}/protocol/openid-connect/auth"
          GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "${var.keycloak_base_url}/realms/${var.keycloak_realm}/protocol/openid-connect/token"
          GF_AUTH_GENERIC_OAUTH_API_URL = "${var.keycloak_base_url}/realms/${var.keycloak_realm}/protocol/openid-connect/userinfo"
          GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = "true"
          GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "contains(roles[*], 'grafana_admin') && 'Admin' || 'Viewer'"
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
