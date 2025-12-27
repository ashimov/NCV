# Traefik Ingress Controller for Nomad

Production-ready Traefik ingress controller with:
- ✅ Consul Catalog integration for automatic service discovery
- ✅ Automatic routing via service tags
- ✅ HTTPS/TLS with Let's Encrypt support
- ✅ Secure dashboard with basic auth
- ✅ Prometheus metrics
- ✅ Access logs
- ✅ System job (runs on all clients)
- ✅ Host network mode for better performance
- ✅ Auto HTTP→HTTPS redirect
- ✅ Health checks and auto-restart

## Prerequisites

1. **Nomad clients must be enabled** on nodes
2. **Consul** running with catalog enabled
3. **Port forwarding** configured for 80/443 if behind firewall

## Quick Start

### 1. Enable Nomad Clients

If your servers don't have client mode enabled:

```yaml
# inventories/NomadCluster/group_vars/nomad_servers.yml
nomad_client_enabled: true
```

Redeploy:
```bash
ansible-playbook -i inventories/NomadCluster/hosts.yml site.yml --tags nomad
```

### 2. Configure Variables

Edit `traefik.vars.hcl`:

```hcl
# Consul integration
consul_address = "127.0.0.1:8501"  # Use HTTPS port
consul_tls     = true

# Dashboard domain and auth
domain             = "ashimov.com"
dashboard_user     = "admin"
dashboard_password = "admin:$$apr1$$..."  # Generate with htpasswd

# Let's Encrypt (optional)
acme_email = "admin@ashimov.com"
```

### 3. Generate Dashboard Password

```bash
# Install htpasswd (if needed)
# Ubuntu/Debian: apt-get install apache2-utils
# RHEL/CentOS: yum install httpd-tools
# macOS: brew install httpd

# Generate password (escape $ with $$)
htpasswd -nb admin yourpassword | sed -e 's/\$/\$\$/g'

# Copy output to dashboard_password in traefik.vars.hcl
```

### 4. Deploy

```bash
nomad job run -var-file=jobs/services/traefik.vars.hcl jobs/services/traefik.hcl
```

### 5. Verify

```bash
# Check job status
nomad job status traefik

# Check service in Consul
consul catalog services | grep traefik

# Access dashboard
curl http://localhost:8080/ping
```

## Service Integration

### Auto-Discovery with Tags

Any Consul service can be exposed through Traefik by adding tags:

```hcl
service {
  name = "my-app"
  port = "http"
  
  tags = [
    "traefik.enable=true",
    "traefik.http.routers.myapp.rule=Host(`myapp.ashimov.com`)",
    "traefik.http.routers.myapp.entrypoints=websecure",
    "traefik.http.routers.myapp.tls=true",
    "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
  ]
}
```

### Common Routing Patterns

**Host-based routing:**
```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.app.rule=Host(`app.example.com`)"
]
```

**Path-based routing:**
```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.api.rule=Host(`example.com`) && PathPrefix(`/api`)"
]
```

**Multiple domains:**
```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.web.rule=Host(`example.com`) || Host(`www.example.com`)"
]
```

**With middleware (auth, ratelimit, etc):**
```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.admin.rule=Host(`admin.example.com`)",
  "traefik.http.routers.admin.middlewares=auth@file",
  "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."
]
```

## Configuration

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `datacenters` | `["dc1"]` | Nomad datacenters |
| `cpu` | `1000` | CPU allocation (MHz) |
| `memory` | `1024` | Memory allocation (MB) |
| `image` | `traefik:v3.0` | Docker image |
| `web_port` | `80` | HTTP port |
| `websecure_port` | `443` | HTTPS port |
| `dashboard_port` | `8080` | Dashboard/API port |
| `consul_address` | `127.0.0.1:8500` | Consul agent address |
| `consul_tls` | `true` | Use HTTPS for Consul |
| `dashboard_user` | `admin` | Dashboard username |
| `dashboard_password` | `changeme` | Dashboard htpasswd hash |
| `acme_email` | `""` | Email for Let's Encrypt |
| `domain` | `traefik.local` | Base domain |

### Consul TLS Integration

If Consul TLS is enabled, Traefik will:
- Connect via HTTPS to Consul catalog
- Use `insecureSkipVerify` by default (suitable for internal CA)
- Optionally load CA cert from Consul KV: `traefik/consul/ca`

Store Consul CA in KV:
```bash
consul kv put traefik/consul/ca @/etc/consul.d/tls/ca.pem
```

## Monitoring

### Prometheus Metrics

Metrics available at `http://<node>:8080/metrics`:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'traefik'
    consul_sd_configs:
      - server: '127.0.0.1:8500'
        services: ['traefik']
    relabel_configs:
      - source_labels: [__meta_consul_service]
        target_label: job
```

### Access Logs

Logs written to `/var/log/traefik/access.log` inside container:

```bash
# View logs
nomad alloc logs -f <alloc-id> traefik

# Or exec into container
nomad alloc exec <alloc-id> cat /var/log/traefik/access.log
```

## Troubleshooting

### Dashboard Not Accessible

```bash
# Check Traefik is running
nomad job status traefik

# Check port bindings
nomad alloc status <alloc-id>

# Check logs
nomad alloc logs <alloc-id> traefik

# Test health
curl http://localhost:8080/ping
```

### Services Not Discovered

```bash
# Verify Consul connection
nomad alloc exec <alloc-id> wget -O- http://127.0.0.1:8500/v1/catalog/services

# Check Traefik logs for Consul provider
nomad alloc logs <alloc-id> traefik | grep -i consul

# Verify service tags in Consul
consul catalog services -tags
```

### Certificate Issues

```bash
# Check ACME storage
nomad alloc exec <alloc-id> cat /data/acme.json

# Verify Let's Encrypt challenges
nomad alloc logs <alloc-id> traefik | grep -i acme

# Test HTTP challenge endpoint
curl http://example.com/.well-known/acme-challenge/test
```

### High Memory Usage

Traefik memory usage grows with number of services/routes. Adjust:

```hcl
memory = 2048  # Increase if needed
```

## Security Considerations

1. **Dashboard Auth**: Change default password immediately
2. **ACME Email**: Use valid email for Let's Encrypt notifications
3. **TLS**: Enable HTTPS for all production services
4. **Firewall**: Restrict dashboard port (8080) to internal network
5. **Secrets**: Store sensitive data in Vault or Consul KV

## Advanced Features

### Custom Middleware

Create dynamic config in Consul KV:

```bash
consul kv put traefik/config/middleware.yml @middleware.yml
```

```yaml
# middleware.yml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100
        burst: 50
    security-headers:
      headers:
        sslRedirect: true
        stsSeconds: 31536000
        contentTypeNosniff: true
```

### Multiple Entrypoints

Add custom entrypoints:

```hcl
"--entrypoints.grpc.address=:9000",
"--entrypoints.grpc.http2.maxConcurrentStreams=250"
```

### Load Balancing Strategies

Configure via service tags:

```hcl
tags = [
  "traefik.http.services.myapp.loadbalancer.sticky.cookie=true",
  "traefik.http.services.myapp.loadbalancer.healthcheck.path=/health"
]
```

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Consul Catalog Provider](https://doc.traefik.io/traefik/providers/consul-catalog/)
- [Traefik & Nomad Guide](https://developer.hashicorp.com/nomad/tutorials/load-balancing/load-balancing-traefik)
- [Let's Encrypt](https://letsencrypt.org/docs/)
