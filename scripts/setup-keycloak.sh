#!/bin/bash
# Setup Keycloak realm, clients, and user for Traefik and Vault OIDC authentication
# 
# Usage: ./setup-keycloak.sh
#
# Prerequisites:
# - Keycloak running and accessible at KEYCLOAK_URL
# - curl and jq installed

set -e

# Configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-https://keycloak.ashimov.com}"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-Admin123!}"
REALM_NAME="ncv"
DOMAIN="ashimov.com"

# User credentials
USER_EMAIL="berik@ashimov.com"
USER_PASSWORD="sBcqF78tk0!@#"
USER_FIRST_NAME="Berik"
USER_LAST_NAME="Ashimov"

# Client configurations
TRAEFIK_CLIENT_ID="traefik"
VAULT_CLIENT_ID="vault"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for Keycloak to be ready
wait_for_keycloak() {
    log_info "Waiting for Keycloak to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -k "${KEYCLOAK_URL}/health/ready" | grep -q "UP"; then
            log_info "Keycloak is ready!"
            return 0
        fi
        log_warn "Attempt $attempt/$max_attempts - Keycloak not ready, waiting..."
        sleep 10
        ((attempt++))
    done
    
    log_error "Keycloak did not become ready in time"
    exit 1
}

# Get admin access token
get_admin_token() {
    log_info "Getting admin access token..."
    
    TOKEN=$(curl -s -k -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=${KEYCLOAK_ADMIN}" \
        -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" | jq -r '.access_token')
    
    if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
        log_error "Failed to get admin token"
        exit 1
    fi
    
    log_info "Got admin token"
}

# Create realm
create_realm() {
    log_info "Creating realm: ${REALM_NAME}..."
    
    # Check if realm exists
    REALM_EXISTS=$(curl -s -k -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}")
    
    if [ "$REALM_EXISTS" == "200" ]; then
        log_warn "Realm ${REALM_NAME} already exists, skipping..."
        return 0
    fi
    
    curl -s -k -X POST "${KEYCLOAK_URL}/admin/realms" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{
            "realm": "'"${REALM_NAME}"'",
            "enabled": true,
            "displayName": "NCV Cluster",
            "displayNameHtml": "<h1>NCV Cluster</h1>",
            "loginTheme": "keycloak",
            "accountTheme": "keycloak.v2",
            "adminTheme": "keycloak.v2",
            "emailTheme": "keycloak",
            "sslRequired": "external",
            "registrationAllowed": false,
            "registrationEmailAsUsername": true,
            "rememberMe": true,
            "verifyEmail": false,
            "loginWithEmailAllowed": true,
            "duplicateEmailsAllowed": false,
            "resetPasswordAllowed": true,
            "editUsernameAllowed": false,
            "bruteForceProtected": true,
            "permanentLockout": false,
            "maxFailureWaitSeconds": 900,
            "minimumQuickLoginWaitSeconds": 60,
            "waitIncrementSeconds": 60,
            "quickLoginCheckMilliSeconds": 1000,
            "maxDeltaTimeSeconds": 43200,
            "failureFactor": 5,
            "accessTokenLifespan": 300,
            "accessTokenLifespanForImplicitFlow": 900,
            "ssoSessionIdleTimeout": 1800,
            "ssoSessionMaxLifespan": 36000,
            "offlineSessionIdleTimeout": 2592000,
            "accessCodeLifespan": 60,
            "accessCodeLifespanUserAction": 300,
            "accessCodeLifespanLogin": 1800,
            "actionTokenGeneratedByAdminLifespan": 43200,
            "actionTokenGeneratedByUserLifespan": 300
        }'
    
    log_info "Realm ${REALM_NAME} created successfully"
}

# Create Traefik OIDC client
create_traefik_client() {
    log_info "Creating Traefik OIDC client..."
    
    # Check if client exists
    CLIENT_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${TRAEFIK_CLIENT_ID}" | jq -r '.[0].id')
    
    if [ "$CLIENT_ID" != "null" ] && [ -n "$CLIENT_ID" ]; then
        log_warn "Traefik client already exists, updating..."
        
        curl -s -k -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "clientId": "'"${TRAEFIK_CLIENT_ID}"'",
                "name": "Traefik Forward Auth",
                "description": "OIDC client for Traefik Forward Auth",
                "enabled": true,
                "clientAuthenticatorType": "client-secret",
                "redirectUris": [
                    "https://auth.'"${DOMAIN}"'/_oauth",
                    "https://traefik.'"${DOMAIN}"'/*",
                    "https://*.'"${DOMAIN}"'/_oauth"
                ],
                "webOrigins": [
                    "https://*.'"${DOMAIN}"'"
                ],
                "publicClient": false,
                "protocol": "openid-connect",
                "standardFlowEnabled": true,
                "implicitFlowEnabled": false,
                "directAccessGrantsEnabled": true,
                "serviceAccountsEnabled": false,
                "authorizationServicesEnabled": false,
                "fullScopeAllowed": true,
                "defaultClientScopes": ["openid", "profile", "email"],
                "optionalClientScopes": ["roles"]
            }'
    else
        curl -s -k -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "clientId": "'"${TRAEFIK_CLIENT_ID}"'",
                "name": "Traefik Forward Auth",
                "description": "OIDC client for Traefik Forward Auth",
                "enabled": true,
                "clientAuthenticatorType": "client-secret",
                "secret": "traefik-client-secret-change-me",
                "redirectUris": [
                    "https://auth.'"${DOMAIN}"'/_oauth",
                    "https://traefik.'"${DOMAIN}"'/*",
                    "https://*.'"${DOMAIN}"'/_oauth"
                ],
                "webOrigins": [
                    "https://*.'"${DOMAIN}"'"
                ],
                "publicClient": false,
                "protocol": "openid-connect",
                "standardFlowEnabled": true,
                "implicitFlowEnabled": false,
                "directAccessGrantsEnabled": true,
                "serviceAccountsEnabled": false,
                "authorizationServicesEnabled": false,
                "fullScopeAllowed": true,
                "defaultClientScopes": ["openid", "profile", "email"],
                "optionalClientScopes": ["roles"]
            }'
    fi
    
    # Get client secret
    CLIENT_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${TRAEFIK_CLIENT_ID}" | jq -r '.[0].id')
    
    TRAEFIK_SECRET=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}/client-secret" | jq -r '.value')
    
    log_info "Traefik client created/updated successfully"
    echo ""
    echo "=========================================="
    echo "TRAEFIK CLIENT CREDENTIALS"
    echo "=========================================="
    echo "Client ID: ${TRAEFIK_CLIENT_ID}"
    echo "Client Secret: ${TRAEFIK_SECRET}"
    echo "=========================================="
    echo ""
}

# Create Vault OIDC client
create_vault_client() {
    log_info "Creating Vault OIDC client..."
    
    # Check if client exists
    CLIENT_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${VAULT_CLIENT_ID}" | jq -r '.[0].id')
    
    if [ "$CLIENT_ID" != "null" ] && [ -n "$CLIENT_ID" ]; then
        log_warn "Vault client already exists, updating..."
        
        curl -s -k -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "clientId": "'"${VAULT_CLIENT_ID}"'",
                "name": "HashiCorp Vault",
                "description": "OIDC client for Vault authentication",
                "enabled": true,
                "clientAuthenticatorType": "client-secret",
                "redirectUris": [
                    "https://vault.'"${DOMAIN}"'/ui/vault/auth/oidc/oidc/callback",
                    "https://vault.'"${DOMAIN}"'/oidc/callback",
                    "http://localhost:8250/oidc/callback"
                ],
                "webOrigins": [
                    "https://vault.'"${DOMAIN}"'",
                    "+"
                ],
                "publicClient": false,
                "protocol": "openid-connect",
                "standardFlowEnabled": true,
                "implicitFlowEnabled": false,
                "directAccessGrantsEnabled": true,
                "serviceAccountsEnabled": false,
                "authorizationServicesEnabled": false,
                "fullScopeAllowed": true,
                "defaultClientScopes": ["openid", "profile", "email"],
                "optionalClientScopes": ["roles"]
            }'
    else
        curl -s -k -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "clientId": "'"${VAULT_CLIENT_ID}"'",
                "name": "HashiCorp Vault",
                "description": "OIDC client for Vault authentication",
                "enabled": true,
                "clientAuthenticatorType": "client-secret",
                "secret": "vault-client-secret-change-me",
                "redirectUris": [
                    "https://vault.'"${DOMAIN}"'/ui/vault/auth/oidc/oidc/callback",
                    "https://vault.'"${DOMAIN}"'/oidc/callback",
                    "http://localhost:8250/oidc/callback"
                ],
                "webOrigins": [
                    "https://vault.'"${DOMAIN}"'",
                    "+"
                ],
                "publicClient": false,
                "protocol": "openid-connect",
                "standardFlowEnabled": true,
                "implicitFlowEnabled": false,
                "directAccessGrantsEnabled": true,
                "serviceAccountsEnabled": false,
                "authorizationServicesEnabled": false,
                "fullScopeAllowed": true,
                "defaultClientScopes": ["openid", "profile", "email"],
                "optionalClientScopes": ["roles"]
            }'
    fi
    
    # Get client secret
    CLIENT_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=${VAULT_CLIENT_ID}" | jq -r '.[0].id')
    
    VAULT_SECRET=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_ID}/client-secret" | jq -r '.value')
    
    log_info "Vault client created/updated successfully"
    echo ""
    echo "=========================================="
    echo "VAULT CLIENT CREDENTIALS"
    echo "=========================================="
    echo "Client ID: ${VAULT_CLIENT_ID}"
    echo "Client Secret: ${VAULT_SECRET}"
    echo "=========================================="
    echo ""
}

# Create user
create_user() {
    log_info "Creating user: ${USER_EMAIL}..."
    
    # Check if user exists
    USER_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users?email=${USER_EMAIL}" | jq -r '.[0].id')
    
    if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
        log_warn "User ${USER_EMAIL} already exists, updating password..."
        
        # Update password
        curl -s -k -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users/${USER_ID}/reset-password" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "type": "password",
                "value": "'"${USER_PASSWORD}"'",
                "temporary": false
            }'
    else
        # Create user
        curl -s -k -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d '{
                "username": "'"${USER_EMAIL}"'",
                "email": "'"${USER_EMAIL}"'",
                "emailVerified": true,
                "enabled": true,
                "firstName": "'"${USER_FIRST_NAME}"'",
                "lastName": "'"${USER_LAST_NAME}"'",
                "credentials": [{
                    "type": "password",
                    "value": "'"${USER_PASSWORD}"'",
                    "temporary": false
                }]
            }'
        
        log_info "User ${USER_EMAIL} created successfully"
    fi
    
    # Get user ID
    USER_ID=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users?email=${USER_EMAIL}" | jq -r '.[0].id')
    
    # Assign realm-admin role to make user admin
    log_info "Assigning admin roles to user..."
    
    # Get realm-management client ID
    REALM_MGMT_CLIENT=$(curl -s -k \
        -H "Authorization: Bearer ${TOKEN}" \
        "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients?clientId=realm-management" | jq -r '.[0].id')
    
    if [ "$REALM_MGMT_CLIENT" != "null" ] && [ -n "$REALM_MGMT_CLIENT" ]; then
        # Get realm-admin role
        ADMIN_ROLE=$(curl -s -k \
            -H "Authorization: Bearer ${TOKEN}" \
            "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${REALM_MGMT_CLIENT}/roles/realm-admin")
        
        # Assign role to user
        curl -s -k -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users/${USER_ID}/role-mappings/clients/${REALM_MGMT_CLIENT}" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "Content-Type: application/json" \
            -d "[${ADMIN_ROLE}]"
    fi
    
    log_info "User setup complete"
}

# Generate configuration summary
print_summary() {
    echo ""
    echo "=========================================="
    echo "KEYCLOAK SETUP COMPLETE"
    echo "=========================================="
    echo ""
    echo "Realm: ${REALM_NAME}"
    echo "Keycloak URL: ${KEYCLOAK_URL}"
    echo "OIDC Issuer URL: ${KEYCLOAK_URL}/realms/${REALM_NAME}"
    echo ""
    echo "User Credentials:"
    echo "  Email: ${USER_EMAIL}"
    echo "  Password: ${USER_PASSWORD}"
    echo ""
    echo "=========================================="
    echo "NEXT STEPS"
    echo "=========================================="
    echo ""
    echo "1. Update traefik-forward-auth.hcl with the Traefik client secret"
    echo ""
    echo "2. Configure Vault OIDC auth:"
    echo "   vault auth enable oidc"
    echo "   vault write auth/oidc/config \\"
    echo "       oidc_discovery_url=\"${KEYCLOAK_URL}/realms/${REALM_NAME}\" \\"
    echo "       oidc_client_id=\"${VAULT_CLIENT_ID}\" \\"
    echo "       oidc_client_secret=\"<VAULT_SECRET>\" \\"
    echo "       default_role=\"default\""
    echo ""
    echo "   vault write auth/oidc/role/default \\"
    echo "       bound_audiences=\"${VAULT_CLIENT_ID}\" \\"
    echo "       allowed_redirect_uris=\"https://vault.${DOMAIN}/ui/vault/auth/oidc/oidc/callback\" \\"
    echo "       allowed_redirect_uris=\"https://vault.${DOMAIN}/oidc/callback\" \\"
    echo "       allowed_redirect_uris=\"http://localhost:8250/oidc/callback\" \\"
    echo "       user_claim=\"email\" \\"
    echo "       policies=\"default\""
    echo ""
    echo "=========================================="
}

# Main execution
main() {
    log_info "Starting Keycloak setup..."
    
    wait_for_keycloak
    get_admin_token
    create_realm
    create_traefik_client
    create_vault_client
    create_user
    print_summary
    
    log_info "Setup complete!"
}

main "$@"
