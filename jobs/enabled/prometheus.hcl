variable "image" {
  type    = string
  default = "prom/prometheus:v2.51.2"
}

variable "prometheus_domain" {
  type    = string
  default = "prometheus.ashimov.com"
}

job "prometheus" {
  datacenters = ["dc1"]
  type = "service"

  group "prometheus" {
    count = 1
    network {
      mode = "host"
      port "web" {
        static = 9090
      }
    }
    service {
      name = "prometheus"
      port = "web"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus.rule=Host(`${var.prometheus_domain}`)",
        "traefik.http.routers.prometheus.entrypoints=websecure",
        "traefik.http.routers.prometheus.tls=true",
        "traefik.http.routers.prometheus.middlewares=forward-auth@file"
      ]
      check {
        type     = "http"
        path     = "/-/ready"
        interval = "10s"
        timeout  = "2s"
      }
    }
    task "prometheus" {
      driver = "docker"
      config {
        image = var.image
        ports = ["web"]
        volumes = ["local/prometheus-data:/prometheus", "local/prometheus-config:/etc/prometheus/"]
      }
      volume {
        type      = "host"
        source    = "/opt/prometheus-data"
        destination = "local/prometheus-data"
        read_only  = false
      }
      volume {
        type      = "host"
        source    = "/opt/prometheus-config"
        destination = "local/prometheus-config"
        read_only  = false
      }
      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
