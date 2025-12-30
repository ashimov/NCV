#!/usr/bin/env bash
# Quick setup script for NCV secrets management

set -euo pipefail

VAULT_PASS_FILE=".vault_pass"
VAULT_FILE="group_vars/all/vault.yml"
VAULT_EXAMPLE="group_vars/all/vault.yml.example"

echo "🔒 NCV Security Setup Script"
echo "=============================="
echo ""

# Check if already configured
if [ -f "$VAULT_PASS_FILE" ] && [ -f "$VAULT_FILE" ]; then
    echo "⚠️  Vault already configured!"
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 0
    fi
fi

# Step 1: Create vault password
echo "📝 Step 1: Creating vault password..."
if [ ! -f "$VAULT_PASS_FILE" ]; then
    openssl rand -base64 32 > "$VAULT_PASS_FILE"
    chmod 600 "$VAULT_PASS_FILE"
    echo "✅ Created $VAULT_PASS_FILE"
else
    echo "⏭️  $VAULT_PASS_FILE already exists, skipping..."
fi

# Step 2: Create vault file from template
echo ""
echo "📄 Step 2: Creating vault file..."
if [ ! -f "$VAULT_FILE" ]; then
    if [ -f "$VAULT_EXAMPLE" ]; then
        cp "$VAULT_EXAMPLE" "$VAULT_FILE"
        echo "✅ Created $VAULT_FILE from template"
    else
        echo "❌ Template file $VAULT_EXAMPLE not found!"
        exit 1
    fi
else
    echo "⏭️  $VAULT_FILE already exists, skipping..."
fi

# Step 3: Generate secrets
echo ""
echo "🔑 Step 3: Generating sample secrets..."
echo ""

# Generate Consul encryption key
if command -v consul &> /dev/null; then
    CONSUL_KEY=$(consul keygen)
    echo "✅ Consul encryption key: $CONSUL_KEY"
else
    CONSUL_KEY=$(openssl rand -base64 32)
    echo "✅ Consul encryption key (openssl): $CONSUL_KEY"
fi

# Generate sample tokens
NOMAD_TOKEN=$(openssl rand -hex 16)
VAULT_TOKEN=$(openssl rand -hex 16)

echo "✅ Nomad Consul token: $NOMAD_TOKEN"
echo "✅ Vault Consul token: $VAULT_TOKEN"
echo ""
echo "⚠️  NOTE: These are sample tokens. In production:"
echo "   - Bootstrap Consul ACL system first"
echo "   - Generate proper ACL tokens with appropriate policies"
echo ""

# Step 4: Update vault file with secrets
echo "📝 Step 4: Updating vault file with generated secrets..."
cat > "$VAULT_FILE" <<EOF
---
# Ansible Vault Encrypted Secrets File
# Generated on $(date)

# Consul gossip encryption key
vault_consul_encrypt: "$CONSUL_KEY"

# Nomad Consul integration token
# TODO: Replace with actual ACL token from: consul acl token create
vault_nomad_consul_token: "$NOMAD_TOKEN"

# Vault Consul storage token
# TODO: Replace with actual ACL token from: consul acl token create
vault_consul_token_secret: "$VAULT_TOKEN"

# Consul ACL tokens (optional)
vault_consul_acl_agent_token: ""
vault_consul_acl_default_token: ""
vault_consul_acl_replication_token: ""

# Add your own secrets below
EOF

echo "✅ Vault file populated with generated secrets"
echo ""

# Step 5: Encrypt vault file
echo "🔐 Step 5: Encrypting vault file..."
ansible-vault encrypt "$VAULT_FILE" --vault-password-file "$VAULT_PASS_FILE" 2>/dev/null || {
    echo "❌ Failed to encrypt vault file"
    exit 1
}
echo "✅ Vault file encrypted successfully"
echo ""

# Step 6: Verify
echo "✅ Step 6: Verification..."
if head -n 1 "$VAULT_FILE" | grep -q '$ANSIBLE_VAULT'; then
    echo "✅ Vault file is properly encrypted"
else
    echo "❌ Vault file encryption failed!"
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "✅ Vault password: $VAULT_PASS_FILE (keep this secure!)"
echo "✅ Encrypted secrets: $VAULT_FILE"
echo ""
echo "📋 Next Steps:"
echo "1. Review secrets: ansible-vault edit $VAULT_FILE --vault-password-file $VAULT_PASS_FILE"
echo "2. Update with production tokens (see SECURITY.md)"
echo "3. Test deployment: ansible-playbook site.yml --syntax-check"
echo "4. Deploy: ansible-playbook -i inventories/your-inventory/hosts.yml site.yml"
echo ""
echo "📚 Documentation:"
echo "- SECURITY.md - Complete security guide"
echo "- MIGRATION.md - Migration instructions"
echo "- README.md - Project documentation"
echo ""
echo "⚠️  IMPORTANT: Add $VAULT_PASS_FILE to .gitignore (already done)"
echo "⚠️  NEVER commit $VAULT_PASS_FILE or decrypted secrets to git!"
