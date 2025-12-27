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
  default = 300
}

variable "memory" {
  type    = number
  default = 256
}

variable "image" {
  type    = string
  default = "nginx:1.25-alpine"
}

variable "http_port" {
  type    = number
  default = 80
}

variable "upstream_service_name" {
  type    = string
  default = "whoami"
}

variable "upstream_local_port" {
  type    = number
  default = 9000
}

job "nginx-mesh" {
  datacenters = var.datacenters
  type = "service"

  group "nginx" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    service {
      name = "nginx"
      port = "http"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = var.upstream_service_name
              local_bind_port  = var.upstream_local_port
            }
          }
        }
      }
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        volumes = [
          "local/nginx.conf:/etc/nginx/nginx.conf:ro"
        ]
      }

      template {
        data = <<NGINX
worker_processes  1;

error_log /dev/stderr info;

pid /tmp/nginx.pid;

events {
  worker_connections  1024;
}

http {
  access_log /dev/stdout;

  server {
    listen 80;

    location / {
      proxy_pass http://127.0.0.1:${var.upstream_local_port};
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
}
NGINX
        destination = "local/nginx.conf"
        change_mode = "restart"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
