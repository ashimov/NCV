# Migration Guide - Version 2.0 Security Updates

## ⚠️ Important Notice

This update includes **critical security fixes** that require action before deployment.

## 🚀 Quick Migration (5 minutes)

### Step 1: Backup Current Configuration
```bash
cp group_vars/all.yml group_vars/all.yml.backup
```

### Step 2: Create Vault Password File
```bash
# Generate a strong password
openssl rand -base64 32 > .vault_pass
chmod 600 .vault_pass

# Add to ansible.cfg (already configured)
# vault_password_file = .vault_pass
```

### Step 3: Create Encrypted Secrets File
```bash
# Create new vault file from template
cp group_vars/all/vault.yml.example group_vars/all/vault.yml

# Encrypt it
ansible-vault encrypt group_vars/all/vault.yml --vault-password-file .vault_pass
```

### Step 4: Add Your Secrets
```bash
# Edit the encrypted file
ansible-vault edit group_vars/all/vault.yml --vault-password-file .vault_pass
```

Add your secrets:
```yaml
---
# Generate Consul encryption key
# consul keygen
vault_consul_encrypt: "YOUR-CONSUL-ENCRYPTION-KEY"

# Generate via Consul ACL
vault_nomad_consul_token: "YOUR-NOMAD-TOKEN"
vault_consul_token_secret: "YOUR-VAULT-TOKEN"
```

### Step 5: Verify Configuration
```bash
# Test that vault decryption works
ansible-playbook site.yml --syntax-check

# Run preflight checks
ansible-playbook -i inventories/your-inventory/hosts.yml site.yml --tags preflight
```

### Step 6: Deploy
```bash
# Deploy with vault password
ansible-playbook -i inventories/your-inventory/hosts.yml site.yml
```

## 🔧 Advanced Configuration

### Using Environment Variable for Vault Password
```bash
# Export password
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass

# Run playbook (no need for --vault-password-file)
ansible-playbook -i inventories/your-inventory/hosts.yml site.yml
```

### Generating Secrets

#### Consul Encryption Key
```bash
# Method 1: Using consul
consul keygen

# Method 2: Using openssl
openssl rand -base64 32
```

#### Consul ACL Tokens
```bash
# Bootstrap ACL system (run once)
consul acl bootstrap

# Create Nomad agent token
consul acl token create \
  -description "Nomad Agent Token" \
  -policy-name nomad-agent

# Create Vault storage token
consul acl token create \
  -description "Vault Storage Token" \
  -policy-name vault-storage
```

## ⚙️ Configuration Changes

### Defaults Changed
The following defaults have changed for better security:

```yaml
# OLD (Insecure)
firewall_enabled: false
preflight_enabled: false

# NEW (Secure)
firewall_enabled: true
preflight_enabled: true
```

### To Use Old Behavior
If you need to disable security features temporarily:

```yaml
# group_vars/all.yml
firewall_enabled: false
preflight_enabled: false
```

**Note**: Not recommended for production!

## 🔍 Verification

### Check No Secrets in Git
```bash
# Should return empty
grep -r "password.*=.*['\"]" group_vars/ --exclude="*.example"
```

### Verify Vault File is Encrypted
```bash
# Should show "$ANSIBLE_VAULT" header
head -n 1 group_vars/all/vault.yml
```

### Test Deployment
```bash
# Dry run
ansible-playbook -i inventories/test/hosts.yml site.yml --check

# Deploy to test environment first
ansible-playbook -i inventories/test/hosts.yml site.yml
```

## 🆘 Troubleshooting

### Error: "Vault password not found"
```bash
# Ensure .vault_pass exists and has correct permissions
ls -la .vault_pass
chmod 600 .vault_pass
```

### Error: "Preflight checks failed"
```bash
# Check requirements
ansible-playbook site.yml --tags preflight -vv

# Skip temporarily if needed
ansible-playbook site.yml --skip-tags preflight
```

### Error: "Port already in use"
```bash
# Check what's using the ports
sudo netstat -tlnp | grep -E '(8500|8501|4646|8200)'

# Stop conflicting services or adjust ports in inventory
```

## 📚 Additional Resources

- [SECURITY.md](SECURITY.md) - Complete security guide
- [CHANGELOG-SECURITY.md](CHANGELOG-SECURITY.md) - All changes made
- [README.md](README.md) - Project documentation

## ✅ Post-Migration Checklist

- [ ] `.vault_pass` created and secured (chmod 600)
- [ ] `group_vars/all/vault.yml` created and encrypted
- [ ] All secrets moved from `group_vars/all.yml` to vault
- [ ] Syntax check passed
- [ ] Preflight checks passed
- [ ] Test deployment successful
- [ ] Production deployment scheduled
- [ ] Team notified of new secret management process
- [ ] Documentation updated

## 🎉 You're Done!

Your NCV stack is now secured with best practices for secret management.

For questions or issues:
- Check [SECURITY.md](SECURITY.md)
- Review [GitHub Issues](https://github.com/ashimov/NCV/issues)
- Consult the team

---

**Version**: 2.0
**Date**: December 29, 2025
**Status**: Production Ready ✅
