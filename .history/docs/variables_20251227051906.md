# Variable Reference

Complete reference for all configurable variables in the NCV Ansible project.

## Table of Contents

- [Global Variables](#global-variables)
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
| `node_ip` | `{{ ansible_host }}` | IP address for service binding |

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
| `pki_ca_common_name` | `{{ cluster_name }}-ca` | CA certificate common name |
| `pki_org` | `NCV` | Organization name in certificates |
| `pki_org_unit` | `Platform` | Organizational unit in certificates |
| `pki_country` | `US` | Country code in certificates |
| `pki_target_groups` | See defaults | List of inventory groups for certificate generation |

### TLS Configuration

Each service (Consul, Nomad, Vault) has similar TLS variables:

- `consul_tls_enabled`, `consul_tls_source`, `consul_tls_ca_src`, `consul_tls_cert_src`, `consul_tls_key_src`
- `nomad_tls_enabled`, `nomad_tls_source`, `nomad_tls_ca_src`, `nomad_tls_cert_src`, `nomad_tls_key_src`
- `vault_tls_enabled`, `vault_tls_source`, `vault_tls_ca_src`, `vault_tls_cert_src`, `vault_tls_key_src`

## Consul Variables

| Variable | Default | Description |
|---|---|---|
| `consul_version` | `1.17.0` | Consul version to install |
| `consul_datacenter` | `dc1` | Datacenter identifier |
| `consul_server` | `false` | Run as server (set in group_vars) |
| `consul_bootstrap_expect` | `1` | Expected number of servers |
| `consul_retry_join` | Auto-detected | List of servers to join |
| `consul_retry_join_cloud_enabled` | `false` | Enable cloud auto-join |
| `consul_retry_join_cloud` | `[]` | Cloud auto-join configuration |
| `consul_encrypt` | `""` | Gossip encryption key |
| `consul_acl_enabled` | `true` | Enable ACL system |
| `consul_acl_default_policy` | `deny` | Default ACL policy |
| `consul_connect_enabled` | `true` | Enable Consul Connect |

## Nomad Variables

| Variable | Default | Description |
|---|---|---|
| `nomad_version` | `1.7.0` | Nomad version to install |
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
| `vault_version` | `1.15.0` | Vault version to install |
| `vault_storage_backend` | `consul` | Storage: `consul` or `raft` |
| `vault_consul_address` | `127.0.0.1:8500` | Consul address |
| `vault_consul_token` | `""` | Consul ACL token |
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
