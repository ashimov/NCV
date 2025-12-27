datacenters = ["dc1"]
count = 3
cpu = 500
memory = 512
http_port = 8500

task_args = ["agent", "-config=/secrets/consul.hcl"]

consul_config = <<CONFIG
# Example production Consul config (adjust for your environment)

server = true
bootstrap_expect = 3

node_name = "consul-1"
datacenter = "dc1"

bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"

# retry_join = ["provider=aws tag_key=consul tag_value=server"]

data_dir = "/consul/data"

ui_config {
  enabled = true
}

connect {
  enabled = true
}

acl {
  enabled = true
  default_policy = "deny"
  down_policy = "extend-cache"
  enable_token_persistence = true
}

# tls {
#   defaults {
#     verify_incoming = true
#     verify_outgoing = true
#     verify_server_hostname = true
#     ca_file = "/secrets/ca.pem"
#     cert_file = "/secrets/consul.pem"
#     key_file = "/secrets/consul.key"
#   }
# }
CONFIG
