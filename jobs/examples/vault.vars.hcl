datacenters = ["dc1"]
count = 1
cpu = 500
memory = 512
http_port = 8200

# Example args for DEV mode only. Replace with production config.
task_args = ["server", "-dev", "-dev-listen-address=0.0.0.0:8200"]

# Example env for dev only; production should use Vault config files and proper seal.
# env_vault_dev_root_token_id = "change_me"
