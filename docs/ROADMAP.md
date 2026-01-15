# StackKits Roadmap

> **Version:** 2.0  
> **Last Updated:** 2026-01-15  
> **Status:** Active Development  
> **Key Decision:** [ADR-001: Docker-First Strategy](./ADR-001-DOCKER-FIRST-V1.md)

This document outlines the development roadmap for StackKits as a standalone open-source project that can be used independently of KombiStack.

---

## 🎯 v1.0 Strategy: Docker-First

**All StackKits in v1.0 use the same technology stack:**

| Component | Default | Alternatives (Config-Level) |
|-----------|---------|----------------------------|
| **OS** | Ubuntu 24.04 LTS | Debian 12, Ubuntu 22.04 |
| **Container Runtime** | Docker 27.x | — |
| **Multi-Node** | Docker Swarm | — |
| **PaaS** | Dokploy | Coolify (variant) |
| **Reverse Proxy** | Traefik v3 | Caddy (variant) |
| **Monitoring** | Uptime Kuma | Beszel (variant) |

### v1.0 StackKit Matrix

| StackKit | Nodes | Orchestration | Use Case |
|----------|-------|---------------|----------|
| `base-homelab` | 1 | Standalone | Single server, beginners |
| `modern-homelab` | 2-5 | Docker Swarm | Hybrid (local + cloud) |
| `ha-homelab` | 3+ | Docker Swarm HA | Production-like HA |

### v1.1+ Planned: Kubernetes Support

Kubernetes will be added as **new, separate StackKits** (not modifications to existing):

| Future StackKit | Platform | Use Case |
|-----------------|----------|----------|
| `k3s-homelab` | k3s | Single-node Kubernetes learning |
| `k8s-cluster` | k3s HA | Multi-node Kubernetes cluster |

> **Rationale:** See [ADR-001](./ADR-001-DOCKER-FIRST-V1.md) for full decision record.

---

## 🧹 Recent Cleanup (2025-01)

### Repository Cleanup Completed

| Item | Action | Status |
|------|--------|--------|
| Duplicate `stackkits/` directory | Removed (was outdated) | ✅ |
| `desprecated_web/` folder | Removed (deprecated) | ✅ |
| `.old` backup files | Removed from modern-homelab | ✅ |
| CUE validation | All packages passing | ✅ |
| Documentation | Updated to reflect current structure | ✅ |

### StackKits Now Available

| StackKit | Status | Deployment Modes |
|----------|--------|-----------------|
| **base-homelab** | ✅ Complete | simple (OpenTofu), advanced (Terramate) |
| **modern-homelab** | ✅ Schema Complete | simple, advanced |
| **ha-homelab** | ✅ Schema Complete | simple, advanced |

---

## 📊 Sprint Overview & Work Packages

### Current Sprint: S1-2026 (Jan 6 - Jan 19, 2026)

| ID | Work Package | Status | Owner | Est. |
|----|--------------|--------|-------|------|
| WP-001 | CLI Framework Setup (Go/Cobra) | ✅ Complete | Core | 3d |
| WP-002 | Core Commands (init, prepare, plan, apply) | ✅ Complete | Core | 5d |
| WP-003 | CUE Validation Integration | ✅ Complete | Core | 2d |
| WP-004 | Test Suite Foundation | ✅ Complete | QA | 3d |

### Sprint Backlog

#### S2-2026 (Jan 20 - Feb 2, 2026)
| ID | Work Package | Priority | Est. |
|----|--------------|----------|------|
| WP-005 | Service Template Engine | P0 | 4d |
| WP-006 | OpenTofu Execution Wrapper | ✅ Complete | 3d |
| WP-007 | SSH Remote Execution | ✅ Complete | 3d |
| WP-008 | Integration Tests | 🟡 Partial | 3d |
| **WP-TD1** | **Fix Critical Security Issues** | **P0** | **2d** | ✅ Complete |

#### S3-2026 (Feb 3 - Feb 16, 2026)
| ID | Work Package | Priority | Est. |
|----|--------------|----------|------|
| WP-009 | Status & Health Monitoring | ✅ Complete | 3d |
| WP-010 | Shell Completion | ✅ Complete (built-in) | 1d |
| WP-011 | E2E Test Coverage | P1 | 4d |
| WP-012 | Documentation & Examples | P1 | 2d |
| **WP-TD2** | **Increase Test Coverage >60%** | **P1** | **3d** |

#### S4-2026 (Feb 17 - Mar 2, 2026) - NEW
| ID | Work Package | Priority | Est. |
|----|--------------|----------|------|
| **WP-013** | **Terramate Integration for Day 2 Ops** | **✅ Complete** | **3d** |
| **WP-014** | **Unified IaC Executor (Dual-Mode)** | **✅ Complete** | **2d** |
| **WP-015** | **Drift Detection Support** | **✅ Complete** | **2d** |
| WP-016 | Multi-Node Stack Orchestration | P1 | 3d |

#### S5-2026 (Mar 3 - Mar 16, 2026) - ARCHITECTURE ALIGNMENT SPRINT
> **See:** [ADR-001: Docker-First Strategy](./ADR-001-DOCKER-FIRST-V1.md)

| ID | Work Package | Priority | Est. |
|----|--------------|----------|------|
| **WP-017** | **Update ha-homelab to Docker Swarm** | **P0** | **2d** |
| **WP-018** | **Update modern-homelab to Dokploy** | **P0** | **1d** |
| **WP-019** | **Add Docker Swarm templates** | **P0** | **3d** |
| **WP-020** | **Document Kubernetes as v1.1+ roadmap** | **P1** | **1d** |
| **WP-021** | **Integration tests for all 3 StackKits** | **P1** | **3d** |

**Sprint S5 Goals:**
- Unify all StackKits on Docker + Dokploy platform
- Add Docker Swarm support for multi-node scenarios
- Remove Kubernetes dependencies from existing StackKits
- Update all documentation to reflect v1.0 scope

**Acceptance Criteria:**
- [ ] All 3 StackKits use Docker platform layer
- [ ] ha-homelab deploys with Docker Swarm HA (not k3s)
- [ ] modern-homelab uses Dokploy instead of Coolify
- [ ] Kubernetes documented as "Planned v1.1+ - separate StackKits"
- [ ] `stackkit apply` works for all 3 StackKits

### Work Package Dependencies

```
WP-001 ──┬──► WP-002 ──┬──► WP-005 ──► WP-009
         │             │
         └──► WP-003 ──┴──► WP-006 ──► WP-007
                            │
WP-004 ────────────────────┴──► WP-008 ──► WP-011
```

### Milestone Summary

| Milestone | Target Date | Key Deliverables | Status |
|-----------|-------------|------------------|--------|
| **M1: CLI MVP** | Jan 31, 2026 | Working CLI with init/prepare/apply | ✅ Complete |
| **M1.5: Docker-First Alignment** | Mar 16, 2026 | All StackKits on Docker + Dokploy | 🟢 Active |
| **M2: Registry Integration** | Apr 30, 2026 | Public registry, `stackkit search` | 🔲 Planned |
| **M3: Existing Systems** | Jun 30, 2026 | Import, analyze, coexist modes | 🔲 Planned |
| **M4: Multi-Node HA** | Sep 30, 2026 | Docker Swarm HA for all StackKits | 🔲 Planned |
| **M5: Kubernetes Support** | Q1 2027 | New k3s-homelab, k8s-cluster StackKits | 🔲 Planned |
| **M6: Ecosystem** | Q2 2027 | Add-on marketplace, IDE extensions | 🔲 Planned |

### Definition of Done (DoD)

- [ ] Unit tests with >80% coverage
- [ ] Integration tests for critical paths
- [ ] Documentation updated
- [ ] Code reviewed and approved
- [ ] No critical/high linter warnings
- [ ] Works on Ubuntu 22.04/24.04, Debian 12

---

## 🔧 Technical Debt & Issues

> **Last Reviewed:** 2026-01-15  
> **Current Test Coverage:** config (84.9%), cue (63.1%), docker (38.5%), ssh (25.2%), template (82.1%), tofu (42.1%), iac (75.0%), terramate (68.0%), validation (78.0%)

### Critical Security Issues

| ID | Package | Issue | Impact | Status |
|----|---------|-------|--------|--------|
| TD-001 | ssh | Insecure SSH Host Key Verification (`InsecureIgnoreHostKey`) | MITM attacks possible | ✅ Fixed |
| TD-002 | ssh | Command Injection via unescaped `remotePath` | Remote code execution | ✅ Fixed |
| TD-003 | docker | No Input Sanitization for container/network names | Command injection | ✅ Fixed |

### High Priority Issues

| ID | Package | Issue | Recommendation | Status |
|----|---------|-------|----------------|--------|
| TD-004 | ssh | Low Test Coverage (20.8%) | Add SSH mock tests, integration tests | 🟢 Improved (25.2%) |
| TD-005 | docker | Low Test Coverage (37.5%) | Add Docker client mocks | 🟢 Improved (38.5%) |
| TD-006 | tofu | Low Test Coverage (35.3%) | Mock binary execution tests | 🟢 Improved (42.1%) |
| TD-007 | config | Path Traversal Vulnerability | Validate paths stay within basePath | ✅ Fixed |
| TD-008 | template | Deprecated `strings.Title` | Use golang.org/x/text cases | 🟠 Open |
| TD-009 | commands | No Context Timeout for Remote Ops | Add configurable timeouts | 🟢 Improved |
| TD-010 | config | Windows Path Handling (`$HOME` empty) | Use `os.UserHomeDir()` | ✅ Fixed |

### Medium Priority Issues

| ID | Package | Issue | Status |
|----|---------|-------|--------|
| TD-011 | template | Simplified toYaml/toJson (incorrect output) | ✅ Fixed |
| TD-012 | cue | Missing Schema Directory Validation | 🟡 Open |
| TD-013 | commands | Error handling ignores SaveDeploymentState errors | 🟡 Open |
| TD-014 | commands | Race Condition in Concurrent Deployments | 🟡 Open |
| TD-015 | docker | Timeout Not Configurable (hardcoded 30s) | 🟢 Improved |
| TD-016 | tofu | Plan Output Parsing Fragile | 🟡 Open |
| TD-017 | ssh | No Connection Pooling | 🟡 Open |
| TD-018 | commands | Interactive Mode Not Implemented | 🟡 Open |
| TD-019 | validate | OpenTofu Validation Not Actually Run | 🟡 Open |
| TD-020 | commands | Missing --dry-run for Apply/Destroy | 🟡 Open |
| TD-021 | ssh | ReadFile Uses Unescaped Path | ✅ Fixed |

### Cross-Platform Compatibility

| ID | Package | Issue | Platforms Affected | Status |
|----|---------|-------|-------------------|--------|
| TD-022 | ssh | Unix Socket Path for Docker | Windows | 🟡 Open |
| TD-023 | prepare | installDockerRemote Unix-Only | Windows, macOS | 🟡 Open |
| TD-024 | ssh | Shell Commands Assume Bash | BSD, Alpine | 🟡 Open |
| TD-025 | config | Path Separator Handling | Windows | ✅ Fixed |

### Missing Features (Technical Debt)

| ID | Feature | Priority | Status |
|----|---------|----------|--------|
| TD-026 | Rollback Capability | P1 | 🔲 Not Started |
| TD-027 | Lock File Support (.stackkit.lock) | P1 | 🔲 Not Started |
| TD-028 | Config File Support (.stackkitrc) | P2 | 🔲 Not Started |
| TD-029 | Structured Logging System | P2 | 🔲 Not Started |
| TD-030 | JSON Output for Status Command | P2 | 🔲 Not Started |

### NEW: Day 2 Operations Support

| ID | Feature | Priority | Status |
|----|---------|----------|--------|
| TD-031 | Terramate Integration | P0 | ✅ Complete |
| TD-032 | Drift Detection | P0 | ✅ Complete |
| TD-033 | Unified IaC Executor | P0 | ✅ Complete |
| TD-034 | Dual-Mode Support (OpenTofu / Terramate) | P0 | ✅ Complete |

### Work Package: Technical Debt Sprint (Proposed)

| ID | Task | Priority | Est. | Status |
|----|------|----------|------|--------|
| WP-TD1 | Fix Critical Security Issues (TD-001 to TD-003) | P0 | 2d | ✅ Complete |
| WP-TD2 | Increase Test Coverage to >60% | P1 | 3d | 🟢 In Progress |
| WP-TD3 | Fix Cross-Platform Issues | P1 | 2d | 🟡 Partial |
| WP-TD4 | Add Proper Error Handling | P2 | 1d | 🟢 In Progress |
| **WP-TD5** | **Day 2 Operations (Terramate, Drift)** | **P0** | **3d** | **✅ Complete** |

---

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
│  │                     IaC EXECUTION LAYER (NEW)                     │   │
│  │                                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────┐     │   │
│  │  │              Unified IaC Executor                        │     │   │
│  │  │                                                          │     │   │
│  │  │   Mode: "simple"/"advanced"  ──►  OpenTofu Executor     │     │   │
│  │  │   Mode: "terramate"          ──►  Terramate Executor    │     │   │
│  │  │                                                          │     │   │
│  │  │   Features: Plan, Apply, Destroy, Drift Detection       │     │   │
│  │  └─────────────────────────────────────────────────────────┘     │   │
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
│  │  Optional: Terramate (0.6+) for Day 2 Operations:               │   │
│  │            - Multi-stack orchestration                           │   │
│  │            - Drift detection                                     │   │
│  │            - Change management across stacks                     │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Dual-Mode IaC Architecture (NEW)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DUAL-MODE IAC EXECUTION                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Day 1 Path (Default - OpenTofu Only):                                  │
│  ─────────────────────────────────────                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐             │
│  │  Spec    │──►│  Plan    │──►│  Apply   │──►│  Deploy  │             │
│  │  YAML    │   │  (tofu)  │   │  (tofu)  │   │  State   │             │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘             │
│                                                                          │
│  Day 1 + Day 2 Path (Terramate + OpenTofu):                             │
│  ──────────────────────────────────────────                             │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐             │
│  │  Spec    │──►│  Generate│──►│ Terramate│──►│  Deploy  │             │
│  │  YAML    │   │  Stacks  │   │   Run    │   │  State   │             │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘             │
│                                     │                                    │
│                                     ▼                                    │
│                              ┌──────────────┐                           │
│                              │    Drift     │                           │
│                              │  Detection   │                           │
│                              └──────────────┘                           │
│                                                                          │
│  internal/iac/executor.go:                                              │
│  - NewExecutor(mode)        - Creates appropriate executor              │
│  - NewExecutorFromSpec(spec)- Auto-selects based on spec.Mode          │
│                                                                          │
│  internal/terramate/executor.go:                                        │
│  - DetectDrift()            - Detects infrastructure drift              │
│  - ListChanged()            - Lists stacks with pending changes         │
│  - RunApply()               - Applies changes across stacks             │
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
| CLI framework (Cobra/Go) | ✅ Complete | P0 |
| `stackkit init` command | ✅ Complete | P0 |
| `stackkit prepare` command | ✅ Complete | P0 |
| `stackkit plan` command | ✅ Complete | P0 |
| `stackkit apply` command | ✅ Complete | P0 |
| `stackkit destroy` command | ✅ Complete | P0 |
| `stackkit status` command | ✅ Complete | P1 |
| `stackkit validate` command | ✅ Complete | P1 |
| Shell completion | ✅ Built-in (Cobra) | P2 |

#### Implementation Notes (2026-01-11)

- **Framework:** Go 1.22 with Cobra CLI v1.8.1
- **Build:** `go build -o stackkit ./cmd/stackkit`
- **Location:** `cmd/stackkit/` (entry point), `cmd/stackkit/commands/` (subcommands)
- **Packages:**
  - `pkg/models` - Core data structures
  - `internal/config` - Configuration loading (84.9% coverage)
  - `internal/cue` - CUE validation (63.1% coverage)
  - `internal/tofu` - OpenTofu execution (35.3% coverage)
  - `internal/template` - Template rendering (82.1% coverage)
  - `internal/docker` - Docker client (28.9% coverage)
  - `internal/ssh` - SSH remote execution (19.0% coverage)

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
