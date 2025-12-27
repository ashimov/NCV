# Simplified Traefik for testing (without Consul Catalog - for demo purposes)
# Use this to quickly validate Traefik routing works
# For production, use traefik.hcl with proper Consul integration

variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "web_port" {
  type    = number
  default = 80
}

variable "dashboard_port" {
  type    = number
  default = 8080
}

job "traefik-simple" {
  datacenters = var.datacenters
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "bridge"
      port "web" {
        to = var.web_port
      }
      port "dashboard" {
        to = var.dashboard_port
      }
    }

    service {
      name = "traefik-simple"
      port = "web"

      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
        port     = "dashboard"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        ports = ["web", "dashboard"]

        volumes = [
          "local/traefik.yml:/traefik.yml"
        ]

        args = [
          "--configFile=/traefik.yml"
        ]
      }

      # Dynamic configuration with file provider
      template {
        data = <<EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":${var.web_port}"
  traefik:
    address: ":${var.dashboard_port}"

providers:
  file:
    filename: /local/dynamic.yml
    watch: true

metrics:
  prometheus: {}

log:
  level: INFO

accessLog: {}

ping: {}
EOF
        destination = "local/traefik.yml"
        change_mode = "restart"
      }

      # Dynamic routes configuration
      template {
        data = <<EOF
http:
  routers:
    web:
      entryPoints:
        - web
      rule: "Host(\`example.com\`, \`www.example.com\`)"
      service: web

  services:
    web:
      loadBalancer:
        servers:
          - url: "http://localhost:8080"
EOF
        destination = "local/dynamic.yml"
        change_mode = "restart"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      kill_timeout = "30s"
    }

    restart {
      attempts = 3
      delay    = "10s"
      interval = "5m"
      mode     = "fail"
    }
  }
}
