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
  default = "mysql:8.4"
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "env_mysql_root_password" {
  type    = string
  default = "change_me"
}

job "mysql" {
  datacenters = var.datacenters
  type = "service"

  group "mysql" {
    count = var.count

    network {
      mode = "bridge"
      port "db" {
        to = var.db_port
      }
    }

    volume "data" {
      type   = "host"
      source = "mysql_data"
    }

    service {
      name = "mysql"
      port = "db"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "mysql" {
      driver = "docker"

      config {
        image = var.image
        ports = ["db"]
      }

      env {
        MYSQL_ROOT_PASSWORD = var.env_mysql_root_password
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      volume_mount {
        volume      = "data"
        destination = "/var/lib/mysql"
        read_only   = false
      }
    }
  }
}
