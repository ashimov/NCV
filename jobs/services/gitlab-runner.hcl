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
  default = "gitlab/gitlab-runner:alpine"
}

job "gitlab-runner" {
  datacenters = var.datacenters
  type = "service"

  group "gitlab-runner" {
    count = var.count

    task "gitlab-runner" {
      driver = "docker"

      config {
        image = var.image
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
