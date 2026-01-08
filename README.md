# StackKits - Infrastructure Blueprints for KombiStack

> **Production-Ready Infrastructure Templates with CUE Validation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CUE](https://img.shields.io/badge/CUE-v0.9-blue)](https://cuelang.org/)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-v1.6-green)](https://opentofu.org/)

## 🎯 Overview

**StackKits** are infrastructure-as-code blueprints designed for homelab deployments. Each StackKit provides:

- **CUE Schemas** for configuration validation
- **OpenTofu Templates** for infrastructure provisioning
- **OS Variants** for different operating systems
- **Compute Variants** for adaptive resource allocation

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

### Using with KombiStack

StackKits are automatically loaded by KombiStack. Simply specify your intent:

```yaml
# kombination.yaml
name: my-homelab
goals:
  storage: true
  media: true
nodes:
  - name: server-1
    os: ubuntu-24
    resources:
      cpu: 4
      memory: 8
```

KombiStack will automatically:
1. Select the appropriate StackKit (`base-homelab`)
2. Apply OS variant (`ubuntu-24`)
3. Select compute tier (`standard`)
4. Generate infrastructure code

### Manual Validation

```bash
# Validate a spec against a StackKit
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

### stackfile.cue - Main Schema

```cue
package base_homelab

import "github.com/kombihq/stackkits/base"

#BaseHomelabKit: base.#BaseStackKit & {
    metadata: {
        name: "base-homelab"
    }
    nodes: [#MainNode]
    services: [#TraefikService, #DockgeService, ...]
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

- [Architecture Overview](docs/architecture.md)
- [Creating a StackKit](docs/creating-stackkits.md)
- [Variant System](docs/variants.md)
- [Template Reference](docs/templates.md)

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Part of the KombiStack ecosystem** - [kombistack.dev](https://kombistack.dev)
