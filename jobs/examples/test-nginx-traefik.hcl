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
  default = 256
}

variable "memory" {
  type    = number
  default = 256
}

variable "image" {
  type    = string
  default = "nginx:latest"
}

variable "domain" {
  type    = string
  default = "traefik.local"
}

job "test-nginx" {
  datacenters = var.datacenters
  type        = "service"

  group "nginx" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = 80
      }
    }

    service {
      name = "test-nginx"
      port = "http"

      # Traefik auto-discovery tags
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.test-nginx.rule=Host(`test-nginx.traefik.local`)",
        "traefik.http.routers.test-nginx.entrypoints=web"
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }

      check_restart {
        limit = 3
        grace = "10s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
        
        # Simple test page
        volumes = [
          "local/index.html:/usr/share/nginx/html/index.html"
        ]
      }

      # Create a custom index.html
      template {
        data = <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Test Nginx via Traefik</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
    .container { background: rgba(0,0,0,0.3); padding: 30px; border-radius: 10px; max-width: 600px; }
    h1 { color: #fff; }
    .info { background: rgba(0,0,0,0.2); padding: 15px; border-radius: 5px; margin: 10px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>✅ Traefik Routing Works!</h1>
    <p>This nginx instance is successfully routed through Traefik.</p>
    
    <div class="info">
      <strong>Service:</strong> test-nginx<br>
      <strong>Hostname:</strong> <code>${HOSTNAME}</code><br>
      <strong>Timestamp:</strong> <code>${TIMESTAMP}</code>
    </div>

    <div class="info">
      <strong>Traefik Features Tested:</strong>
      <ul>
        <li>✅ Consul Catalog Discovery</li>
        <li>✅ Service Tag-based Routing</li>
        <li>✅ HTTP Entrypoint</li>
        <li>✅ Load Balancing</li>
      </ul>
    </div>

    <p style="margin-top: 30px; font-size: 12px; opacity: 0.7;">
      Next: Configure HTTPS, add dashboard auth, deploy more services
    </p>
  </div>
</body>
</html>
EOF
        destination = "local/index.html"
        perms       = "644"
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }

    restart {
      attempts = 3
      delay    = "10s"
      interval = "5m"
      mode     = "fail"
    }
  }
}
