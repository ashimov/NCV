# Nomad jobs

This folder contains example Nomad job specs for common services and stacks.
They are intended as starting points; adjust images, resources, volumes, and
secrets for your environment.

## Structure
- `jobs/enabled/` - curated jobs intended for automatic deployment
- `jobs/services/` - single-service jobs
- `jobs/stacks/` - multi-service stacks (example: ELK)
- `jobs/examples/` - patterns for raw_exec, Windows, and Vault templates

## Notes
- Many services require external dependencies (DB, object storage, SMTP). Add
  those and update the job specs accordingly.
- Stateful services use a `host` volume named `<service>_data` and must be
  configured on Nomad clients.
- Consul/Vault jobs require explicit `task_args`; provide production configs.
- Some services (nginx-ingress, jitsi, freeipa, gitlab-runner, kafka) require
  extra configuration beyond the defaults here.
- When using `nomad_jobs`, point `nomad_jobs_dir` at `jobs/enabled` to avoid
  deploying examples unintentionally.
- Jobs in `jobs/enabled` that talk to Consul/Nomad/Vault use mTLS by default and
  expect TLS files on the host under `/etc/consul.d/tls`, `/etc/nomad.d/tls`,
  and `/etc/vault.d/tls`. Override `*_tls_*_src` variables if your paths differ.
- The Docker job does not expose a TCP daemon by default; if you enable TCP,
  use TLS and restrict access.
- Secrets can be injected via Vault templates (see `jobs/examples/vault-template-example.hcl`).

## Run a job
```bash
nomad job run jobs/services/grafana.hcl
```

## Override variables
Each job declares variables for resources, ports, and required environment values.
Use `-var` or `-var-file` to override them:
```bash
nomad job run -var-file=jobs/examples/grafana.vars.hcl jobs/services/grafana.hcl
```

Naming conventions:
- Ports: `<port>_port` (example: `http_port`, `db_port`)
- Env vars: `env_<name>` (example: `env_postgres_password`)
- Resources: `cpu`, `memory`, `count`

Some jobs (Consul, Vault) require `task_args` to be provided via `-var` or `-var-file`.
Example files:
- `jobs/examples/consul.vars.hcl`
- `jobs/examples/vault.vars.hcl`

Production examples with config templates:
- `jobs/examples/consul-prod.hcl` + `jobs/examples/consul-prod.vars.hcl`
- `jobs/examples/vault-prod.hcl` + `jobs/examples/vault-prod.vars.hcl`
- `jobs/examples/consul-prod-tls.hcl` + `jobs/examples/consul-prod-tls.vars.hcl` (TLS via Vault templates)
- `jobs/examples/vault-prod-mesh.hcl` + `jobs/examples/vault-prod-mesh.vars.hcl` (Consul Connect sidecar)
- Config references: `jobs/examples/configs/consul.hcl`, `jobs/examples/configs/vault.hcl`

Mesh example:
- `jobs/examples/nginx-mesh.hcl` + `jobs/examples/nginx-mesh.vars.hcl`
- `jobs/examples/whoami.hcl` (upstream target for testing)
