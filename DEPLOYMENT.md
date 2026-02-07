# 🚀 DEPLOYMENT - KOMBIFY STACKKITS

> **Last Updated:** 2026-02-07  
> **⚠️ Production deployments are automated via GitHub Actions only!**

## Quick Reference

| Environment | URL | Container App |
|-------------|-----|---------------|
| **StackKits API** | `https://stackkits.kombify.io/api` | `ca-stackkits-prod` |
| **StackKits Website** | `https://stackkits.kombify.io` | Static (via SWA/CDN) |

---

## 🏗️ Architecture Overview

StackKits provides infrastructure templates (CUE schemas) that power kombify Stack configurations.

```
┌─────────────────────────────────────────────────────────────┐
│                     StackKits Architecture                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              CUE Schema Repository                    │  │
│  │  base/          - Core service definitions           │  │
│  │  base-homelab/  - Basic homelab configurations       │  │
│  │  dev-homelab/   - Development setups                 │  │
│  │  ha-homelab/    - High-availability configurations   │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              go-stackkits CLI                         │  │
│  │  - Validates CUE schemas                             │  │
│  │  - Generates Docker Compose / Kubernetes manifests   │  │
│  │  - Publishes to artifact repository                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 CI/CD Workflows

### Workflow Overview

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | All PRs and pushes | CUE validation, Go tests |
| `generate-cue.yml` | Push to `main` | Regenerates CUE artifacts |
| `deploy-website.yml` | Push to `main` (docs/**) | Deploys documentation site |

### CI Checks

```yaml
# ci.yml runs:
- CUE schema validation (cue vet)
- Go unit tests
- Build verification
```

---

## 🌐 Azure Resources

### Resource Group: `rg-kombify-prod`

| Resource | Name | Purpose |
|----------|------|---------|
| Container Registry | `acrkombifyprod` | Stores StackKit artifacts |
| Storage Account | `stkombifyprod` | CUE schema hosting |

### Artifact Publishing

StackKits artifacts are published to ACR as OCI artifacts:

```bash
acrkombifyprod.azurecr.io/stackkits/base-homelab:v1.0.0
acrkombifyprod.azurecr.io/stackkits/dev-homelab:v1.0.0
acrkombifyprod.azurecr.io/stackkits/ha-homelab:v1.0.0
```

---

## 🔐 Required Secrets

### GitHub Repository Secrets

```
AZURE_CREDENTIALS     # Service Principal JSON for OIDC
ACR_USERNAME          # Container Registry username
ACR_PASSWORD          # Container Registry password
```

---

## 📦 Manual Operations

### Validate CUE Schemas

```bash
# Validate all schemas
cue vet ./...

# Validate specific stack
cue vet ./base-homelab/...
```

### Generate Artifacts

```bash
# Build go-stackkits CLI
go build -o bin/stackkits ./cmd/stackkits

# Generate Docker Compose from StackKit
./bin/stackkits generate --input base-homelab --output ./artifacts/
```

### Publish StackKit

```bash
# Login to ACR
az acr login --name acrkombifyprod

# Push as OCI artifact
oras push acrkombifyprod.azurecr.io/stackkits/base-homelab:v1.0.0 \
  --artifact-type application/vnd.kombify.stackkit.v1 \
  ./base-homelab/:application/vnd.cuelang.cue
```

---

## 🧪 Local Development

### Prerequisites

```bash
# Required
go 1.22+
cue 0.6+

# Optional
docker (for testing generated manifests)
```

### Working with CUE

```bash
# Evaluate a schema
cue eval ./base-homelab/

# Export to JSON
cue export ./base-homelab/ -o base-homelab.json

# Format CUE files
cue fmt ./...
```

### Building the CLI

```bash
# Build
go build -o bin/stackkits ./cmd/stackkits

# Run tests
go test ./...

# Build with version info
go build -ldflags "-X main.version=v1.0.0" -o bin/stackkits ./cmd/stackkits
```

---

## 📐 Schema Structure

### Directory Layout

```
stackkits/
├── base/                  # Core definitions (imported by all)
│   ├── service.cue       # Base service schema
│   ├── network.cue       # Network configuration
│   └── volume.cue        # Volume definitions
├── base-homelab/         # Basic homelab
│   ├── stack.cue         # Stack definition
│   └── services/
│       ├── traefik.cue
│       └── portainer.cue
├── dev-homelab/          # Development focus
└── ha-homelab/           # High availability
```

### Adding a New StackKit

1. Create directory: `mkdir my-stackkit`
2. Define stack.cue with imports from `base/`
3. Add service definitions
4. Validate: `cue vet ./my-stackkit/...`
5. Generate: `./bin/stackkits generate --input my-stackkit`
6. Test generated output
7. PR and merge

---

## 🐛 Troubleshooting

### CUE validation errors

```bash
# Get detailed error output
cue vet -c ./base-homelab/...

# Check specific file
cue vet ./base-homelab/stack.cue
```

### Import resolution issues

Ensure `cue.mod/module.cue` exists and has correct module path:

```cue
module: "github.com/kombiverselabs/stackkits"
```

---

## 📚 Related Documentation

- [docs/SCHEMA_GUIDE.md](./docs/SCHEMA_GUIDE.md) - CUE schema development guide
- [ROADMAP.md](./ROADMAP.md) - Feature roadmap
- [ADR/](./ADR/) - Architecture Decision Records
