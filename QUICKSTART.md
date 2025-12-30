# Quick Start Guide

Get your NCV cluster up and running in under 10 minutes.

## Prerequisites

- 3+ Ubuntu/RHEL servers with SSH access
- Ansible 2.14+ installed on your control node
- Sudo privileges on target servers

## Installation

```bash
# 1. Install Ansible
pip3 install ansible>=2.14

# 2. Clone repository
git clone <repository-url>
cd NCV

# 3. Install required collections
ansible-galaxy collection install -r collections/requirements.yml
```

## Basic Setup

### 1. Create Inventory

```bash
cp -R inventories/example inventories/quickstart
vim inventories/quickstart/hosts.yml
```

Minimal inventory:
```yaml
---
all:
  vars:
    ansible_user: ubuntu
  children:
    consul_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    consul_clients:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    nomad_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    nomad_clients:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    vault_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
```

### 2. Configure Variables (Optional)

Edit `group_vars/all.yml` if needed:
```yaml
---
cluster_name: quickstart
cluster_domain: cluster.local

# Defaults are production-ready, but you can customize:
consul_version: "1.22.2"
nomad_version: "1.11.1"
vault_version: "1.21.1"

# Enable firewall (recommended)
firewall_enabled: true
firewall_allow_cidrs:
  - 10.0.0.0/8
```

### 3. Deploy

```bash
# Optional: Preflight checks
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags preflight \
  -e preflight_enabled=true

# Full deployment (5-10 minutes)
ansible-playbook -i inventories/quickstart/hosts.yml site.yml

# Or step by step:
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags pki
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags consul
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags nomad
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags vault
```

### Backups (Optional)

```bash
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags backup \
  -e backup_enabled=true
```

### Cleanup (Destructive, Optional)

```bash
# Stop services and remove data/config/TLS (use with care)
ansible-playbook -i inventories/quickstart/hosts.yml site.yml --tags cleanup \
  -e cleanup_enabled=true \
  -e cleanup_confirm=true \
  -e cleanup_remove_data=true \
  -e cleanup_remove_config=true \
  -e cleanup_remove_tls=true
```

### 4. Verify

```bash
# SSH to any node
ssh ubuntu@10.0.1.11

# Check services
systemctl status consul
systemctl status nomad
systemctl status vault

# Check Consul cluster
consul members
consul catalog services

# Check Nomad cluster
nomad server members
nomad node status

# Check Vault
vault status
```

### 5. Initialize Vault

```bash
# Initialize Vault (save output!)
vault operator init

# Example output:
# Unseal Key 1: xxx
# Unseal Key 2: yyy
# Unseal Key 3: zzz
# Unseal Key 4: aaa
# Unseal Key 5: bbb
# Initial Root Token: root-token-here

# Unseal Vault on each server (need 3 keys)
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>

# Login
export VAULT_TOKEN="root-token-here"
vault status

# Enable secrets engine
vault secrets enable -path=secret kv-v2
```

### 6. Bootstrap ACLs (Optional but Recommended)

```bash
# Consul ACL bootstrap
consul acl bootstrap

# Save the SecretID as consul_acl_default_token
# Update group_vars/all.yml with tokens
```

## What's Next?

- **Deploy workloads**: Place Nomad job files in `jobs/` and set `nomad_jobs_enabled: true`
- **Configure service mesh**: Consul Connect is enabled by default
- **Add monitoring**: Deploy Prometheus, Grafana via Nomad
- **Set up secrets**: Use Vault for application secrets
- **Load balancing**: Enable `load_balancer_enabled: true` for planning

## Common Issues

### Connection Timeout
```bash
# Test connectivity
ansible all -i inventories/quickstart/hosts.yml -m ping

# Check SSH access
ssh -v ubuntu@10.0.1.11
```

### Permission Denied
```bash
# Ensure sudo is available
ansible all -i inventories/quickstart/hosts.yml -m shell -a "sudo whoami"
```

### Service Not Starting
```bash
# Check logs
journalctl -u consul -f
journalctl -u nomad -f
journalctl -u vault -f

# Validate configuration
consul validate /etc/consul.d
nomad config validate /etc/nomad.d/nomad.hcl
```

### Firewall Blocking
```bash
# Temporarily disable to test
sudo ufw disable          # Ubuntu
sudo systemctl stop firewalld  # RHEL

# Check if services work, then configure firewall properly
```

## Complete Example

```bash
# One-liner for quick setup
git clone <repo> && cd NCV && \
pip3 install ansible>=2.14 && \
ansible-galaxy collection install -r collections/requirements.yml && \
cp -R inventories/example inventories/test && \
# Edit inventories/test/hosts.yml with your servers
ansible-playbook -i inventories/test/hosts.yml site.yml
```

## Documentation

- [Full README](README.md) - Complete documentation
- [Variables Guide](docs/variables.md) - All configuration options
- [Load Balancers](docs/load_balancers.md) - LB setup
- [Job Examples](jobs/README.md) - Nomad job templates

## Support

- **Issues**: Report bugs and feature requests
- **Discussions**: Ask questions and share ideas
- **Wiki**: Additional guides and examples

---

**Ready for production?** See the [full documentation](README.md) for advanced configuration, security hardening, and operational best practices.
