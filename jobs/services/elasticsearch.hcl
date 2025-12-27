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
  default = 500
}

variable "memory" {
  type    = number
  default = 512
}

variable "image" {
  type    = string
  default = "docker.elastic.co/elasticsearch/elasticsearch:8.12.2"
}

variable "http_port" {
  type    = number
  default = 9200
}

variable "env_discovery_type" {
  type    = string
  default = "single-node"
}

variable "env_xpack_security_enabled" {
  type    = string
  default = "false"
}

job "elasticsearch" {
  datacenters = var.datacenters
  type = "service"

  group "elasticsearch" {
    count = var.count

    network {
      mode = "bridge"
      port "http" {
        to = var.http_port
      }
    }

    volume "data" {
      type   = "host"
      source = "elasticsearch_data"
    }

    service {
      name = "elasticsearch"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "elasticsearch" {
      driver = "docker"

      config {
        image = var.image
        ports = ["http"]
      }

      env {
        "discovery.type" = var.env_discovery_type
        "xpack.security.enabled" = var.env_xpack_security_enabled
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/usr/share/elasticsearch/data"
        read_only   = false
      }
    }
  }
}
