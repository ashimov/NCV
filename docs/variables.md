# Variable Reference

Complete reference for all configurable variables in the NCV Ansible project.

## Table of Contents

- [Global Variables](#global-variables)
- [Preflight Variables](#preflight-variables)
- [Cleanup Variables](#cleanup-variables)
- [PKI/TLS Variables](#pkitls-variables)
- [Consul Variables](#consul-variables)
- [Nomad Variables](#nomad-variables)
- [Vault Variables](#vault-variables)
- [Firewall Variables](#firewall-variables)
- [Nomad Jobs Variables](#nomad-jobs-variables)
- [Load Balancer Variables](#load-balancer-variables)

## Global Variables

Defined in `group_vars/all.yml`:

| Variable | Default | Description |
|---|---|---|
| `cluster_name` | `ncv` | Cluster identifier used in naming and tagging |
| `cluster_domain` | `example.internal` | Internal domain for cluster DNS |
| `node_ip` | `{{ ansible_host | default(ansible_facts.default_ipv4.address) }}` | IP address for service binding |

## Preflight Variables

Defined in `roles/preflight/defaults/main.yml`:

| Variable | Default | Description |
|---|---|---|
| `preflight_enabled` | `false` | Enable preflight checks |
| `preflight_debian_distributions` | `["Ubuntu"]` | Debian-family distributions allowed |
| `preflight_ubuntu_versions` | `["22.04","24.04"]` | Supported Ubuntu versions |
| `preflight_redhat_distributions` | `["OracleLinux","AlmaLinux"]` | RedHat-family distributions allowed |
| `preflight_require_consul` | `true` | Require Consul servers if Consul groups exist |
| `preflight_require_nomad` | `true` | Require Nomad servers if Nomad groups exist |
| `preflight_require_vault` | `false` | Require Vault servers |
| `preflight_require_pki` | `true` | Require PKI target groups when PKI enabled |
| `preflight_check_unique_node_ip` | `true` | Ensure node_ip values are unique |
| `preflight_warn_on_insecure_defaults` | `true` | Warn on insecure defaults (e.g. empty consul_encrypt) |

## Cleanup Variables

Defined in `roles/cleanup/defaults/main.yml`:

| Variable | Default | Description |
|---|---|---|
| `cleanup_enabled` | `false` | Enable cleanup role |
| `cleanup_confirm` | `false` | Required confirmation to run cleanup |
| `cleanup_services` | `["consul","nomad","vault"]` | Services to stop/disable |
| `cleanup_stop_services` | `true` | Stop services during cleanup |
| `cleanup_disable_services` | `true` | Disable services during cleanup |
| `cleanup_remove_packages` | `false` | Remove packages |
| `cleanup_packages` | `["consul","nomad","vault"]` | Package names to remove |
| `cleanup_remove_users` | `false` | Remove service users |
| `cleanup_remove_groups` | `false` | Remove service groups |
| `cleanup_users` | `["consul","nomad","vault"]` | Users to remove |
| `cleanup_groups` | `["consul","nomad","vault"]` | Groups to remove |
| `cleanup_remove_data` | `false` | Remove data directories |
| `cleanup_remove_config` | `false` | Remove config directories |
| `cleanup_remove_tls` | `false` | Remove TLS directories |
| `cleanup_remove_logs` | `false` | Remove log directories |
| `cleanup_remove_local_pki` | `false` | Remove local `pki_root` directory |

## PKI/TLS Variables

### PKI Generation

| Variable | Default | Description |
|---|---|---|
| `pki_generate` | `true` | Enable automatic CA and certificate generation |
| `pki_root` | `{{ playbook_dir }}/pki` | Root directory for PKI artifacts |
| `pki_ca_dir` | `{{ pki_root }}/ca` | CA certificate directory |
| `pki_hosts_dir` | `{{ pki_root }}/hosts` | Host certificates directory |
| `pki_ca_key_size` | `4096` | CA private key size in bits |
| `pki_host_key_size` | `2048` | Host private key size in bits |
| `pki_valid_days` | `825` | Certificate validity period (~2 years) |
| `pki_host_extended_key_usage` | `["serverAuth", "clientAuth"]` | Extended key usage for host certificates |
| `pki_ca_common_name` | `{{ cluster_name }}-ca` | CA certificate common name |
| `pki_org` | `NCV` | Organization name in certificates |
| `pki_org_unit` | `Platform` | Organizational unit in certificates |
| `pki_country` | `US` | Country code in certificates |
| `pki_target_groups` | See defaults | List of inventory groups for certificate generation |
| `pki_install_cryptography` | `true` | Install cryptography requirements locally |
| `pki_force_regen` | `false` | Force regeneration of host certificates and keys |
| `pki_cryptography_packages` | `["packaging", "cryptography>=3.3"]` | Python packages to install for PKI |
| `pki_pip_extra_args` | `[]` | Extra pip arguments for PKI installs |
| `pki_python_interpreter` | `python3` | Python interpreter used for PKI tooling |
| `pki_use_venv` | `true` | Use a local virtual environment for PKI |
| `pki_venv_path` | `{{ pki_root }}/.venv` | Virtual environment directory |
| `pki_venv_python` | `{{ pki_venv_path }}/bin/python` | Virtual environment interpreter path |

### TLS Configuration

Each service (Consul, Nomad, Vault) has similar TLS variables:

- `consul_tls_enabled`, `consul_tls_source`, `consul_tls_ca_src`, `consul_tls_cert_src`, `consul_tls_key_src`
- `nomad_tls_enabled`, `nomad_tls_source`, `nomad_tls_ca_src`, `nomad_tls_cert_src`, `nomad_tls_key_src`
- `vault_tls_enabled`, `vault_tls_source`, `vault_tls_ca_src`, `vault_tls_cert_src`, `vault_tls_key_src`

## Consul Variables

| Variable | Default | Description |
|---|---|---|
| `consul_version` | `1.22.2` | Consul version to install |
| `consul_datacenter` | `dc1` | Datacenter identifier |
| `consul_server` | `false` | Run as server (set in group_vars) |
| `consul_bootstrap_expect` | `1` | Expected number of servers |
| `consul_retry_join` | Auto-detected | List of servers to join |
| `consul_retry_join_cloud_enabled` | `false` | Enable cloud auto-join |
| `consul_retry_join_cloud` | `[]` | Cloud auto-join configuration |
| `consul_http_port` | `8500` | HTTP API port |
| `consul_https_port` | `8501` | HTTPS API port |
| `consul_http_disable` | `true` | Disable HTTP when TLS is enabled |
| `consul_encrypt` | `""` | Gossip encryption key |
| `consul_acl_enabled` | `true` | Enable ACL system |
| `consul_acl_default_policy` | `deny` | Default ACL policy |
| `consul_connect_enabled` | `true` | Enable Consul Connect |

## Nomad Variables

| Variable | Default | Description |
|---|---|---|
| `nomad_version` | `1.11.1` | Nomad version to install |
| `nomad_region` | `global` | Region identifier |
| `nomad_datacenter` | `dc1` | Datacenter identifier |
| `nomad_server_enabled` | `false` | Enable server mode |
| `nomad_client_enabled` | `false` | Enable client mode |
| `nomad_bootstrap_expect` | `1` | Expected number of servers |
| `nomad_retry_join` | Auto-detected | List of servers to join |
| `nomad_retry_join_cloud_enabled` | `false` | Enable cloud auto-join |
| `nomad_consul_enabled` | `true` | Enable Consul integration |
| `nomad_consul_address` | `127.0.0.1:8500` | Consul agent address |
| `nomad_consul_tls_enabled` | Auto-detected | Use TLS for Consul |
| `nomad_enable_raw_exec` | `false` | Enable raw_exec driver |
| `nomad_acl_enabled` | `false` | Enable ACL system |

## Vault Variables

| Variable | Default | Description |
|---|---|---|
| `vault_version` | `1.21.1` | Vault version to install |
| `vault_storage_backend` | `consul` | Storage: `consul` or `raft` |
| `vault_consul_address` | `127.0.0.1:8500` | Consul address |
| `vault_consul_token` | `""` | Consul ACL token (read from `vault_consul_token_vaulted` when set) |
| `vault_consul_token_vaulted` | `""` | Consul ACL token (store with Ansible Vault) |
| `vault_seal_type` | `none` | Seal: `none`, `awskms`, `gcpckms`, `transit` |
| `vault_seal_config` | `{}` | Seal-specific configuration |
| `vault_ui` | `true` | Enable web UI |

## Firewall Variables

| Variable | Default | Description |
|---|---|---|
| `firewall_enabled` | `false` | Enable firewall configuration |
| `firewall_backend` | `auto` | Backend: `auto`, `ufw`, `firewalld` |
| `firewall_allow_cidrs` | `[]` | List of allowed CIDR blocks |

## Nomad Jobs Variables

| Variable | Default | Description |
|---|---|---|
| `nomad_jobs_enabled` | `false` | Enable job deployment |
| `nomad_jobs_dir` | `{{ playbook_dir }}/jobs` | Job files directory |
| `nomad_jobs_nomad_addr` | `https://127.0.0.1:4646` | Nomad API address |
| `nomad_jobs_nomad_token` | `""` | Nomad ACL token |

## Load Balancer Variables

| Variable | Default | Description |
|---|---|---|
| `load_balancer_enabled` | `false` | Enable plan generation |
| `load_balancer_provider` | `aws` | Provider: `aws`, `gcp`, `manual` |
| `load_balancer_name` | `{{ cluster_name }}-lb` | Load balancer name |

## See Also

- [Main README](../README.md)
- [Load Balancer Guide](load_balancers.md)
- [Job Examples](../jobs/README.md)
