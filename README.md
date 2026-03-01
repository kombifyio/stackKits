# StackKits

Declarative infrastructure blueprints for homelabs. Define your stack in CUE, generate deployment artifacts, apply to a fresh server — fully automated, zero manual steps.

## What is a StackKit?

A StackKit is a complete infrastructure composition defined entirely in [CUE](https://cuelang.org/). It describes services, networking, security, and deployment configuration. The `stackkit` CLI reads your CUE definitions and stack specification, generates OpenTofu files, and deploys everything to your server.

```
Edit .cue files → stackkit generate → stackkit apply → Done.
```

## Base Kit

The included **Base Kit** (`base-kit`) provides a single-node homelab deployment with:

| Service | Purpose |
|---------|---------|
| **Traefik** | Reverse proxy with automatic HTTPS |
| **Dokploy** | PaaS platform for app deployment |
| **Uptime Kuma** | Monitoring & status pages |
| **Dozzle** | Real-time container log viewer |
| **Whoami** | Proxy verification test service |

### Variants

| Variant | Description |
|---------|-------------|
| `default` | Dokploy PaaS + Uptime Kuma monitoring |
| `beszel` | Dokploy PaaS + Beszel server metrics |
| `minimal` | Dockge + Portainer + Netdata (traditional compose management) |

### Deployment Modes

| Mode | Engine | Use Case |
|------|--------|----------|
| `simple` | OpenTofu | Single-node, quick setup |
| `advanced` | Terramate | Drift detection, multi-stack orchestration |

## Requirements

- **Go 1.24+** (to build the CLI)
- **OpenTofu 1.6+** (deployment engine)
- **CUE** (optional, for schema validation)
- **Target server**: Ubuntu 22/24 or Debian 12 with SSH access

### Minimum Resources

| | CPU | RAM | Disk |
|---|---|---|---|
| **Minimum** | 2 cores | 4 GB | 50 GB |
| **Recommended** | 4 cores | 8 GB | 100 GB |

## Quick Start

### 1. Build the CLI

```bash
git clone https://github.com/kombihq/stackkits.git
cd stackkits
make build
# Binary at: ./build/stackkit
```

Or install directly:

```bash
go install github.com/kombihq/stackkits/cmd/stackkit@latest
```

### 2. Initialize a Stack

```bash
mkdir my-homelab && cd my-homelab

stackkit init base-kit
# Creates stack-spec.yaml
```

### 3. Configure

Edit `stack-spec.yaml`:

```yaml
name: my-homelab
stackkit: base-kit
variant: default
mode: simple
domain: homelab.example.com
network:
  mode: local
  subnet: 172.20.0.0/16
compute:
  tier: standard
ssh:
  user: root
  port: 22
```

### 4. Generate & Deploy

```bash
# Validate CUE schemas
stackkit validate

# Generate OpenTofu files
stackkit generate

# Preview changes
stackkit plan

# Deploy to server
stackkit apply --auto-approve
```

All services are accessible via `<service>.<domain>` (e.g., `traefik.homelab.example.com`).

## Project Structure

```
stackkits/
├── base/                    # Core CUE schemas (shared by all kits)
│   ├── stackkit.cue         # Base types: #ServiceDefinition, #NodeDefinition, etc.
│   ├── layers.cue           # 3-layer model: Foundation, Platform, Applications
│   ├── network.cue          # Network, DNS, proxy configuration
│   ├── security.cue         # SSH, firewall, TLS, secrets, RBAC
│   ├── identity.cue         # LLDAP, Step-CA, identity providers
│   ├── observability.cue    # Logging, metrics, health checks, backups
│   ├── context.cue          # Node contexts (local/cloud/pi)
│   └── generated/           # Generated schema registries
│
├── base-kit/            # Base Kit definition
│   ├── stackfile.cue        # Main stack schema
│   ├── services.cue         # Service definitions
│   ├── defaults.cue         # Smart defaults & compute tier detection
│   ├── stackkit.yaml        # Kit metadata, variants, modes
│   ├── default-spec.yaml    # Example stack specification
│   └── templates/           # OpenTofu templates (simple & advanced)
│
├── platforms/docker/        # Docker platform CUE definitions
├── cmd/stackkit/            # CLI source (Go + Cobra)
├── internal/                # Go packages (config, CUE bridge, SSH, etc.)
├── pkg/models/              # Shared data models
├── docs/                    # Documentation & ADRs
└── tests/                   # Validation & integration tests
```

## Architecture

StackKits uses a 3-layer architecture:

- **L1 Foundation**: System packages, SSH hardening, firewall, container runtime
- **L2 Platform**: Traefik reverse proxy, PaaS (Dokploy/Coolify), Docker networking
- **L3 Applications**: User services deployed via the PaaS platform

All layers are defined in CUE and deployed atomically via `stackkit apply`.

## CLI Commands

| Command | Description |
|---------|-------------|
| `stackkit init <kit>` | Create a new stack-spec.yaml |
| `stackkit validate` | Validate CUE schemas and spec |
| `stackkit generate` | Generate OpenTofu files from spec |
| `stackkit plan` | Preview infrastructure changes |
| `stackkit apply` | Deploy infrastructure |
| `stackkit destroy` | Tear down infrastructure |
| `stackkit status` | Show deployment status |
| `stackkit version` | Show CLI version |

See [docs/CLI.md](docs/CLI.md) for full reference.

## Documentation

- [Architecture (v4)](docs/ARCHITECTURE_V4.md) — design concepts and layer model
- [CLI Reference](docs/CLI.md) — all commands and flags
- [Creating StackKits](docs/creating-stackkits.md) — guide for building new kits
- [Deployment Guide](docs/DEPLOYMENT.md) — deployment workflows
- [Development Guide](docs/DEVELOPMENT.md) — contributing and local dev setup
- [Stack Spec Reference](docs/stack-spec-reference.md) — specification format
- [Testing](docs/TESTING.md) — test strategy and running tests
- [ADRs](docs/ADR/) — architecture decision records

## License

Apache 2.0 — see [LICENSE](LICENSE).
