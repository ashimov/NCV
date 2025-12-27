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
  default = "bitnami/kafka:3.7.0"
}

variable "kafka_port" {
  type    = number
  default = 9092
}

variable "env_kafka_cfg_process_roles" {
  type    = string
  default = "broker,controller"
}

variable "env_kafka_cfg_node_id" {
  type    = string
  default = "1"
}

variable "env_kafka_cfg_listeners" {
  type    = string
  default = "PLAINTEXT://:9092,CONTROLLER://:9093"
}

variable "env_kafka_cfg_advertised_listeners" {
  type    = string
  default = "PLAINTEXT://127.0.0.1:9092"
}

variable "env_kafka_cfg_controller_listener_names" {
  type    = string
  default = "CONTROLLER"
}

variable "env_kafka_cfg_controller_quorum_voters" {
  type    = string
  default = "1@127.0.0.1:9093"
}

variable "env_allow_plaintext_listener" {
  type    = string
  default = "yes"
}

job "kafka" {
  datacenters = var.datacenters
  type = "service"

  group "kafka" {
    count = var.count

    network {
      mode = "bridge"
      port "kafka" {
        to = var.kafka_port
      }
    }

    service {
      name = "kafka"
      port = "kafka"
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "kafka" {
      driver = "docker"

      config {
        image = var.image
        ports = ["kafka"]
      }

      env {
        KAFKA_CFG_PROCESS_ROLES = var.env_kafka_cfg_process_roles
        KAFKA_CFG_NODE_ID = var.env_kafka_cfg_node_id
        KAFKA_CFG_LISTENERS = var.env_kafka_cfg_listeners
        KAFKA_CFG_ADVERTISED_LISTENERS = var.env_kafka_cfg_advertised_listeners
        KAFKA_CFG_CONTROLLER_LISTENER_NAMES = var.env_kafka_cfg_controller_listener_names
        KAFKA_CFG_CONTROLLER_QUORUM_VOTERS = var.env_kafka_cfg_controller_quorum_voters
        ALLOW_PLAINTEXT_LISTENER = var.env_allow_plaintext_listener
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }
    }
  }
}
