variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

job "nexus" {
  datacenters = var.datacenters
  type        = "service"

  group "nexus" {
    count = 1

    network {
      mode = "host"
      port "http" {
        static = 8081
      }
      # Docker registry port (if needed)
      port "docker" {
        static = 8082
      }
    }

    # Persistent storage for Nexus data
    volume "nexus_data" {
      type      = "host"
      source    = "nexus_data"
      read_only = false
    }

    service {
      name = "nexus"
      port = "http"
      
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nexus.rule=Host(`nexus.ashimov.com`)",
        "traefik.http.routers.nexus.entrypoints=websecure",
        "traefik.http.routers.nexus.tls.certresolver=letsencrypt",
        "traefik.http.services.nexus.loadbalancer.server.port=8081"
      ]

      check {
        type     = "http"
        path     = "/service/rest/v1/status"
        interval = "30s"
        timeout  = "5s"
      }
    }

    task "nexus" {
      driver = "docker"

      config {
        image        = "sonatype/nexus3:3.70.0"
        network_mode = "host"
        
        # Run as nexus user (UID 200)
        # volumes will be owned by this user
      }

      volume_mount {
        volume      = "nexus_data"
        destination = "/nexus-data"
        read_only   = false
      }

      env {
        INSTALL4J_ADD_VM_PARAMS = "-Xms1024m -Xmx1024m -XX:MaxDirectMemorySize=1024m"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }
    }
  }
}
