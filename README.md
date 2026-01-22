# StackKits - Declarative Infrastructure Blueprints

> **IaC-First Infrastructure Templates with CUE Validation and OpenTofu Execution**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CUE](https://img.shields.io/badge/CUE-v0.9-blue)](https://cuelang.org/)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-v1.6-green)](https://opentofu.org/)

## 🎯 Overview

**StackKits** are declarative infrastructure blueprints for homelab and self-hosted deployments. They combine the power of **CUE** for validation with **OpenTofu** for provisioning, delivering safe and reproducible infrastructure.

### Key Features

- **Validated Configuration** - CUE schemas catch errors before deployment
- **IaC-First Architecture** - OpenTofu as execution engine, not custom scripts
- **Multi-OS Support** - Ubuntu, Debian, and more via variants
- **Standalone or Integrated** - Use via CLI or with KombiStack Web UI

### Prerequisites

| Tool         | Version | Purpose                     |
| ------------ | ------- | --------------------------- |
| **Docker**   | 24.0+   | Container runtime           |
| **OpenTofu** | 1.6+    | Infrastructure provisioning |

Optional: Terramate (0.6+) for multi-node orchestration, CUE (0.9+) for development

## 📦 Available StackKits

| StackKit           | Description                 | Nodes | Deployment Modes | Status         |
| ------------------ | --------------------------- | ----- | ---------------- | -------------- |
| **base-homelab**   | Single server, local only   | 1     | simple, advanced | ✅ Available   |
| **modern-homelab** | Multi-node Docker + Dokploy | 2+    | simple, advanced | 🚧 Schema Only |
| **ha-homelab**     | Docker Swarm HA Cluster     | 3+    | simple, advanced | 🚧 Schema Only |

### Deployment Modes

- **Simple Mode:** OpenTofu Day-1 provisioning (init → plan → apply)
- **Advanced Mode:** OpenTofu + Terramate Day-1 & Day-2 (drift detection, change sets, rolling updates)

## 🏗️ 3-Layer Architecture

StackKits uses a strict **3-layer architecture** for maximum reusability:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: STACKKITS (stackkits/)                            │
│  Use-case specific configurations with services             │
│  • base-homelab: Single-node Docker + Dokploy               │
│  • modern-homelab: Multi-node Docker + Dokploy              │
│  • ha-homelab: Docker Swarm HA (3+ Nodes)                   │
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
├── base-homelab/               # Layer 2: STACKKIT (Base)
├── modern-homelab/             # Layer 2: STACKKIT (Modern)
├── ha-homelab/                 # Layer 2: STACKKIT (HA)
│
├── ADR/                        # Architectural Decisions
├── docs/                       # Canonical project docs
├── tests/                      # Testing
├── cmd/                        # CLI Source
├── internal/                   # Internal Packages
│
└── docs/README.md              # Documentation index
```

## 🚀 Quick Start

### CLI-Only (Standalone)

**Recommended workflow (matches current CLI implementation):**

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

### Using with KombiStack

StackKits are automatically loaded by KombiStack. Simply specify your intent:

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

KombiStack will automatically:

1. Validate via Unifier Pipeline
2. Resolve StackKit (`base-homelab`)
3. Apply OS variant (auto-detect)
4. Generate `stack-spec.yaml` (standardized)
5. Provision via OpenTofu

**Important:** KombiStack uses a two-file system:

- `kombination.yaml` - User intent (from UI)
- `stack-spec.yaml` - Unifier output (StackKit input)

See [Spec-File Separation](../KombiStack/docs/architecture/spec-file-separation.md) for details.

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
  description: "Single-server homelab"
modes:
  simple:
    description: "Single OpenTofu file"
  advanced:
    description: "Terramate-orchestrated"
```

### default-spec.yaml - CLI Template

Ready-to-use deployment template (see [DEFAULT_SPECS_README.md](./DEFAULT_SPECS_README.md)):

```yaml
version: "1.0"
stack:
  name: my-homelab
  kit: base-homelab
  variant: os/ubuntu-24

nodes:
  - name: homelab-server
    ip: 192.168.1.100 # ⚠️ ANPASSEN
    ssh:
      user: admin # ⚠️ ANPASSEN

services:
  - name: traefik
    type: reverse-proxy
  - name: dokploy
    type: deployment-platform
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
    services: [#TraefikService, #DokployService, ...]
}
```

### variants/ - OS & Compute Variants

```cue
// variants/os/ubuntu-24.cue
#Ubuntu24Variant: {
    os: {
        distribution: "ubuntu"
        version: "24.04"
    }
    packages: { ... }
}
```

## 🧪 Testing

```bash
# Run CUE validation tests
cd tests/cue && cue vet ./...

# Run integration tests (requires KombiSim)
make test-integration
```

## 📖 Documentation

### Getting Started

- [Documentation index](docs/README.md) - Canonical project docs ⭐
- [Cleanup methodology](docs/cleanup/README.md) - Reusable cleanup process (project-agnostic)

### Core Concepts

- [Architecture](docs/ARCHITECTURE.md) - System design, IaC-first principles, layer architecture
- [Target State](docs/TARGET_STATE.md) - Product vision
- [Roadmap](docs/ROADMAP.md) - Milestones + backlog

## 🔧 Architecture

```
┌─────────────────────────────────────────────────────────┐
│  User Config (kombination.yaml)                         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  CUE Validation Layer                                    │
│  • Schema validation  • Type checking  • Defaults       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  OpenTofu Generation                                     │
│  • HCL templates  • Provider configuration               │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  Execution (tofu init → plan → apply)                   │
│  • Docker containers  • Networks  • Volumes             │
└─────────────────────────────────────────────────────────┘
```

## 🤝 Contributing

We welcome contributions! Priority areas:

1. **Documentation** - Improve guides and examples
2. **StackKits** - Create new StackKits for common use cases
3. **Variants** - Add support for additional operating systems
4. **CLI** - Help build the `stackkit` command-line tool

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**StackKits** works standalone or as part of the [KombiStack](https://kombistack.dev) ecosystem.
