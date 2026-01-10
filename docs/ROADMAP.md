# StackKits Roadmap

> **Version:** 1.0  
> **Last Updated:** 2026-01-10  
> **Status:** Active Development

This document outlines the development roadmap for StackKits as a standalone open-source project that can be used independently of KombiStack.

## Vision

**StackKits** aims to be the standard for declarative homelab infrastructure blueprints, combining the power of CUE validation with OpenTofu provisioning to deliver safe, reproducible deployments.

### Core Principles

1. **Standalone First:** StackKits work independently via CLI, no web UI required
2. **IaC Native:** OpenTofu as the execution engine, not custom scripts
3. **Validated by Default:** CUE schemas catch errors before deployment
4. **Community Driven:** Open registry for community-contributed StackKits

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         STACKKIT ECOSYSTEM                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │   StackKit CLI   │  │   KombiStack     │  │   CI/CD          │       │
│  │   (standalone)   │  │   (Web UI)       │  │   Integrations   │       │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘       │
│           │                     │                     │                  │
│           └──────────────┬──────┴─────────────────────┘                  │
│                          │                                               │
│                          ▼                                               │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                     STACKKIT CORE                                 │   │
│  │                                                                   │   │
│  │  CUE Schemas ──► Validation ──► OpenTofu Generation ──► Apply   │   │
│  │                                                                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                          │                                               │
│                          ▼                                               │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                     PREREQUISITES                                 │   │
│  │                                                                   │   │
│  │  Docker (24.0+)           OpenTofu (1.6+)                        │   │
│  │  └── Container Runtime    └── Infrastructure Provisioning        │   │
│  │                                                                   │   │
│  │  Optional: Terramate (0.6+) for multi-node orchestration        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation (Q1 2026)

**Goal:** Establish StackKits as a usable standalone project.

### 1.1 Core Documentation ✅

- [x] Architecture documentation
- [x] Creating StackKits guide
- [x] Variant system documentation
- [x] Template reference
- [x] CLI reference (design)
- [x] Roadmap

### 1.2 CLI Tool (MVP)

| Task | Status | Priority |
|------|--------|----------|
| CLI framework (Cobra/Go) | 🔲 Planned | P0 |
| `stackkit init` command | 🔲 Planned | P0 |
| `stackkit prepare` command | 🔲 Planned | P0 |
| `stackkit plan` command | 🔲 Planned | P0 |
| `stackkit apply` command | 🔲 Planned | P0 |
| `stackkit destroy` command | 🔲 Planned | P0 |
| `stackkit status` command | 🔲 Planned | P1 |
| `stackkit validate` command | 🔲 Planned | P1 |
| Shell completion | 🔲 Planned | P2 |

### 1.3 Prepare Command

The `stackkit prepare` command bootstraps a bare system:

```
┌─────────────────────────────────────────────────────────────┐
│                   stackkit prepare                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Detect OS (Ubuntu, Debian, Rocky, etc.)                 │
│  2. Install system packages (curl, ca-certificates, gnupg)  │
│  3. Add Docker repository                                    │
│  4. Install Docker CE + Compose plugin                      │
│  5. Add OpenTofu repository                                  │
│  6. Install OpenTofu                                         │
│  7. Configure Docker permissions                             │
│  8. Verify installations                                     │
│                                                              │
│  Result: System ready for stackkit apply                    │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 StackKit Structure Standardization

```yaml
# stackkit.yaml v1.0 specification
apiVersion: stackkit/v1
kind: StackKit
metadata:
  name: string          # required, DNS-compatible
  version: semver       # required, semantic version
  displayName: string   # required, human-readable
  description: string   # required, one-line summary
  author: string        # optional
  license: string       # required, SPDX identifier
  homepage: url         # optional
  repository: url       # optional
  tags: [string]        # optional

requirements:
  os: [string]          # supported OS variants
  resources:
    cpu: int            # minimum CPU cores
    memory: int         # minimum memory (MB)
    storage: int        # minimum storage (GB)
  network:
    ports: [int]        # required ports

modes:
  simple:
    description: string
    default: bool
  advanced:
    description: string

variants:
  <name>:
    description: string
    services: [string]
```

---

## Phase 2: Registry Integration (Q2 2026)

**Goal:** Enable community StackKit sharing and service customization.

### 2.1 StackKit Registry

Create a public registry for discovering and sharing StackKits:

```
┌─────────────────────────────────────────────────────────────┐
│                    STACKKIT REGISTRY                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Official StackKits (kombihq/*)                             │
│  ├── base-homelab                                           │
│  ├── modern-homelab                                         │
│  └── ha-homelab                                             │
│                                                              │
│  Community StackKits                                         │
│  ├── community/media-server                                 │
│  ├── community/gaming-server                                │
│  └── community/dev-environment                              │
│                                                              │
│  API: registry.stackkits.dev/v1/                            │
│  ├── GET /stackkits                                         │
│  ├── GET /stackkits/{name}                                  │
│  └── GET /stackkits/{name}/versions/{version}               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**CLI Integration:**

```bash
# List available StackKits
stackkit search homelab

# Install from registry
stackkit init registry/community/media-server

# Publish a StackKit
stackkit publish ./my-stackkit
```

### 2.2 OpenTofu Registry Integration

Leverage the OpenTofu Registry for provider discovery:

```hcl
# Auto-discovered from registry.opentofu.org
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
```

### 2.3 Service Customization

Enable service replacement via CLI:

```bash
# Replace default photo service with alternative
stackkit apply --replace immich=ente

# Or via configuration
# kombination.yaml
services:
  photos:
    provider: ente  # instead of default immich
    # ente-specific config follows
```

**Implementation:**

```cue
// Service alternatives definition
#PhotoService: #Immich | #Ente | #PhotoPrism

#Immich: base.#ServiceDefinition & {
    name: "immich"
    image: "ghcr.io/immich-app/immich-server"
    // ...
}

#Ente: base.#ServiceDefinition & {
    name: "ente"
    image: "ghcr.io/ente-io/photos"
    // ...
}
```

---

## Phase 3: Existing System Support (Q3 2026)

**Goal:** Enable StackKit deployment on systems with existing services.

### 3.1 System Analysis

```bash
# Analyze existing system
stackkit analyze

# Output:
# Detected Services:
#   ✓ Docker (24.0.7)
#   ✓ Traefik (v2.10) - port 80, 443
#   ⚠ Portainer (2.19) - port 9443 (conflicts with StackKit)
#
# Recommendations:
#   1. Migrate Portainer to StackKit-managed
#   2. Or exclude Portainer from StackKit
```

### 3.2 Adoption Modes

```yaml
# kombination.yaml
adoption:
  mode: coexist  # or: migrate, takeover
  
  # Coexist: StackKit manages new services only
  # Migrate: Gradually move existing services
  # Takeover: Full StackKit management
  
  existing:
    traefik:
      action: adopt   # Bring under StackKit management
      preserve:
        config: true  # Keep existing configuration
        certs: true   # Keep existing certificates
    
    portainer:
      action: exclude # Leave as-is, avoid conflicts
    
    custom-app:
      action: import  # Import as StackKit service
      image: myapp:latest
      ports: [8080]
```

### 3.3 State Import

```bash
# Import existing Docker containers
stackkit import --from docker

# Import from docker-compose
stackkit import --from compose ./docker-compose.yml

# Preview import
stackkit import --dry-run --from docker
```

---

## Phase 4: Advanced Features (Q4 2026)

### 4.1 Multi-Node Support

```yaml
# kombination.yaml
stackkit: modern-homelab

nodes:
  - name: primary
    role: control-plane
    ip: 192.168.1.100
    services:
      - traefik
      - dokploy
  
  - name: worker-1
    role: worker
    ip: 192.168.1.101
    services:
      - jellyfin
      - sonarr
```

### 4.2 Backup & Restore

```bash
# Backup all StackKit data
stackkit backup --output ./backup-2026-01-10.tar.gz

# Restore from backup
stackkit restore ./backup-2026-01-10.tar.gz

# Scheduled backups
stackkit backup --schedule "0 2 * * *" --s3 s3://my-bucket/
```

### 4.3 Secrets Management

```yaml
# kombination.yaml
secrets:
  provider: vault  # or: file, doppler, 1password
  vault:
    address: https://vault.example.com
    path: secret/homelab

services:
  database:
    environment:
      DB_PASSWORD: "secret://database/password"
```

### 4.4 Health Monitoring

```bash
# Continuous health monitoring
stackkit watch --interval 30s

# Alerting
stackkit watch --alert-webhook https://ntfy.sh/my-topic
```

---

## Phase 5: Ecosystem (2027)

### 5.1 Add-on Marketplace

```
addons/
├── monitoring/          # Prometheus + Grafana
├── vpn-overlay/         # Tailscale/WireGuard
├── backup-restic/       # Automated backups
├── dns-adguard/         # Ad blocking
├── auth-authelia/       # SSO/2FA
└── storage-minio/       # S3-compatible storage
```

### 5.2 IDE Integration

- VS Code extension for StackKit development
- CUE syntax highlighting and validation
- OpenTofu plan preview

### 5.3 CI/CD Templates

```yaml
# .github/workflows/stackkit.yml
name: Deploy StackKit
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: kombihq/stackkit-action@v1
        with:
          command: apply
          auto-approve: true
```

---

## Compatibility Matrix

### Operating Systems

| OS | Version | Status | Notes |
|----|---------|--------|-------|
| Ubuntu | 24.04 LTS | ✅ Recommended | Full support |
| Ubuntu | 22.04 LTS | ✅ Supported | Full support |
| Debian | 12 | ✅ Supported | Full support |
| Debian | 11 | ⚠️ Legacy | Security updates only |
| Rocky Linux | 9 | 🔲 Planned | Q2 2026 |
| Fedora | 40+ | 🔲 Planned | Q3 2026 |

### Prerequisites

| Tool | Minimum Version | Notes |
|------|-----------------|-------|
| Docker | 24.0 | Required |
| OpenTofu | 1.6 | Required |
| Terramate | 0.6 | Optional (advanced mode) |
| CUE | 0.9 | Optional (development) |

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### Priority Areas

1. **Documentation:** Improve guides and examples
2. **StackKits:** Create new StackKits for common use cases
3. **Variants:** Add support for additional operating systems
4. **CLI:** Help build the `stackkit` command-line tool
5. **Testing:** Improve test coverage

### Development Setup

```bash
# Clone repository
git clone https://github.com/kombihq/stackkits.git
cd stackkits

# Install CUE
go install cuelang.org/go/cmd/cue@latest

# Validate schemas
cue vet ./...

# Run tests
cd tests/cue && cue vet ./...
```

---

## Changelog

### v2.0.0 (2026-01-10)
- Complete documentation overhaul
- CLI design specification
- Registry integration planning
- Existing system support design

### v1.0.0 (2025-12-01)
- Initial StackKit structure
- Base homelab StackKit
- CUE schema definitions
- OpenTofu templates

---

## Contact

- **GitHub:** [github.com/kombihq/stackkits](https://github.com/kombihq/stackkits)
- **Discord:** [discord.gg/kombistack](https://discord.gg/kombistack)
- **Website:** [stackkits.dev](https://stackkits.dev)
