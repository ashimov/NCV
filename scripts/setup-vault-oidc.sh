#!/bin/bash
# Configure Vault OIDC authentication with Keycloak
#
# Usage: ./setup-vault-oidc.sh <vault_client_secret>
#
# Prerequisites:
# - Vault running and unsealed
# - Keycloak configured with Vault client (run setup-keycloak.sh first)
# - VAULT_ADDR and VAULT_TOKEN environment variables set

set -e

# Configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-https://keycloak.ashimov.com}"
REALM_NAME="${REALM_NAME:-ncv}"
VAULT_CLIENT_ID="${VAULT_CLIENT_ID:-vault}"
DOMAIN="${DOMAIN:-ashimov.com}"

# Get client secret from argument or environment
VAULT_CLIENT_SECRET="${1:-${VAULT_CLIENT_SECRET}}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    if [ -z "$VAULT_ADDR" ]; then
        log_error "VAULT_ADDR is not set"
        echo "export VAULT_ADDR=https://vault.${DOMAIN}"
        exit 1
    fi
    
    if [ -z "$VAULT_TOKEN" ]; then
        log_error "VAULT_TOKEN is not set"
        echo "export VAULT_TOKEN=<your_root_token>"
        exit 1
    fi
    
    if [ -z "$VAULT_CLIENT_SECRET" ]; then
        log_error "Vault client secret not provided"
        echo "Usage: $0 <vault_client_secret>"
        echo "Or set VAULT_CLIENT_SECRET environment variable"
        exit 1
    fi
    
    if ! command -v vault &> /dev/null; then
        log_error "vault CLI not found"
        exit 1
    fi
}

# Enable OIDC auth method
enable_oidc() {
    log_info "Enabling OIDC auth method..."
    
    # Check if already enabled
    if vault auth list 2>/dev/null | grep -q "^oidc/"; then
        log_warn "OIDC auth method already enabled"
    else
        vault auth enable oidc
        log_info "OIDC auth method enabled"
    fi
}

# Configure OIDC
configure_oidc() {
    log_info "Configuring OIDC with Keycloak..."
    
    vault write auth/oidc/config \
        oidc_discovery_url="${KEYCLOAK_URL}/realms/${REALM_NAME}" \
        oidc_client_id="${VAULT_CLIENT_ID}" \
        oidc_client_secret="${VAULT_CLIENT_SECRET}" \
        default_role="default"
    
    log_info "OIDC configuration complete"
}

# Create admin policy
create_admin_policy() {
    log_info "Creating admin policy..."
    
    vault policy write admin - <<EOF
# Full admin access
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF
    
    log_info "Admin policy created"
}

# Create default user policy
create_user_policy() {
    log_info "Creating default user policy..."
    
    vault policy write user - <<EOF
# Read system health
path "sys/health" {
  capabilities = ["read"]
}

# Read own token info
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Renew own token
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Revoke own token
path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Read secret engines list
path "sys/mounts" {
  capabilities = ["read"]
}

# KV secrets - user's own namespace
path "secret/data/users/{{identity.entity.aliases.auth_oidc_*.name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/users/{{identity.entity.aliases.auth_oidc_*.name}}/*" {
  capabilities = ["list", "read", "delete"]
}

# Read shared secrets
path "secret/data/shared/*" {
  capabilities = ["read", "list"]
}
EOF
    
    log_info "User policy created"
}

# Create OIDC roles
create_roles() {
    log_info "Creating OIDC roles..."
    
    # Default role for all users
    vault write auth/oidc/role/default \
        bound_audiences="${VAULT_CLIENT_ID}" \
        allowed_redirect_uris="https://vault.${DOMAIN}/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="https://vault.${DOMAIN}/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="email" \
        groups_claim="groups" \
        policies="default,user" \
        ttl="1h" \
        max_ttl="24h"
    
    log_info "Default role created"
    
    # Admin role
    vault write auth/oidc/role/admin \
        bound_audiences="${VAULT_CLIENT_ID}" \
        allowed_redirect_uris="https://vault.${DOMAIN}/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="https://vault.${DOMAIN}/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="email" \
        groups_claim="groups" \
        bound_claims='{"email": ["berik@ashimov.com"]}' \
        policies="default,admin" \
        ttl="1h" \
        max_ttl="24h"
    
    log_info "Admin role created"
}

# Enable KV secrets engine if not enabled
enable_kv() {
    log_info "Checking KV secrets engine..."
    
    if vault secrets list 2>/dev/null | grep -q "^secret/"; then
        log_warn "KV secrets engine already enabled at secret/"
    else
        vault secrets enable -path=secret kv-v2
        log_info "KV secrets engine enabled"
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "VAULT OIDC CONFIGURATION COMPLETE"
    echo "=========================================="
    echo ""
    echo "OIDC Discovery URL: ${KEYCLOAK_URL}/realms/${REALM_NAME}"
    echo "Client ID: ${VAULT_CLIENT_ID}"
    echo ""
    echo "Roles configured:"
    echo "  - default: For all authenticated users"
    echo "  - admin: Full admin access for berik@ashimov.com"
    echo ""
    echo "To login via UI:"
    echo "  1. Go to https://vault.${DOMAIN}/ui"
    echo "  2. Select 'OIDC' method"
    echo "  3. Click 'Sign in with OIDC Provider'"
    echo ""
    echo "To login via CLI:"
    echo "  vault login -method=oidc role=default"
    echo "  vault login -method=oidc role=admin  # for admin access"
    echo ""
    echo "=========================================="
}

# Main
main() {
    log_info "Starting Vault OIDC setup..."
    
    check_prerequisites
    enable_oidc
    configure_oidc
    create_admin_policy
    create_user_policy
    create_roles
    enable_kv
    print_summary
    
    log_info "Setup complete!"
}

main "$@"
