# Security Best Practices

## 🔐 Managing Secrets

This project follows security best practices by **NOT** storing secrets in plain text in git repositories.

### Critical Security Note

❌ **NEVER commit the following to git:**
- Consul encryption keys (`consul_encrypt`)
- Nomad Consul tokens (`nomad_consul_token`)
- Vault tokens (`vault_consul_token`)
- ACL tokens
- Private keys or certificates
- Any passwords or sensitive configuration

### Recommended Approach: Ansible Vault

#### 1. Create an Ansible Vault Password File

```bash
# Generate a strong password
openssl rand -base64 32 > .vault_pass
chmod 600 .vault_pass
```

Add `.vault_pass` to your `.gitignore` (already done).

#### 2. Create Encrypted Secrets File

```bash
# Create encrypted secrets file
ansible-vault create group_vars/all/vault.yml --vault-password-file .vault_pass
```

Add your secrets in the vault file:

```yaml
---
# Consul gossip encryption key (generate with: consul keygen)
vault_consul_encrypt: "your-consul-encryption-key-here"

# Nomad Consul token (generate via Consul ACL)
vault_nomad_consul_token: "your-nomad-consul-token-here"

# Vault Consul token (generate via Consul ACL)
vault_consul_token_secret: "your-vault-consul-token-here"

# Other sensitive variables
vault_acl_master_token: "your-master-acl-token"
```

#### 3. Reference Vault Variables in group_vars/all.yml

```yaml
# group_vars/all.yml
consul_encrypt: "{{ vault_consul_encrypt | default('') }}"
nomad_consul_token: "{{ vault_nomad_consul_token | default('') }}"
vault_consul_token: "{{ vault_consul_token_secret | default('') }}"
```

#### 4. Configure Ansible to Use Vault Password

Option A: Add to `ansible.cfg`:
```ini
[defaults]
vault_password_file = .vault_pass
```

Option B: Use command line:
```bash
ansible-playbook -i inventory site.yml --vault-password-file .vault_pass
```

### Generating Secrets

#### Consul Encryption Key

```bash
# Install consul first, then:
consul keygen
# Example output: ShvXiMkny+Dfwt12Q5jrhoOFophlcUMrTQLFdIrsxJ0=
```

Or use OpenSSL:
```bash
openssl rand -base64 32
```

#### Consul ACL Tokens

```bash
# Bootstrap ACL system (run once)
consul acl bootstrap

# Create tokens for Nomad and Vault
consul acl token create -description "Nomad Agent Token" \
  -policy-name nomad-agent

consul acl token create -description "Vault Storage Token" \
  -policy-name vault-storage
```

### Alternative: External Secret Management

For production environments, consider using:

1. **HashiCorp Vault** - Store secrets in Vault and retrieve via lookup plugin
2. **AWS Secrets Manager** - For AWS deployments
3. **Azure Key Vault** - For Azure deployments
4. **GCP Secret Manager** - For GCP deployments

Example with HashiCorp Vault lookup:
```yaml
consul_encrypt: "{{ lookup('hashi_vault', 'secret=secret/ncv/consul_encrypt:value') }}"
```

## 🛡️ Firewall Configuration

The project enables firewall by default. Customize allowed CIDRs:

```yaml
# group_vars/all.yml
firewall_enabled: true
firewall_allow_cidrs:
  - "10.0.0.0/8"      # Private network
  - "192.168.0.0/16"  # Private network
  - "YOUR.IP.ADD.RESS/32"  # Your admin IP
```

## 🔒 TLS/PKI Security

### Using Auto-Generated PKI (Development)

```yaml
pki_generate: true
pki_root: "{{ playbook_dir }}/pki"  # Git-ignored directory
```

The `pki/` directory is automatically excluded from git.

### Using External PKI (Production)

Store certificates outside the repository:

```yaml
pki_generate: false
consul_tls_ca_src: /secure/path/to/ca.pem
consul_tls_cert_src: /secure/path/to/{{ inventory_hostname }}/cert.pem
consul_tls_key_src: /secure/path/to/{{ inventory_hostname }}/key.pem
```

## ✅ Security Checklist

Before deploying to production:

- [ ] All secrets moved to ansible-vault encrypted files
- [ ] `.vault_pass` file is secured (chmod 600) and git-ignored
- [ ] Firewall is enabled with appropriate CIDR restrictions
- [ ] TLS is enabled for all services
- [ ] ACLs are enabled for Consul and configured properly
- [ ] Preflight checks are enabled
- [ ] No hardcoded secrets in `group_vars/all.yml`
- [ ] Production certificates are used (not self-signed dev certs)
- [ ] Regular security audits are scheduled
- [ ] Backup procedures are in place

## 📚 Additional Resources

- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Consul Security Model](https://www.consul.io/docs/security)
- [Nomad Security Model](https://www.nomadproject.io/docs/security)
- [Vault Security Model](https://www.vaultproject.io/docs/internals/security)

## 🚨 Security Issues

If you discover a security vulnerability, please email security@ashimov.com instead of using the issue tracker.
