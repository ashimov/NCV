# Traefik Production Variables
# Usage: nomad job run -var-file=traefik.vars.hcl traefik.hcl

datacenters = ["dc1"]

# Resources
cpu    = 1000
memory = 1024

# Image
image = "traefik:v3.0"

# Network
web_port       = 80
websecure_port = 443
dashboard_port = 8080

# Consul Integration
consul_address = "127.0.0.1:8501"  # Use HTTPS port if TLS enabled
consul_tls     = true

# Dashboard Authentication
# Generate password hash with: htpasswd -nb admin yourpassword
# Then escape $ with $$: echo $(htpasswd -nb admin password) | sed -e s/\\$/\\$\\$/g
dashboard_user     = "admin"
dashboard_password = "admin:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/"  # default: admin/changeme

# Domain for dashboard and default routing
domain = "ashimov.com"

# Let's Encrypt (leave empty to disable ACME)
acme_email = ""  # e.g., "admin@ashimov.com" for production certs
