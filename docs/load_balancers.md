# Load balancers

This repository provides a load balancer plan file to help you implement NLB/ELB/GLB in your cloud tooling.

## Generate a plan
Enable the role and run the playbook:
```yaml
load_balancer_enabled: true
load_balancer_provider: aws
```

The plan is written to `docs/lb-plans/` and includes listener/target mapping for Consul, Nomad, and Vault.

## AWS patterns
- Use NLB for TCP pass-through on 8500/8502/4646/4647/8200/8201
- Terminate TLS at services or add ALB for HTTP termination
- Health checks should target HTTPS endpoints where TLS is enabled

## GCP patterns
- Use TCP/SSL load balancer with backend service per target group
- Create health checks per service (Consul HTTP, Nomad HTTP, Vault HTTP)
- Limit source ranges and enable logging
