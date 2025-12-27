job "vault-template-example" {
  datacenters = ["dc1"]
  type = "service"

  group "vault-template-example" {
    count = 1

    vault {
      policies = ["default"]
    }

    network {
      mode = "bridge"
      port "http" { to = 8080 }
    }

    service {
      name = "vault-template-example"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "app" {
      driver = "docker"
      config {
        image = "nginx:1.25-alpine"
        ports = ["http"]
      }

      template {
        data = <<EOF
        export APP_USER={{ with secret "secret/data/app" }}{{ .Data.data.user }}{{ end }}
        export APP_PASSWORD={{ with secret "secret/data/app" }}{{ .Data.data.password }}{{ end }}
        EOF
        destination = "secrets/app.env"
        env         = true
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
