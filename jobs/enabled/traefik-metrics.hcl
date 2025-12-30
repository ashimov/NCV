variable "image" {
  type    = string
  default = "traefik/whoami:v1.10.1"
}

job "traefik-metrics" {
  datacenters = ["dc1"]
  type = "service"
  group "traefik-metrics" {
    count = 1
    network {
      mode = "host"
      port "metrics" {
        static = 8082
      }
    }
    service {
      name = "traefik-metrics"
      port = "metrics"
      tags = ["traefik.enable=false"]
    }
    task "traefik-metrics" {
      driver = "docker"
      config {
        image = var.image
        ports = ["metrics"]
      }
      resources {
        cpu    = 50
        memory = 32
      }
    }
  }
}
