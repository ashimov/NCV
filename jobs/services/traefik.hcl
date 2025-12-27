variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 1000
}

variable "memory" {
  type    = number
  default = 1024
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

variable "consul_address" {
  type    = string
  default = "127.0.0.1:8500"
}

variable "consul_tls" {
  type    = bool
  default = true
}

variable "dashboard_user" {
  type    = string
  default = "admin"
}

variable "dashboard_password" {
  type    = string
  default = "changeme"
  # Generate with: htpasswd -nb admin password
  # Or use: echo $(htpasswd -nb admin password) | sed -e s/\\$/\\$\\$/g
}

variable "acme_email" {
  type    = string
  default = ""
  # Set your email for Let's Encrypt certificates
}

variable "domain" {
  type    = string
  default = "traefik.local"
  # Dashboard domain
}

job "traefik" {
  datacenters = var.datacenters
  type        = "system"  # Run on all clients for HA

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

    service {
      name = "traefik"
      port = "web"
      
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=Host(`${var.domain}`)",
        "traefik.http.routers.dashboard.service=api@internal",
        "traefik.http.routers.dashboard.entrypoints=websecure",
        "traefik.http.routers.dashboard.tls=true"
      ]

      check {
        type     = "http"
        path     = "/ping"
        interval = "10s"
        timeout  = "2s"
        port     = "dashboard"
      }

      check_restart {
        limit = 3
        grace = "10s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = var.image
        network_mode = "host"
        
        args = [
          "--api.dashboard=true",
          "--api.insecure=false",
          "--ping=true",
          "--ping.entrypoint=traefik",
          
          # Entrypoints
          "--entrypoints.web.address=:${var.web_port}",
          "--entrypoints.websecure.address=:${var.websecure_port}",
          "--entrypoints.traefik.address=:${var.dashboard_port}",
          
          # HTTP to HTTPS redirect (disabled for testing - enable when using HTTPS certs)
          # "--entrypoints.web.http.redirections.entrypoint.to=websecure",
          # "--entrypoints.web.http.redirections.entrypoint.scheme=https",
          
          # Consul Catalog Provider
          "--providers.consulcatalog=true",
          "--providers.consulcatalog.endpoint.address=${var.consul_address}",
          "--providers.consulcatalog.endpoint.scheme=${var.consul_tls ? "https" : "http"}",
          "--providers.consulcatalog.endpoint.datacenter=${var.datacenters[0]}",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.exposedByDefault=false",
          "--providers.consulcatalog.defaultRule=Host(`{{ normalize .Name }}.${var.domain}`)",
          "--providers.consulcatalog.connectAware=false",
          "--providers.consulcatalog.connectByDefault=false",
          "--providers.consulcatalog.serviceName=traefik",
          
          # Consul Catalog cache
          "--providers.consulcatalog.cache=true",
          "--providers.consulcatalog.endpoint.tls.insecureskipverify=true",
          
          # Logs
          "--log.level=INFO",
          "--accesslog=true",
          "--accesslog.filepath=/var/log/traefik/access.log",
          "--accesslog.bufferingsize=100",
          
          # Metrics
          "--metrics.prometheus=true",
          "--metrics.prometheus.addEntryPointsLabels=true",
          "--metrics.prometheus.addServicesLabels=true",
          

        ]

        volumes = [
          "local/traefik:/data",
          "local/logs:/var/log/traefik"
        ]
      }

      # Dashboard authentication template
      template {
        data = <<EOF
# Dashboard Basic Auth (htpasswd format)
# Generate with: htpasswd -nb username password
${var.dashboard_password != "changeme" ? var.dashboard_password : "admin:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/"}
EOF
        destination = "secrets/dashboard_users"
        perms       = "600"
      }

      # Traefik dynamic configuration for dashboard auth
      template {
        data = <<EOF
http:
  middlewares:
    dashboard-auth:
      basicAuth:
        usersFile: /secrets/dashboard_users
    
  routers:
    dashboard:
      rule: "Host(`${var.domain}`)"
      entryPoints:
        - traefik
      service: api@internal
      middlewares:
        - dashboard-auth
EOF
        destination = "local/config/dynamic.yml"
        change_mode = "restart"
      }

      env {
        CONSUL_HTTP_ADDR = var.consul_address
        CONSUL_HTTP_SSL  = var.consul_tls ? "true" : "false"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      # Service lifecycle
      kill_timeout = "30s"
    }

    # Restart policy
    restart {
      attempts = 3
      delay    = "15s"
      interval = "5m"
      mode     = "fail"
    }

    # Update strategy
    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "10s"
      healthy_deadline = "5m"
      auto_revert      = true
      canary           = 1
    }
  }
}
