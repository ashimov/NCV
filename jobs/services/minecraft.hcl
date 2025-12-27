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
  default = "itzg/minecraft-server:latest"
}

variable "minecraft_port" {
  type    = number
  default = 25565
}

variable "env_eula" {
  type    = string
  default = "TRUE"
}

job "minecraft" {
  datacenters = var.datacenters
  type = "service"

  group "minecraft" {
    count = var.count

    network {
      mode = "bridge"
      port "minecraft" {
        to = var.minecraft_port
      }
    }

    volume "data" {
      type   = "host"
      source = "minecraft_data"
    }

    service {
      name = "minecraft"
      port = "minecraft"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "minecraft" {
      driver = "docker"

      config {
        image = var.image
        ports = ["minecraft"]
      }

      env {
        EULA = var.env_eula
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
        read_only   = false
      }
    }
  }
}
