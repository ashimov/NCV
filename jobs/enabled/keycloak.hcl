# Keycloak HA Cluster with PostgreSQL backend
# Provides OIDC authentication for Traefik and Vault

variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "domain" {
  type    = string
  default = "ashimov.com"
}

variable "keycloak_domain" {
  type    = string
  default = "keycloak.ashimov.com"
}

variable "keycloak_admin" {
  type    = string
  default = "admin"
}

variable "keycloak_admin_password" {
  type    = string
  default = "Admin123!"
}

variable "postgres_host" {
  type    = string
  default = "keycloak-db.service.consul"
}

variable "postgres_user" {
  type    = string
  default = "keycloak"
}

variable "postgres_password" {
  type    = string
  default = "keycloak123"
}

variable "postgres_db" {
  type    = string
  default = "keycloak"
}

variable "keycloak_replicas" {
  type    = number
  default = 2
}

# ============================================
# PostgreSQL Database (separate job)
# ============================================
job "keycloak-db" {
  datacenters = var.datacenters
  type        = "service"

  # Pin to specific node for persistent storage
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "nomad-w2"
  }

  group "postgres" {
    count = 1

    network {
      mode = "host"
      port "db" {
        static = 5432
      }
    }

    volume "postgres-data" {
      type      = "host"
      source    = "keycloak-db"
      read_only = false
    }

    service {
      name = "keycloak-db"
      port = "db"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "postgres" {
      driver = "docker"

      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      config {
        image        = "postgres:15-alpine"
        network_mode = "host"
      }

      env {
        POSTGRES_USER     = var.postgres_user
        POSTGRES_PASSWORD = var.postgres_password
        POSTGRES_DB       = var.postgres_db
        PGDATA           = "/var/lib/postgresql/data/pgdata"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}

# ============================================
# Keycloak Cluster
# ============================================
job "keycloak" {
  datacenters = var.datacenters
  type        = "service"

  # Update strategy for zero-downtime deployments
  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "5m"
    auto_revert      = true
    stagger          = "30s"
  }

  group "keycloak" {
    count = var.keycloak_replicas

    # Spread across different hosts
    spread {
      attribute = "${node.unique.id}"
      weight    = 100
    }

    # Anti-affinity - place on different hosts
    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    network {
      mode = "host"
      port "http" {
        to = 8180
      }
      port "jgroups" {
        to = 7800
      }
    }

    service {
      name = "keycloak"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.keycloak.rule=Host(`${var.keycloak_domain}`)",
        "traefik.http.routers.keycloak.entrypoints=websecure",
        "traefik.http.routers.keycloak.tls=true",
        "traefik.http.routers.keycloak.tls.certresolver=letsencrypt",
        "traefik.http.services.keycloak.loadbalancer.server.port=${NOMAD_HOST_PORT_http}",
        "traefik.http.services.keycloak.loadbalancer.sticky.cookie=true",
        "traefik.http.services.keycloak.loadbalancer.sticky.cookie.name=KC_SESSION",
        "traefik.http.services.keycloak.loadbalancer.sticky.cookie.httpOnly=true",
        "traefik.http.services.keycloak.loadbalancer.healthcheck.path=/health/ready",
        "traefik.http.services.keycloak.loadbalancer.healthcheck.interval=10s"
      ]

      check {
        type     = "http"
        path     = "/health/ready"
        interval = "15s"
        timeout  = "5s"
      }
    }

    # Internal service for cluster discovery
    service {
      name = "keycloak-cluster"
      port = "jgroups"

      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Wait for PostgreSQL to be available
    task "wait-for-db" {
      lifecycle {
        hook    = "prestart"
        sidecar = false
      }

      driver = "docker"

      config {
        image        = "postgres:15-alpine"
        network_mode = "host"
        command      = "sh"
        args         = ["-c", "until pg_isready -h ${var.postgres_host} -p 5432; do echo 'Waiting for PostgreSQL...'; sleep 2; done"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }

    task "keycloak" {
      driver = "docker"

      config {
        image        = "quay.io/keycloak/keycloak:24.0.4"
        network_mode = "host"
        
        args = [
          "start",
          "--hostname=${var.keycloak_domain}",
          "--hostname-strict=false",
          "--hostname-strict-backchannel=false",
          "--http-enabled=true",
          "--http-port=${NOMAD_HOST_PORT_http}",
          "--proxy=edge",
          "--health-enabled=true",
          "--metrics-enabled=true",
          # Clustering options
          "--cache=ispn",
          "--cache-stack=jdbc-ping"
        ]
      }

      env {
        KEYCLOAK_ADMIN          = var.keycloak_admin
        KEYCLOAK_ADMIN_PASSWORD = var.keycloak_admin_password
        
        # Database configuration
        KC_DB                   = "postgres"
        KC_DB_URL               = "jdbc:postgresql://${var.postgres_host}:5432/${var.postgres_db}"
        KC_DB_USERNAME          = var.postgres_user
        KC_DB_PASSWORD          = var.postgres_password
        
        # Proxy settings
        KC_PROXY                       = "edge"
        KC_HOSTNAME                    = var.keycloak_domain
        KC_HOSTNAME_STRICT             = "false"
        KC_HOSTNAME_STRICT_BACKCHANNEL = "false"
        KC_HTTP_ENABLED                = "true"
        
        # Clustering - distributed cache with JDBC_PING discovery
        KC_CACHE                       = "ispn"
        KC_CACHE_STACK                 = "jdbc-ping"
        
        # JGroups bind address - use node IP
        JAVA_OPTS_APPEND = "-Djgroups.dns.query=keycloak-cluster.service.consul -Djgroups.bind.address=${NOMAD_IP_http}"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      # Give Keycloak more time to start in cluster mode
      kill_timeout = "60s"
    }
  }
}
