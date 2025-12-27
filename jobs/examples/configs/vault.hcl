# Example production Vault config (adjust for your environment)

ui = true
disable_mlock = false

listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_cert_file = "/secrets/vault.crt"
  tls_key_file = "/secrets/vault.key"
}

storage "consul" {
  address = "127.0.0.1:8500"
  path = "vault/"
}

# seal "awskms" {
#   region = "us-east-1"
#   kms_key_id = "..."
# }
