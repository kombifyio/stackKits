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

| Tool | Version | Purpose |
|------|---------|---------|
| **Docker** | 24.0+ | Container runtime |
| **OpenTofu** | 1.6+ | Infrastructure provisioning |

Optional: Terramate (0.6+) for multi-node orchestration, CUE (0.9+) for development

## 📦 Available StackKits

| StackKit | Description | Nodes | Cloud | Status |
|----------|-------------|-------|-------|--------|
| **base-homelab** | Single server, local only | 1 | ❌ | ✅ Available |
| **modern-homelab** | Local + Cloud hybrid | 2 | ✅ | 🚧 Planned |
| **ha-homelab** | Multi-cloud high availability | 3+ | ✅ | 🚧 Planned |

## 🏗️ Repository Structure

```
StackKits/
├── base/                   # Shared CUE schemas
│   ├── stackkit.cue        # Base definitions
│   ├── system.cue          # System configuration
│   ├── network.cue         # Network configuration
│   ├── security.cue        # Security policies
│   └── observability.cue   # Monitoring & logging
│
├── base-homelab/           # Single-server StackKit
│   ├── stackkit.yaml       # Metadata
│   ├── stackfile.cue       # Main schema
│   ├── default-spec.yaml   # CLI-ready template (⭐ START HERE)
│   ├── services.cue        # Service definitions
│   ├── defaults.cue        # Smart defaults
│   ├── templates/          # OpenTofu templates
│   └── variants/           # OS/Compute variants
│   ├── services.cue        # Service definitions
│   ├── defaults.cue        # Smart defaults
│   ├── variants/           # OS & compute variants
│   └── templates/          # OpenTofu templates
│
├── addons/                 # Optional add-ons
│   ├── monitoring/
│   ├── vpn-overlay/
│   └── backup-restic/
│
└── tests/                  # Validation tests
    └── cue/
```

## 🚀 Quick Start

### CLI-Only (Standalone)

**Start with a ready-to-use template:**

```bash
# 1. Copy default spec
cd StackKits
cp base-homelab/default-spec.yaml ~/my-homelab-spec.yaml

# 2. Edit configuration (IPs, SSH, Secrets)
nano ~/my-homelab-spec.yaml

# 3. Validate
stackkit validate ~/my-homelab-spec.yaml

# 4. Deploy
stackkit apply ~/my-homelab-spec.yaml
```

See [DEFAULT_SPECS_README.md](./DEFAULT_SPECS_README.md) for detailed customization guide.

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
    ip: 192.168.1.100  # ⚠️ ANPASSEN
    ssh:
      user: admin      # ⚠️ ANPASSEN

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
- **[Default Specs Guide](DEFAULT_SPECS_README.md)** - CLI templates for base/ha/modern-homelab ⭐
- **[stack-spec.yaml Reference](docs/stack-spec-reference.md)** - Standardized spec format
- [CLI Reference](docs/cli-reference.md) - Command-line tool (planned)

### Core Concepts
- [Architecture Overview](docs/architecture.md) - System design, IaC-first principles, layer architecture
- [Creating a StackKit](docs/creating-stackkits.md) - Build custom StackKits step-by-step
- [Variant System](docs/variants.md) - OS variants (Ubuntu, Debian) and compute tiers
- [Template Reference](docs/templates.md) - OpenTofu template patterns and best practices

### Operations
- [CLI Reference](docs/cli-reference.md) - Command-line usage (planned)
- [Existing Systems](docs/existing-systems.md) - Adopt StackKits on running systems

### Ecosystem
- [Registry Integration](docs/registry-integration.md) - Provider and StackKit registries
- [Roadmap](docs/ROADMAP.md) - Development roadmap and future plans

### Internal
- [Architecture Plan](docs/ARCHITECTURE_PLAN.md) - Detailed technical architecture
- [IaC-First Architecture](docs/IAC_FIRST_ARCHITECTURE.md) - Why IaC-first, not agent-first

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
