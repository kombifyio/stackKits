# StackKits 3-Layer Architecture

> **Version:** 1.0  
> **Last Updated:** 2026-01-11  
> **Status:** Approved & Implemented

---

## Executive Summary

StackKits uses a **strict 3-layer architecture** where:
- **Layer 1 (CORE)**: Shared OS-level configuration applied to ALL deployments
- **Layer 2 (PLATFORM)**: Container orchestration layer (Docker vs Kubernetes)
- **Layer 3 (STACKKIT)**: Specific use-case configurations with services and variants

This architecture ensures:
- ✅ Clear separation of concerns
- ✅ Reusable components across StackKits
- ✅ Consistent security and hardening
- ✅ Easy maintenance and updates

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        3-LAYER ARCHITECTURE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ LAYER 3: STACKKITS (Use-Case Specific)                                 │ │
│  │ ──────────────────────────────────────                                 │ │
│  │                                                                        │ │
│  │  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                  │ │
│  │  │ base-       │   │ modern-     │   │ ha-         │                  │ │
│  │  │ homelab     │   │ homelab     │   │ homelab     │                  │ │
│  │  │             │   │             │   │             │                  │ │
│  │  │ • 1 Node    │   │ • 2-5 Nodes │   │ • 3+ Nodes  │                  │ │
│  │  │ • Dokploy   │   │ • Swarm     │   │ • k3s HA    │                  │ │
│  │  │ • Variants  │   │ • Variants  │   │ • GitOps    │                  │ │
│  │  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘                  │ │
│  │         │                 │                 │                          │ │
│  └─────────┼─────────────────┼─────────────────┼──────────────────────────┘ │
│            │                 │                 │                            │
│            └────────┬────────┴─────────────────┘                            │
│                     │ extends                                               │
│                     ▼                                                       │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ LAYER 2: PLATFORMS (Container Orchestration)                           │ │
│  │ ─────────────────────────────────────────────                          │ │
│  │                                                                        │ │
│  │  ┌─────────────────────────────┐   ┌─────────────────────────────┐    │ │
│  │  │ DOCKER PLATFORM             │   │ KUBERNETES PLATFORM         │    │ │
│  │  │                             │   │                             │    │ │
│  │  │ • Docker Engine             │   │ • k3s Installation          │    │ │
│  │  │ • Docker Compose            │   │ • CNI (Flannel/Cilium)      │    │ │
│  │  │ • Traefik (Docker)          │   │ • Ingress Controller        │    │ │
│  │  │ • Docker Networks           │   │ • MetalLB/kube-vip          │    │ │
│  │  │ • Volume Management         │   │ • Persistent Volumes        │    │ │
│  │  │                             │   │                             │    │ │
│  │  │ Used by:                    │   │ Used by:                    │    │ │
│  │  │ • base-homelab              │   │ • ha-homelab                │    │ │
│  │  │ • modern-homelab            │   │                             │    │ │
│  │  └──────────────┬──────────────┘   └──────────────┬──────────────┘    │ │
│  │                 │                                 │                    │ │
│  └─────────────────┼─────────────────────────────────┼────────────────────┘ │
│                    │                                 │                      │
│                    └────────────┬────────────────────┘                      │
│                                 │ extends                                   │
│                                 ▼                                           │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │ LAYER 1: CORE (Shared Foundation)                                      │ │
│  │ ─────────────────────────────────                                      │ │
│  │                                                                        │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │ Bootstrap    │ │ Security     │ │ Network      │ │ Observability│  │ │
│  │  │              │ │              │ │              │ │              │  │ │
│  │  │ • System     │ │ • UFW        │ │ • DNS        │ │ • Logging    │  │ │
│  │  │   Update     │ │ • SSH        │ │ • Firewall   │ │ • Health     │  │ │
│  │  │ • Base       │ │   Hardening  │ │   Ports      │ │   Checks     │  │ │
│  │  │   Packages   │ │ • Fail2ban   │ │ • TLS Modes  │ │ • Metrics    │  │ │
│  │  │ • Users      │ │ • Secrets    │ │              │ │ • Backup     │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  │                                                                        │ │
│  │  Applied to: ALL deployments, regardless of StackKit                  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### Layer 1: CORE (`base/`)

**Purpose:** Everything that applies to EVERY homelab deployment.

**Components:**
| Directory | Purpose | Templates |
|-----------|---------|-----------|
| `base/bootstrap/` | System preparation | `_bootstrap.tf.tmpl` |
| `base/security/` | SSH, Firewall, Fail2ban | `_security.tf.tmpl` |
| `base/network/` | Network modes (local/public/hybrid) | `_local.tf.tmpl`, `_public.tf.tmpl` |
| `base/observability/` | Logging, metrics, health | `_health.tf.tmpl` |
| `base/lifecycle/` | Drift detection, backups | `_drift.tf.tmpl` |
| `base/schema/` | CUE schemas for validation | `*.cue` |

**What CORE Provides:**
```yaml
# Always applied, regardless of StackKit:
- System update and base packages
- User creation (admin user with SSH key)
- UFW firewall (deny all, allow SSH/HTTP/HTTPS)
- SSH hardening (no password auth, no root login)
- Base directories (/opt/kombistack/*)
- Health check framework
- Logging configuration
```

**CUE Schema (base/stackkit.cue):**
```cue
#BaseStackKit: {
    metadata: #StackKitMetadata
    system:   #SystemConfig      // Users, hostname, timezone
    security: #SecurityConfig    // SSH, firewall, fail2ban
    network:  #NetworkConfig     // Mode, TLS, DNS
    ...
}
```

---

### Layer 2: PLATFORMS (`platforms/`)

**Purpose:** Container orchestration layer. Each platform defines HOW containers/workloads are deployed.

**Available Platforms:**

| Platform | Description | Used By |
|----------|-------------|---------|
| `platforms/docker/` | Docker + Compose | base-homelab, modern-homelab |
| `platforms/kubernetes/` | k3s HA cluster | ha-homelab |

**Docker Platform Provides:**
```yaml
# platforms/docker/
- Docker Engine installation
- Docker Compose plugin
- Docker networks (bridge, overlay)
- Traefik as reverse proxy (Docker labels)
- Volume management
- Container health checks
```

**Kubernetes Platform Provides:**
```yaml
# platforms/kubernetes/
- k3s installation
- Control plane setup (1 or 3 masters)
- CNI (Flannel by default, Cilium optional)
- Ingress controller (Traefik/Nginx)
- MetalLB for LoadBalancer services
- Storage class (local-path / Longhorn)
```

---

### Layer 3: STACKKITS (`stackkits/`)

**Purpose:** Specific use-case configurations with services and variants.

**Available StackKits:**

| StackKit | Nodes | Platform | Use Case |
|----------|-------|----------|----------|
| `base-homelab` | 1 | Docker | Single server, beginners |
| `modern-homelab` | 2-5 | Docker | Multi-node Docker |
| `ha-homelab` | 3+ | Kubernetes | Production-grade HA |

**StackKit Structure:**
```
stackkits/base-homelab/
├── stackkit.yaml          # Metadata, requirements
├── stackfile.cue          # CUE schema (extends base)
├── defaults.cue           # Default values
├── services.cue           # Available services
├── variants/              # Pre-configured service sets
│   ├── default.cue        # Dokploy + Uptime Kuma
│   ├── beszel.cue         # Dokploy + Beszel
│   └── minimal.cue        # Dockge + Portainer
└── templates/             # OpenTofu templates
    ├── simple/            # OpenTofu-only mode
    └── advanced/          # Terramate + OpenTofu
```

**What StackKits Define:**
```yaml
# StackKit-specific:
- Which services to deploy (Traefik, Dokploy, monitoring)
- Service configurations
- Variants (pre-configured service combinations)
- Compute tiers (minimal, standard, performance)
- StackKit-specific networking
```

---

## Composition Flow

### How Layers Compose

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        COMPOSITION FLOW                                   │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  USER INPUT:                                                             │
│  ───────────                                                             │
│  stack-spec.yaml                                                         │
│  ├── name: "my-homelab"                                                 │
│  ├── stackkit: "base-homelab"                                           │
│  ├── variant: "default"                                                 │
│  └── network:                                                           │
│      └── mode: "local"                                                  │
│                                                                          │
│              │                                                           │
│              ▼                                                           │
│                                                                          │
│  STACKKIT CLI:                                                           │
│  ─────────────                                                           │
│  1. Load stack-spec.yaml                                                │
│  2. Find StackKit (base-homelab)                                        │
│  3. Validate against CUE schemas                                        │
│  4. Determine platform (Docker)                                         │
│  5. Compose templates:                                                  │
│                                                                          │
│     ┌─────────────────────────────────────────────────────────────┐     │
│     │ GENERATED TERRAFORM                                          │     │
│     ├─────────────────────────────────────────────────────────────┤     │
│     │                                                              │     │
│     │ # From CORE (Layer 1)                                       │     │
│     │ ├── bootstrap.tf      # System prep, packages              │     │
│     │ ├── security.tf       # UFW, SSH hardening                 │     │
│     │ ├── network.tf        # Network mode (local)               │     │
│     │ └── health.tf         # Health check framework             │     │
│     │                                                              │     │
│     │ # From PLATFORM (Layer 2)                                   │     │
│     │ ├── docker.tf         # Docker installation                │     │
│     │ ├── traefik.tf        # Reverse proxy                      │     │
│     │ └── networks.tf       # Docker networks                    │     │
│     │                                                              │     │
│     │ # From STACKKIT (Layer 3)                                   │     │
│     │ ├── services.tf       # Dokploy, monitoring                │     │
│     │ ├── outputs.tf        # Service URLs                       │     │
│     │ └── variables.tf      # Configuration                      │     │
│     │                                                              │     │
│     └─────────────────────────────────────────────────────────────┘     │
│                                                                          │
│  6. Run: tofu init → tofu plan → tofu apply                            │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

### CUE Schema Composition

```cue
// base/stackkit.cue - Layer 1
#BaseStackKit: {
    metadata: #StackKitMetadata
    system:   #SystemConfig
    security: #SecurityConfig
    network:  #NetworkConfig
    // ... base definitions
}

// platforms/docker/platform.cue - Layer 2
#DockerPlatform: {
    runtime: "docker"
    compose: #ComposeConfig
    networks: [...#DockerNetwork]
    reverseProxy: #TraefikConfig
}

// stackkits/base-homelab/stackfile.cue - Layer 3
import "github.com/kombihq/stackkits/base"
import "github.com/kombihq/stackkits/platforms/docker"

#BaseHomelabKit: base.#BaseStackKit & docker.#DockerPlatform & {
    // StackKit-specific overrides
    metadata: {
        name: "base-homelab"
        // ...
    }
    services: [...#ServiceDefinition]
    variants: [...#Variant]
}
```

---

## Directory Structure

```
StackKits/
│
├── base/                          # LAYER 1: CORE
│   ├── stackkit.cue              # Base CUE schema
│   ├── system.cue                # System configuration schema
│   ├── security.cue              # Security schema
│   ├── network.cue               # Network schema
│   ├── observability.cue         # Observability schema
│   │
│   ├── bootstrap/                # OS preparation templates
│   │   ├── _bootstrap.tf.tmpl    # System update, packages
│   │   ├── _users.tf.tmpl        # User creation
│   │   └── _variables.tf.tmpl    # Bootstrap variables
│   │
│   ├── security/                 # Security templates
│   │   ├── _firewall.tf.tmpl     # UFW configuration
│   │   ├── _ssh.tf.tmpl          # SSH hardening
│   │   └── _fail2ban.tf.tmpl     # Brute-force protection
│   │
│   ├── network/                  # Network mode templates
│   │   ├── _local.tf.tmpl        # Local mode (IP-based)
│   │   ├── _public.tf.tmpl       # Public mode (domain + ACME)
│   │   └── _hybrid.tf.tmpl       # Hybrid mode
│   │
│   ├── observability/            # Health & monitoring
│   │   ├── _health.tf.tmpl       # Health checks
│   │   └── _logging.tf.tmpl      # Log configuration
│   │
│   └── lifecycle/                # Day-2 operations
│       ├── _drift.tf.tmpl        # Drift detection
│       └── _backup.tf.tmpl       # Backup configuration
│
├── platforms/                     # LAYER 2: PLATFORMS
│   │
│   ├── docker/                   # Docker platform
│   │   ├── platform.cue          # Docker CUE schema
│   │   ├── _docker.tf.tmpl       # Docker installation
│   │   ├── _networks.tf.tmpl     # Docker networks
│   │   ├── _traefik.tf.tmpl      # Traefik reverse proxy
│   │   └── _compose.tf.tmpl      # Compose deployment
│   │
│   └── kubernetes/               # Kubernetes platform
│       ├── platform.cue          # K8s CUE schema
│       ├── _k3s.tf.tmpl          # k3s installation
│       ├── _ingress.tf.tmpl      # Ingress controller
│       └── _storage.tf.tmpl      # Storage class
│
├── stackkits/                     # LAYER 3: USE-CASE STACKKITS
│   │
│   ├── base-homelab/             # Single-node Docker
│   │   ├── stackkit.yaml         # Metadata
│   │   ├── stackfile.cue         # Schema (extends base + docker)
│   │   ├── services.cue          # Service definitions
│   │   ├── variants/             # Variant configurations
│   │   └── templates/            # StackKit-specific templates
│   │
│   ├── modern-homelab/           # Multi-node Docker
│   │   └── ...
│   │
│   └── ha-homelab/               # Kubernetes HA
│       └── ...
│
├── cmd/stackkit/                  # CLI Entry Point
│   └── commands/                  # CLI Commands
│
├── internal/                      # Go Implementation
│   ├── config/                   # Configuration loading
│   ├── cue/                      # CUE validation
│   ├── template/                 # Template rendering
│   ├── composer/                 # Layer composition (NEW)
│   └── tofu/                     # OpenTofu execution
│
└── pkg/models/                    # Data structures
```

---

## Network Modes

### Local Mode (Default)

```yaml
network:
  mode: local
  
# Results in:
# - Services accessed via IP: https://192.168.1.100
# - Self-signed TLS certificates
# - No DNS required
# - No external access
```

### Public Mode

```yaml
network:
  mode: public
  domain: homelab.example.com
  tls:
    mode: acme
    email: admin@example.com
    
# Results in:
# - Services accessed via domain: https://dokploy.homelab.example.com
# - Let's Encrypt certificates
# - DNS records required
# - External access enabled
```

### Hybrid Mode

```yaml
network:
  mode: hybrid
  localIP: 192.168.1.100
  domain: homelab.example.com  # Optional
  
# Results in:
# - Services accessible via both IP and domain
# - Flexible TLS configuration
```

---

## Service URL Generation

### Local Mode URLs
```
https://192.168.1.100:443/           → Traefik Dashboard
https://192.168.1.100:3000/          → Dokploy
https://192.168.1.100:3001/          → Uptime Kuma
```

### Public Mode URLs
```
https://traefik.homelab.example.com  → Traefik Dashboard
https://dokploy.homelab.example.com  → Dokploy
https://status.homelab.example.com   → Uptime Kuma
```

---

## Validation Pipeline

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VALIDATION PIPELINE                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Phase 1: Schema Validation (CUE)                                       │
│  ────────────────────────────────                                       │
│  ├── Validate stack-spec.yaml against UnifiedSpec schema               │
│  ├── Check required fields (name, stackkit)                            │
│  ├── Validate network mode                                              │
│  └── Validate compute tier                                              │
│                                                                          │
│  Phase 2: StackKit Resolution                                           │
│  ───────────────────────────                                            │
│  ├── Find StackKit (local or registry)                                 │
│  ├── Load stackkit.yaml                                                │
│  ├── Resolve variant                                                    │
│  └── Check requirements (OS, resources)                                │
│                                                                          │
│  Phase 3: Layer Composition                                             │
│  ──────────────────────────                                             │
│  ├── Load CORE templates                                               │
│  ├── Load PLATFORM templates (docker/kubernetes)                       │
│  ├── Load STACKKIT templates                                           │
│  └── Render all templates with spec values                             │
│                                                                          │
│  Phase 4: Pre-Flight Checks                                             │
│  ──────────────────────────                                             │
│  ├── SSH connectivity                                                   │
│  ├── Target OS detection                                               │
│  ├── Available disk space                                              │
│  ├── Port availability                                                 │
│  └── Docker/K8s status                                                 │
│                                                                          │
│  Phase 5: Terraform Validation                                          │
│  ────────────────────────────                                           │
│  ├── tofu validate                                                     │
│  ├── Check provider requirements                                       │
│  └── Dependency resolution                                             │
│                                                                          │
│  Phase 6: Plan Review                                                   │
│  ────────────────────                                                   │
│  ├── tofu plan                                                         │
│  ├── Show resources to be created                                      │
│  └── User confirmation                                                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Usage Examples

### Basic Usage (Local Mode)

```bash
# Create stack spec
cat > stack-spec.yaml <<EOF
name: my-homelab
stackkit: base-homelab
variant: default

nodes:
  - name: server
    ip: 192.168.1.100
    role: standalone

ssh:
  user: root
  keyPath: ~/.ssh/id_ed25519
EOF

# Initialize and deploy
stackkit init
stackkit validate
stackkit plan
stackkit apply
```

### Public Mode with Domain

```bash
cat > stack-spec.yaml <<EOF
name: my-homelab
stackkit: base-homelab
variant: beszel

network:
  mode: public
  domain: homelab.example.com
  
tls:
  email: admin@example.com

nodes:
  - name: server
    ip: 1.2.3.4
    role: standalone
EOF

stackkit apply
```

---

## Migration Notes

### From Previous Architecture

If you have existing deployments with the old structure:

1. **CUE schemas remain compatible** - base-homelab already imports from base/
2. **Templates need reorganization** - Move platform-specific templates to platforms/
3. **CLI handles composition** - No changes needed to stack-spec.yaml

### Breaking Changes

- Template paths changed (e.g., `base/bootstrap/` → same, but explicitly CORE)
- New `platforms/` directory for Layer 2
- StackKits must explicitly declare their platform

---

## Summary

| Layer | Location | Purpose | Examples |
|-------|----------|---------|----------|
| **1: CORE** | `base/` | Shared OS-level foundation | Bootstrap, UFW, SSH, Health |
| **2: PLATFORM** | `platforms/` | Container orchestration | Docker, Kubernetes |
| **3: STACKKIT** | `stackkits/` | Use-case configurations | base-homelab, ha-homelab |

This architecture ensures:
- ✅ **Consistency**: All homelabs get the same security baseline
- ✅ **Flexibility**: Platforms and services are exchangeable
- ✅ **Maintainability**: Changes in CORE apply everywhere
- ✅ **Scalability**: Easy to add new platforms and StackKits
