# NCV Ansible - Production Nomad, Consul & Vault Stack

[![Ansible Lint](https://img.shields.io/badge/ansible--lint-passing-brightgreen)](https://github.com/ansible/ansible-lint)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/ansible-%3E%3D2.14-blue.svg)](https://docs.ansible.com/)

Production-ready Ansible automation for deploying and managing a complete HashiCorp stack (Nomad + Consul + Vault) with enterprise-grade security, high availability, and infrastructure-as-code best practices.

## 🎯 Features

### Security First
- ✅ **TLS enabled by default** for all services (Consul, Nomad, Vault)
- ✅ **ACLs enabled** by default with token management
- ✅ **Automated PKI** with local CA generation or external certificate integration
- ✅ **Secure secret handling** with `no_log` protection
- ✅ **Firewall integration** (ufw/firewalld) with sensible defaults including SSH protection

### Production Ready
- ✅ **Health checks** with automatic retry and timeout for service readiness
- ✅ **Configuration validation** before deployment (consul validate, nomad config validate)
- ✅ **Version pinning** for reproducible deployments
- ✅ **Idempotent operations** - safe to run multiple times
- ✅ **Multi-cloud support** - AWS, GCP, Azure auto-join capabilities
- ✅ **High availability** - multi-node cluster support out of the box

### Developer Friendly
- ✅ **Clean role structure** following Ansible best practices
- ✅ **Comprehensive defaults** - works out of the box
- ✅ **Extensive documentation** with examples
- ✅ **CI/CD ready** with ansible-lint and yamllint configurations
- ✅ **Galaxy compatible** with proper role metadata

## 📋 Table of Contents

- [Supported Operating Systems](#supported-operating-systems)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Configuration](#configuration)
  - [TLS/PKI Setup](#tlspki-setup)
  - [Consul Configuration](#consul-configuration)
  - [Nomad Configuration](#nomad-configuration)
  - [Vault Configuration](#vault-configuration)
  - [Firewall Configuration](#firewall-configuration)
  - [Cloud Auto-Join](#cloud-auto-join)
- [Advanced Features](#advanced-features)
  - [Nomad Jobs Deployment](#nomad-jobs-deployment)
  - [Load Balancer Planning](#load-balancer-planning)
  - [Version Management](#version-management)
- [Operations](#operations)
  - [Initial Deployment](#initial-deployment)
  - [Cluster Scaling](#cluster-scaling)
  - [Certificate Renewal](#certificate-renewal)
  - [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## 🖥️ Supported Operating Systems

| OS | Versions | Status |
|---|---|---|
| Ubuntu | 22.04 (Jammy), 24.04 (Noble) | ✅ Fully Supported |
| Oracle Linux | 8, 9 | ✅ Fully Supported |
| AlmaLinux | 8, 9 | ✅ Fully Supported |
| Rocky Linux | 8, 9 | ✅ Fully Supported |
| RHEL | 8, 9 | ✅ Fully Supported |

## 📦 Requirements

### Control Node
- **Ansible**: 2.14 or higher
- **Python**: 3.8 or higher
- **Collections**:
  - `community.crypto` (TLS/PKI operations)
  - `community.general` (firewall, utilities)
  - `ansible.posix` (firewalld support)

### Managed Nodes
- SSH access with sudo privileges
- Python 3.x installed
- Minimum 2GB RAM per node
- Minimum 20GB disk space

### Installation

```bash
# Install Ansible
pip install ansible>=2.14

# Install required collections
ansible-galaxy collection install -r collections/requirements.yml

# Install development tools (optional)
pip install -r requirements-dev.txt
```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd NCV
```

### 2. Create Your Inventory

```bash
# Copy example inventory
cp -R inventories/example inventories/my-cluster

# Edit hosts
vim inventories/my-cluster/hosts.yml
```

Example inventory structure:

```yaml
---
all:
  vars:
    ansible_user: ubuntu
    ansible_become: true
  children:
    consul_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    consul_clients:
      hosts:
        worker1: {ansible_host: 10.0.1.21}
        worker2: {ansible_host: 10.0.1.22}
    
    nomad_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
    
    nomad_clients:
      hosts:
        worker1: {ansible_host: 10.0.1.21}
        worker2: {ansible_host: 10.0.1.22}
    
    vault_servers:
      hosts:
        node1: {ansible_host: 10.0.1.11}
        node2: {ansible_host: 10.0.1.12}
        node3: {ansible_host: 10.0.1.13}
```

### 3. Review and Customize Variables

Edit `group_vars/all.yml` for global settings:

```yaml
---
cluster_name: production
cluster_domain: internal.company.com

# Version control
consul_version: "1.17.0"
nomad_version: "1.7.0"
vault_version: "1.15.0"

# Network
node_ip: "{{ ansible_host }}"

# TLS (enabled by default)
consul_tls_enabled: true
nomad_tls_enabled: true
vault_tls_enabled: true

# ACLs (enabled by default)
consul_acl_enabled: true
nomad_acl_enabled: false  # Set to true if needed

# Firewall protection
firewall_enabled: true
firewall_allow_cidrs:
  - 10.0.0.0/8  # Your private network
```

### 4. Deploy the Stack

```bash
# Full deployment
ansible-playbook -i inventories/my-cluster/hosts.yml site.yml

# Or deploy specific components
ansible-playbook -i inventories/my-cluster/hosts.yml site.yml --tags consul
ansible-playbook -i inventories/my-cluster/hosts.yml site.yml --tags nomad
ansible-playbook -i inventories/my-cluster/hosts.yml site.yml --tags vault
```

### 5. Verify Deployment

```bash
# Check Consul cluster
consul members
consul catalog services

# Check Nomad cluster
nomad server members
nomad node status

# Check Vault status
vault status
```

## 🏗️ Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                         │
│            (Optional, plan generated)                    │
└──────────────────┬──────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼───┐      ┌───▼───┐      ┌──▼────┐
│Consul │      │ Nomad │      │ Vault │
│Servers│◄────►│Servers│◄────►│Servers│
│  x3   │      │  x3   │      │  x3   │
└───┬───┘      └───┬───┘      └───┬───┘
    │              │              │
    │         ┌────▼────┐         │
    │         │  Nomad  │         │
    └────────►│ Clients ├─────────┘
              │   xN    │
              └─────────┘
```

### Roles Description

| Role | Purpose | Key Features |
|---|---|---|
| **common** | Base system setup | HashiCorp repos, base packages |
| **pki** | Certificate management | Local CA or external certs |
| **consul** | Service mesh & KV store | Server/client modes, ACLs, TLS |
| **nomad** | Workload orchestration | Server/client modes, drivers, TLS |
| **vault** | Secrets management | Consul/Raft storage, auto-unseal |
| **firewall** | Network security | ufw/firewalld with service ports |
| **nomad_jobs** | Job deployment | Automatic job submission |
| **load_balancer** | LB planning | AWS NLB/GCP GLB templates |

## ⚙️ Configuration

### TLS/PKI Setup

#### Option 1: Automatic PKI (Development/Testing)

The `pki` role automatically generates a local Certificate Authority and per-host certificates:

```yaml
# group_vars/all.yml
pki_generate: true
pki_valid_days: 825  # ~2 years
pki_ca_common_name: "my-cluster-ca"
pki_org: "My Company"
```

Generated certificates are stored in `pki/` (git-ignored) and automatically distributed.

#### Option 2: External Certificates (Production)

#### Option 2: External Certificates (Production)

Use certificates from your organization's PKI:

```yaml
# group_vars/all.yml
pki_generate: false

# Consul certificates
consul_tls_source: files
consul_tls_ca_src: /path/to/ca.pem
consul_tls_cert_src: /path/to/{{ inventory_hostname }}/cert.pem
consul_tls_key_src: /path/to/{{ inventory_hostname }}/key.pem

# Nomad certificates (similar pattern)
nomad_tls_source: files
nomad_tls_ca_src: /path/to/ca.pem
nomad_tls_cert_src: /path/to/{{ inventory_hostname }}/cert.pem
nomad_tls_key_src: /path/to/{{ inventory_hostname }}/key.pem

# Vault certificates (similar pattern)
vault_tls_source: files
vault_tls_ca_src: /path/to/ca.pem
vault_tls_cert_src: /path/to/{{ inventory_hostname }}/cert.pem
vault_tls_key_src: /path/to/{{ inventory_hostname }}/key.pem
```

**Security Features:**
- ✅ Pre-flight TLS file existence verification
- ✅ Automatic certificate distribution with correct permissions
- ✅ All private keys are handled with `no_log: true`

### Consul Configuration

#### Server Configuration

```yaml
# group_vars/consul_servers.yml
consul_server: true
consul_bootstrap_expect: 3  # Number of servers for quorum
```

#### Client Configuration

```yaml
# group_vars/consul_clients.yml
consul_server: false
```

#### ACL Setup

Consul ACLs are enabled by default for enhanced security:

```yaml
# group_vars/all.yml
consul_acl_enabled: true
consul_acl_default_policy: deny
consul_acl_down_policy: extend-cache

# After bootstrapping, set these tokens:
consul_acl_agent_token: "your-agent-token"
consul_acl_default_token: "your-default-token"
consul_acl_replication_token: "your-replication-token"  # Multi-DC only
```

**ACL Bootstrap Process:**

```bash
# On any Consul server
consul acl bootstrap

# Create agent policy
consul acl policy create -name agent -rules @agent-policy.hcl

# Create tokens
consul acl token create -policy-name agent
```

#### Gossip Encryption

Generate and set a gossip encryption key:

```bash
# Generate key
consul keygen

# Set in group_vars/all.yml
consul_encrypt: "your-32-byte-base64-key"
```

#### Service Mesh (Consul Connect)

```yaml
# group_vars/all.yml
consul_connect_enabled: true  # Enabled by default
```

### Nomad Configuration

#### Server Configuration

```yaml
# group_vars/nomad_servers.yml
nomad_server_enabled: true
nomad_client_enabled: false
nomad_bootstrap_expect: 3
```

#### Client Configuration

```yaml
# group_vars/nomad_clients.yml
nomad_server_enabled: false
nomad_client_enabled: true

# Enable specific task drivers
nomad_enable_raw_exec: false  # Security: disabled by default
```

#### Consul Integration

Nomad integrates with Consul for service discovery:

```yaml
# group_vars/all.yml
nomad_consul_enabled: true
nomad_consul_address: "127.0.0.1:8500"
nomad_consul_token: "your-consul-token"  # Optional, for ACL

# TLS integration
nomad_consul_tls_enabled: true  # Auto-enabled if Consul TLS is on
```

#### ACL Setup (Optional)

```yaml
# group_vars/all.yml
nomad_acl_enabled: true
```

Then bootstrap Nomad ACLs:

```bash
# On any Nomad server
nomad acl bootstrap
```

### Vault Configuration

#### Storage Backend

**Option 1: Consul Storage (Default)**

```yaml
# group_vars/all.yml
vault_storage_backend: consul
vault_consul_address: "127.0.0.1:8500"
vault_consul_token: "your-vault-consul-token"
```

**Option 2: Integrated Raft Storage**

```yaml
# group_vars/all.yml
vault_storage_backend: raft
```

#### Auto-Unseal

**AWS KMS Auto-Unseal**

```yaml
# group_vars/all.yml or inventory-specific vars
vault_seal_type: awskms
vault_seal_config:
  region: us-east-1
  kms_key_id: "your-kms-key-id"
  # AWS credentials via IAM role or environment
```

**GCP Cloud KMS Auto-Unseal**

```yaml
vault_seal_type: gcpckms
vault_seal_config:
  project: "your-project-id"
  region: "us-central1"
  key_ring: "vault-keyring"
  crypto_key: "vault-key"
```

**Transit Auto-Unseal** (using another Vault cluster)

```yaml
vault_seal_type: transit
vault_seal_config:
  address: "https://vault-primary.company.com"
  token: "your-transit-token"
  key_name: "vault-unseal-key"
  mount_path: "transit"
```

#### Vault Initialization

After deployment, initialize Vault:

```bash
# Initialize (returns unseal keys and root token)
vault operator init

# Unseal (if not using auto-unseal, repeat on each server)
vault operator unseal

# Configure
export VAULT_TOKEN="root-token"
vault secrets enable -path=secret kv-v2
```

### Firewall Configuration

Automated firewall configuration with sensible defaults:

```yaml
# group_vars/all.yml
firewall_enabled: true
firewall_backend: auto  # Detects ufw (Debian) or firewalld (RedHat)

# Restrict access to specific networks
firewall_allow_cidrs:
  - 10.0.0.0/8        # Private network
  - 192.168.0.0/16    # Private network
```

**Default Allowed Ports:**
- `22/tcp` - SSH (added for safety)
- `8300/tcp` - Consul server RPC
- `8301/tcp,udp` - Consul serf LAN
- `8302/tcp,udp` - Consul serf WAN
- `8500/tcp` - Consul HTTP/HTTPS API
- `8502/tcp` - Consul gRPC (xDS for Envoy)
- `8600/tcp,udp` - Consul DNS
- `4646/tcp` - Nomad HTTP/HTTPS API
- `4647/tcp` - Nomad RPC
- `4648/tcp,udp` - Nomad serf
- `8200/tcp` - Vault API
- `8201/tcp` - Vault cluster

### Cloud Auto-Join

#### AWS Cloud Auto-Join

```yaml
# inventories/aws/group_vars/all.yml
consul_retry_join_cloud_enabled: true
consul_retry_join_cloud:
  - "provider=aws tag_key=consul_server tag_value=true region=us-east-1"

nomad_retry_join_cloud_enabled: true
nomad_retry_join_cloud:
  - "provider=aws tag_key=nomad_server tag_value=true region=us-east-1"
```

#### GCP Cloud Auto-Join

```yaml
# inventories/gcp/group_vars/all.yml
consul_retry_join_cloud_enabled: true
consul_retry_join_cloud:
  - "provider=gce project_name=my-project tag_value=consul-server"

nomad_retry_join_cloud_enabled: true
nomad_retry_join_cloud:
  - "provider=gce project_name=my-project tag_value=nomad-server"
```

#### Azure Cloud Auto-Join

```yaml
consul_retry_join_cloud_enabled: true
consul_retry_join_cloud:
  - "provider=azure tag_name=consul_server tag_value=true subscription_id=..."

nomad_retry_join_cloud_enabled: true
nomad_retry_join_cloud:
  - "provider=azure tag_name=nomad_server tag_value=true subscription_id=..."
```

**Best Practice:** Keep cloud-specific auto-join configuration in inventory-specific files:
- `inventories/aws/group_vars/all.yml`
- `inventories/gcp/group_vars/all.yml`
- `inventories/azure/group_vars/all.yml`

## 🚀 Advanced Features

### Nomad Jobs Deployment

Automatically deploy Nomad job files during provisioning:

```yaml
# group_vars/all.yml or nomad_servers.yml
nomad_jobs_enabled: true
nomad_jobs_dir: "{{ playbook_dir }}/jobs"
nomad_jobs_nomad_addr: "https://127.0.0.1:4646"
nomad_jobs_nomad_token: "your-nomad-token"  # If ACLs enabled
```

Place your `.hcl` job files in `jobs/` directory:

```
jobs/
├── services/
│   ├── nginx.hcl
│   ├── postgres.hcl
│   └── redis.hcl
└── examples/
    └── whoami.hcl
```

Jobs are automatically:
- ✅ Planned before execution (`nomad job plan`)
- ✅ Deployed with change detection
- ✅ Handled securely (tokens protected with `no_log`)

### Load Balancer Planning

Generate load balancer configuration templates:

```yaml
# group_vars/all.yml
load_balancer_enabled: true
load_balancer_provider: aws  # aws | gcp | manual
load_balancer_name: "{{ cluster_name }}-lb"
```

Generates planning documents in `docs/lb-plans/` with:
- Listener configurations for all services
- Target group definitions
- Health check recommendations
- Cloud-specific implementation notes

See `docs/load_balancers.md` for detailed guidance.

### Version Management

Control HashiCorp product versions explicitly:

```yaml
# group_vars/all.yml
consul_version: "1.17.0"    # Specific version
nomad_version: "1.7.0"      # Specific version
vault_version: "1.15.0"     # Specific version

# Or use latest (not recommended for production)
consul_version: "latest"
```

**Version Pinning Benefits:**
- ✅ Reproducible deployments
- ✅ Controlled upgrades
- ✅ Testing consistency
- ✅ Rollback capability

## 🔧 Operations

### Initial Deployment

```bash
# 1. Deploy infrastructure
ansible-playbook -i inventories/prod/hosts.yml site.yml

# 2. Verify Consul
consul members
consul catalog services

# 3. Bootstrap Consul ACLs
consul acl bootstrap

# 4. Verify Nomad
nomad server members
nomad node status

# 5. Bootstrap Nomad ACLs (if enabled)
nomad acl bootstrap

# 6. Initialize Vault
vault operator init
vault operator unseal  # Or auto-unseal

# 7. Configure Vault
export VAULT_TOKEN="root-token"
vault auth enable approle
vault secrets enable -path=secret kv-v2
```

### Cluster Scaling

#### Adding Consul/Nomad Servers

1. Update inventory with new servers
2. Run playbook with limit:

```bash
ansible-playbook -i inventories/prod/hosts.yml site.yml --limit new-server
```

#### Adding Nomad Clients

```yaml
# Update inventories/prod/hosts.yml
nomad_clients:
  hosts:
    worker3: {ansible_host: 10.0.1.23}
    worker4: {ansible_host: 10.0.1.24}
```

```bash
ansible-playbook -i inventories/prod/hosts.yml site.yml --limit nomad_clients
```

### Certificate Renewal

#### With Automatic PKI

```bash
# Regenerate all certificates
rm -rf pki/
ansible-playbook -i inventories/prod/hosts.yml site.yml --tags pki

# Restart services to load new certs
ansible-playbook -i inventories/prod/hosts.yml site.yml --tags consul,nomad,vault
```

#### With External PKI

1. Obtain new certificates from your PKI
2. Update certificate files
3. Run playbook to distribute:

```bash
ansible-playbook -i inventories/prod/hosts.yml site.yml --tags consul,nomad,vault
```

### Troubleshooting

#### Check Service Status

```bash
# On managed nodes
systemctl status consul
systemctl status nomad
systemctl status vault

# Check logs
journalctl -u consul -f
journalctl -u nomad -f
journalctl -u vault -f
```

#### Verify Configuration

The playbook automatically validates configurations:
- ✅ `consul validate /etc/consul.d`
- ✅ `nomad config validate /etc/nomad.d/nomad.hcl`
- ✅ `vault server -config /etc/vault.d/vault.hcl -test`

#### Health Checks

All services include automatic health checks with retries:

```yaml
# Consul health check (automatic)
# GET http(s)://127.0.0.1:8500/v1/status/leader
# Retries: 30 × 2s = 60s timeout

# Nomad health check (automatic)
# GET http(s)://127.0.0.1:4646/v1/agent/self
# Retries: 30 × 2s = 60s timeout

# Vault health check (automatic)
# GET https://127.0.0.1:8200/v1/sys/health
# Accepts: 200, 429, 501, 503 (sealed states)
# Retries: 30 × 2s = 60s timeout
```

#### Common Issues

**1. TLS Certificate Errors**

```bash
# Verify certificates exist
ls -la /etc/consul.d/tls/
ls -la /etc/nomad.d/tls/
ls -la /etc/vault.d/tls/

# Check certificate validity
openssl x509 -in /etc/consul.d/tls/cert.pem -text -noout
```

**2. ACL Token Issues**

```bash
# Test Consul token
consul members -token="your-token"

# Test Nomad token
nomad node status -token="your-token"
```

**3. Firewall Blocking**

```bash
# Check firewall status
sudo ufw status verbose          # Ubuntu
sudo firewall-cmd --list-all     # RHEL

# Temporarily disable for testing
sudo ufw disable
sudo systemctl stop firewalld
```

## 💻 Development

### Running Lint

```bash
# Install development dependencies
pip install -r requirements-dev.txt

# Run all linters
./scripts/lint.sh

# Run individually
yamllint .
ansible-lint
```

### Testing Changes

```bash
# Syntax check
ansible-playbook site.yml --syntax-check

# Dry run (check mode)
ansible-playbook -i inventories/test/hosts.yml site.yml --check

# Run specific roles
ansible-playbook -i inventories/test/hosts.yml site.yml --tags consul
```

### Role Structure

```
roles/
├── common/          # Base system configuration
│   ├── defaults/
│   ├── handlers/
│   ├── meta/
│   ├── tasks/
│   └── templates/
├── consul/          # Consul deployment
├── nomad/           # Nomad deployment
├── vault/           # Vault deployment
├── pki/             # PKI/TLS management
├── firewall/        # Firewall configuration
├── nomad_jobs/      # Nomad job deployment
└── load_balancer/   # LB planning
```

## 📚 Documentation

- [Load Balancer Configuration](docs/load_balancers.md) - Detailed LB setup guide
- [Variable Reference](docs/variables.md) - Complete variable documentation
- [Job Examples](jobs/README.md) - Nomad job examples and catalog
- [Code Review Fixes](CODE_REVIEW_FIXES.md) - Recent improvements and fixes

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Run linters before committing
4. Submit a pull request with clear description

### Code Standards

- Follow Ansible best practices
- Use FQCN for all modules
- Include `become: true` where needed
- Add `no_log: true` for sensitive data
- Document all variables in defaults/
- Pass ansible-lint with production profile

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- HashiCorp for Consul, Nomad, and Vault
- Ansible community for collections and best practices
- Contributors and users of this project

## 📞 Support

- Issues: [GitHub Issues](https://github.com/your-org/ncv/issues)
- Discussions: [GitHub Discussions](https://github.com/your-org/ncv/discussions)
- Documentation: [Wiki](https://github.com/your-org/ncv/wiki)

---

**Made with ❤️ for the DevOps community**
