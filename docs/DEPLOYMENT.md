# Deployment — kombify StackKits

> **Last Updated:** 2026-01-28  
> **Version:** 1.0  
> **Component:** kombify StackKits (Infrastructure Templates)

---

## Quick Reference

| Environment | Method | Notes |
|------------|--------|-------|
| **Production Website** | Azure Container App | CI/CD from `main` → `ca-stackkits-web-prod` |
| **Local** | Docker Compose | `docker compose up -d` |
| **Binary** | Go binary | `make build` → `./bin/stackkit` |

| Property | Value |
|----------|-------|
| **Production URL** | `https://stackkits.kombify.io` |
| **Container Registry** | `acrkombifyprod.azurecr.io/stackkits-web` |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     StackKits Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              CUE Schema Repository                    │  │
│  │  base/          - Core service definitions           │  │
│  │  base-homelab/  - Single Environment Kit             │  │
│  │  ha-homelab/    - High-Availability Kit              │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              stackkit CLI (Go)                        │  │
│  │  - Validates CUE schemas                             │  │
│  │  - Generates Docker Compose / OpenTofu configs       │  │
│  │  - Publishes to artifact repository                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Platform Position

```
┌─────────────────────────────────────────────────────────────┐
│                    kombify Platform                          │
├─────────────────────────────────────────────────────────────┤
│   ┌──────────────────┐     ┌──────────────────┐             │
│   │  kombify Cloud     │     │  kombify Stack   │             │
│   │  (Portal)        │     │  (Core API)      │             │
│   └────────┬─────────┘     └────────┬─────────┘             │
│            │   Uses templates from  │                        │
│            └────────────┬───────────┘                        │
│                         ▼                                    │
│            ┌──────────────────────┐                         │
│            │     StackKits        │◀── YOU ARE HERE         │
│            │  (CUE Templates)     │                         │
│            └──────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## CI/CD Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | All PRs and pushes | CUE validation, Go tests, build |
| `release.yml` | `v*` tag push | GoReleaser cross-compilation + GitHub Release |
| `generate-cue.yml` | Push to `main` | Regenerates CUE artifacts |
| `deploy-website.yml` | Push to `main` (docs/) | Deploys documentation site |

---

## Azure Resources

### Domain Routing (Azure Front Door)

> **⚠️ IMPORTANT**: All kombify.io subdomains are routed through Azure Front Door.  
> See [AZURE_INFRASTRUCTURE.md](https://github.com/kombify/kombify-administration/blob/main/docs/AZURE_INFRASTRUCTURE.md) for the complete routing architecture.

| Property | Value |
|----------|-------|
| **Public URL** | `https://stackkits.kombify.io` |
| **AFD Profile** | `afd-kombify-prod` |
| **Origin Group** | `og-stackkits` |
| **Route Name** | `route-stackkits` |

**To update routing**, modify the AFD configuration in `rg-kombify-prod`, NOT DNS records.

### Resource Group: `rg-kombify-prod`

| Resource | Name | Purpose |
|----------|------|---------|
| Container App | `ca-stackkits-web-prod` | Documentation website |
| Container Registry | `acrkombifyprod` | Docker images + OCI artifacts |
| Storage Account | `stkombifyprod` | CUE schema hosting |

### Required GitHub Secrets

```
AZURE_CREDENTIALS     # Service Principal JSON for OIDC
ACR_USERNAME          # Container Registry username
ACR_PASSWORD          # Container Registry password
```

---

## Local Development

### Prerequisites

```bash
go 1.24+        # Required
cue 0.9+        # Required (go install cuelang.org/go/cmd/cue@latest)
make             # Required
docker           # Optional (for testing generated manifests)
```

### Build & Test

```bash
# Build CLI
make build
# → ./bin/stackkit

# Run tests
go test ./...

# Build with version info
go build -ldflags "-X main.version=v1.0.0" -o bin/stackkit ./cmd/stackkit
```

### Working with CUE

```bash
# Validate all schemas
cue vet ./...

# Validate specific stack
cue vet ./base-homelab/...

# Evaluate a schema
cue eval ./base-homelab/

# Export as YAML
cue export ./base-homelab/ --out yaml

# Format CUE files
cue fmt ./...
```

### Docker

```bash
docker compose up -d --build
curl -s http://localhost:5280/api/v1/health
```

---

## Publishing Artifacts

StackKits artifacts are published to ACR as OCI artifacts:

```bash
# Login to ACR
az acr login --name acrkombifyprod

# Push as OCI artifact
oras push acrkombifyprod.azurecr.io/stackkits/base-homelab:v1.0.0 \
  --artifact-type application/vnd.kombify.stackkit.v1 \
  ./base-homelab/:application/vnd.cuelang.cue
```

---

## Pre-Release Checklist

- [ ] All CUE schemas validate (`cue vet ./...`)
- [ ] Go tests pass (`go test ./...`)
- [ ] Documentation updated
- [ ] Version bumped in appropriate files
- [ ] CHANGELOG updated

---

## Troubleshooting

### CUE validation errors

```bash
# Get detailed error output
cue vet -c ./base-homelab/...

# Check specific file
cue vet ./base-homelab/stackfile.cue
```

### Import resolution issues

Ensure `cue.mod/module.cue` exists and has correct module path:

```cue
module: "github.com/kombihq/stackkits"
```

---

## Cross-Repository Dependencies

| Repo | Dependency Type | Notes |
|------|-----------------|-------|
| kombify Stack | Consumer | Stack loads StackKit definitions |
| docs | Documentation | Published to docs site |
| kombify Cloud | Display | Shows available templates |

---

## Related Documentation

- [Azure Website Deployment](./AZURE_WEBSITE_DEPLOYMENT.md)
- [Architecture V4](../docs/ARCHITECTURE_V4.md)
- [ROADMAP](../ROADMAP.md)
- [ADR/](./ADR/) — Architecture Decision Records
