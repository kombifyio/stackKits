# kombify StackKits (StackKits) - Guided Infrastructure Blueprints

> **Pre-validated infrastructure blueprints with guided UI setup, CUE validation, and OpenTofu execution under the hood**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![CUE](https://img.shields.io/badge/CUE-v0.9-blue)](https://cuelang.org/)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-v1.6-green)](https://opentofu.org/)

## 🎯 Overview

**StackKits** are declarative infrastructure blueprints for homelab and self-hosted deployments. They combine the power of **CUE** for validation with **OpenTofu** for provisioning, delivering safe and reproducible infrastructure.

### Key Features

- **Validated Configuration** - CUE schemas catch errors before deployment
- **Professional Engine Under the Hood** - OpenTofu as execution engine, CUE for validation -- users interact through UI or CLI
- **Multi-OS Support** - Ubuntu, Debian, and more via variants
- **Standalone or Integrated** - Use via CLI or with kombify Stack Web UI

### Prerequisites

| Tool         | Version | Purpose                     |
| ------------ | ------- | --------------------------- |
| **Docker**   | 24.0+   | Container runtime           |
| **OpenTofu** | 1.6+    | Infrastructure provisioning |

Optional: Terramate (0.6+) for multi-node orchestration, CUE (0.9+) for development

## 📦 Available StackKits

StackKits are **architecture patterns**, not node-count definitions.

| StackKit | Pattern | Core Idea | Status |
| --- | --- | --- | --- |
| **Base Kit** | Single environment | All services in one deployment target — local or cloud VPS. | ✅ Available |
| **Modern Homelab Kit** | Hybrid infrastructure | Bridges local + cloud. Zero-trust access via identity stack. | 🚧 Schema Only |
| **High Availability Kit** | HA cluster | Redundancy, failover, quorum. Cluster-first architecture. | 🚧 Schema Only |

### Node-Context (Auto-Detected)

Each node is classified into a **Context** based on hardware and provider metadata:

| Context | Detection | Characteristics |
| --- | --- | --- |
| **local** | Physical hardware, no cloud metadata | Full control, local network |
| **cloud** | Cloud provider metadata detected | Public IP, egress costs |
| **pi** | ARM + low memory or RPi detection | Resource-constrained |

### Add-Ons (Composable Extensions)

Add-Ons replace the old monolithic variant system. They are stackable and compatible:

| Add-On | Category | Description |
| --- | --- | --- |
| `monitoring` | Observability | Prometheus + Grafana + Alertmanager |
| `backup` | Data | Restic + configurable targets |
| `vpn-overlay` | Networking | Optional Headscale/Tailscale mesh |
| `gpu-workloads` | Compute | NVIDIA/AMD GPU passthrough |
| `media` | Applications | Jellyfin + *arr stack |
| `smart-home` | IoT | Home Assistant + MQTT |

### Progressive Capability Model

| Level | Name | Access Method |
| --- | --- | --- |
| **Level 0** | Standalone CLI | `stackkit` CLI directly |
| **Level 1** | Control Plane | kombify Stack Web UI / API |
| **Level 2** | Worker Agent | kombify Stack + gRPC Agent |
| **Level 3** | Runtime Intelligence | Day-2 monitoring + auto-remediation |
| **Level 4** | AI-Assisted (SaaS) | kombify Sphere |

## 🏗️ 3-Layer Architecture

StackKits uses a strict **3-layer architecture** for maximum reusability:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: STACKKITS (stackkits/)                            │
│  Use-case specific configurations with services             │
│  • base-homelab: Single-environment Docker + Dokploy        │
│  • modern-homelab: Hybrid Docker + identity stack            │
│  • ha-homelab: Docker Swarm HA cluster                       │
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: PLATFORMS (platforms/)                            │
│  Container orchestration layer                              │
│  • docker/: Docker + Traefik + Swarm                        │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: CORE (base/)                                      │
│  Shared foundation applied to ALL deployments               │
│  • Bootstrap, Security, Network, Observability              │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
StackKits/
├── base/                       # Layer 1: CORE (Shared)
│   ├── stackkit.cue
│   └── ...
├── base-homelab/               # Base Kit
├── modern-homelab/             # Modern Homelab Kit
├── ha-homelab/                 # High Availability Kit
│
├── docs/                       # Canonical project docs
│   └── ADR/                    # Architectural Decision Records
├── tests/                      # Testing
├── cmd/                        # CLI Source
├── internal/                   # Internal Packages
│
└── docs/README.md              # Documentation index
```

## 🚀 Quick Start

### Development/Testing with VM (Recommended for Local Dev)

Deploy the **dev-homelab** StackKit inside an Ubuntu VM for isolated testing:

```bash
# 1) Start ONLY the VM (no services on host)
docker compose up -d vm

# 2) Deploy all services INSIDE the VM via StackKit CLI
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli \
  ./stackkit init dev-homelab --non-interactive
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli \
  ./stackkit apply --auto-approve

# 3) Verify: Services are IN the VM, not on host
docker ps                           # Host: should show ONLY 'stackkits-vm'
docker compose exec vm docker ps    # VM: should show ALL services
```

**Or use the automated deployment script:**
```bash
./deploy-to-vm.sh
```

**First Login:**
- **TinyAuth**: http://auth.stack.local → `admin` / `admin123`
- **Dokploy**: http://dokploy.stack.local (via TinyAuth SSO)

See [dev-homelab/README.md](dev-homelab/README.md) for complete documentation.

### CLI-Only (Standalone)

**Recommended workflow for production deployments:**

```bash
mkdir my-homelab
cd my-homelab

# 1) Create a spec
stackkit init base-homelab

# 2) Check prerequisites + validate spec
stackkit prepare

# 3) Generate OpenTofu files into ./deploy
stackkit generate

# 4) Preview and apply
stackkit plan
stackkit apply
```

See [docs/CLI.md](docs/CLI.md) for the full command reference.

### Using with kombify Stack

StackKits are automatically loaded by kombify Stack. Simply specify your intent:

```yaml
# kombination.yaml (User Intent - created via UI Wizard)
name: my-homelab
kit: base-homelab

nodes:
  - name: server-1
    type: main
    provider: local
    ssh:
      host: 192.168.1.100
      user: admin

services:
  - name: traefik
    type: reverse-proxy
```

kombify Stack will automatically:

1. Validate via Unifier Pipeline
2. Resolve StackKit pattern (`base` / `modern` / `ha`)
3. Auto-detect Node-Context (local / cloud / pi)
4. Apply matching Add-Ons
5. Generate IaC files and provision via OpenTofu

### Manual Validation (Development)

```bash
# Validate spec against StackKit schema
cue vet ./base-homelab/... my-spec.cue

# Export resolved configuration
cue export ./base-homelab/... -e resolvedSpec
```

## 📋 StackKit Specification

Each StackKit contains:

### stackkit.yaml - Metadata

```yaml
apiVersion: stackkit/v1
kind: StackKit
metadata:
  name: base-homelab
  version: "1.0.0"
  description: "Single-environment homelab"
  pattern: base       # Architecture pattern
```

### stackfile.cue - Main Schema

```cue
package base_homelab

import "github.com/kombihq/stackkits/base"

#BaseHomelabKit: base.#BaseStackKit & {
    metadata: {
        name: "base-homelab"
    }
    nodes: [#MainNode]
    services: { traefik: #TraefikService, dokploy: #DokployService, ... }
}
```

### addons/ - Composable Extensions

```cue
// addons/monitoring/addon.cue
#MonitoringAddOn: #AddOn & {
    metadata: {
        name: "monitoring"
        category: "observability"
    }
    compatible_stackkits: ["base", "modern", "ha"]
    services: { prometheus: ..., grafana: ..., alertmanager: ... }
}
```

## 🧪 Testing

```bash
# Run CUE validation tests
cd tests/cue && cue vet ./...

# Run integration tests (requires kombify Sim)
make test-integration
```

## 📖 Documentation

### Getting Started

- [Documentation index](docs/README.md) — Canonical project docs ⭐

### Core Concepts

- [Architecture v4](docs/ARCHITECTURE_V4.md) — Three-concept model, Progressive Capability, Add-Ons
- [Target State](docs/TARGET_STATE.md) — Product vision
- [Roadmap](docs/ROADMAP.md) — M0–M9 milestones, timeline, dependencies
- [Technical Debt](TECHNICAL_DEBT.md) — Known issues and debt register
- [Evaluation Report](docs/EVALUATION_REPORT_2026-02-07.md) — Comprehensive code review

## 🔧 Architecture

```
┌───────────────────────────────────────────────────────────┐
│  User Intent (kombination.yaml)                           │
│  StackKit: base | modern | ha                             │
│  Context: local | cloud | pi  (auto-detected)            │
│  Add-Ons: monitoring, backup, vpn-overlay, ...            │
└───────────────────────┬───────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────┐
│  CUE Validation + Resolution                             │
│  StackKit × Context → Smart Defaults                     │
│  + Add-On merging → Resolved Configuration               │
└───────────────────────┬───────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────┐
│  IaC Generation (OpenTofu + Terramate)                   │
│  • HCL templates  • Docker Compose  • Bootstrap scripts  │
└───────────────────────┬───────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────┐
│  Execution (Level 0: CLI | Level 2+: Agent)              │
│  • Docker containers  • Networks  • Volumes              │
└───────────────────────────────────────────────────────────┘
```

## 🤝 Contributing

We welcome contributions! Priority areas:

1. **Add-Ons** - Create composable extensions for common use cases
2. **Context modules** - Improve hardware-aware defaults
3. **StackKits** - Implement modern-homelab and ha-homelab patterns
4. **Documentation** - Improve guides and examples
5. **CLI** - Add-On management commands

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

Apache-2.0 — see [LICENSE](LICENSE) for details.

---

**StackKits** works standalone (Level 0) or as part of the [kombify](https://kombify.io) ecosystem (Levels 1–4).
