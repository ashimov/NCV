variable "datacenters" {
  type    = list(string)
  default = ["dc1"]
}

variable "count" {
  type    = number
  default = 1
}

variable "elasticsearch_image" {
  type    = string
  default = "docker.elastic.co/elasticsearch/elasticsearch:8.12.2"
}

variable "kibana_image" {
  type    = string
  default = "docker.elastic.co/kibana/kibana:8.12.2"
}

variable "logstash_image" {
  type    = string
  default = "docker.elastic.co/logstash/logstash:8.12.2"
}

variable "elasticsearch_port" {
  type    = number
  default = 9200
}

variable "kibana_port" {
  type    = number
  default = 5601
}

variable "logstash_port" {
  type    = number
  default = 9600
}

variable "elasticsearch_cpu" {
  type    = number
  default = 1000
}

variable "elasticsearch_memory" {
  type    = number
  default = 2048
}

variable "kibana_cpu" {
  type    = number
  default = 500
}

variable "kibana_memory" {
  type    = number
  default = 512
}

variable "logstash_cpu" {
  type    = number
  default = 500
}

variable "logstash_memory" {
  type    = number
  default = 512
}

variable "env_discovery_type" {
  type    = string
  default = "single-node"
}

variable "env_xpack_security_enabled" {
  type    = string
  default = "false"
}

job "elk" {
  datacenters = var.datacenters
  type = "service"

  group "elk" {
    count = var.count

    network {
      mode = "bridge"
      port "elasticsearch" { to = var.elasticsearch_port }
      port "kibana"        { to = var.kibana_port }
      port "logstash"      { to = var.logstash_port }
    }

    volume "data" {
      type   = "host"
      source = "elk_data"
    }

    service {
      name = "elasticsearch"
      port = "elasticsearch"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    service {
      name = "kibana"
      port = "kibana"
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
        image = var.elasticsearch_image
        ports = ["elasticsearch"]
      }
      env {
        "discovery.type" = var.env_discovery_type
        "xpack.security.enabled" = var.env_xpack_security_enabled
      }
      resources {
        cpu    = var.elasticsearch_cpu
        memory = var.elasticsearch_memory
      }
      volume_mount {
        volume      = "data"
        destination = "/usr/share/elasticsearch/data"
        read_only   = false
      }
    }

    task "kibana" {
      driver = "docker"
      config {
        image = var.kibana_image
        ports = ["kibana"]
      }
      resources {
        cpu    = var.kibana_cpu
        memory = var.kibana_memory
      }
    }

    task "logstash" {
      driver = "docker"
      config {
        image = var.logstash_image
        ports = ["logstash"]
      }
      resources {
        cpu    = var.logstash_cpu
        memory = var.logstash_memory
      }
    }
  }
}
