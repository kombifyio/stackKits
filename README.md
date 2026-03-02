# StackKits

Declarative infrastructure blueprints for homelabs. Define your stack in CUE, generate deployment artifacts, apply to a fresh server — fully automated, zero manual steps.

## What is a StackKit?

A StackKit is a complete infrastructure composition defined entirely in [CUE](https://cuelang.org/). It describes services, networking, security, and deployment configuration. The `stackkit` CLI reads your CUE definitions and stack specification, generates OpenTofu files, and deploys everything to your server.

```
Edit .cue files → stackkit generate → stackkit apply → Done.
```

## Base Kit

The **Base Kit** is a single-environment deployment pattern — all services run on one node via Docker Compose.

### Default Services

| Layer | Service | Purpose |
|-------|---------|---------|
| L2 Platform | **Traefik** | Reverse proxy with automatic HTTPS |
| L2 Identity | **TinyAuth** | Forward auth with passkeys & OAuth |
| L2 Identity | **PocketID** | OpenID Connect identity provider |
| L2 Platform | **Dokploy** | PaaS platform for app deployment |
| L2 Observability | **Dozzle** | Real-time Docker log viewer |
| L3 Application | **Uptime Kuma** | Uptime monitoring & status pages |
| L3 Application | **Whoami** | Proxy verification test service |

### Variants

| Variant | Description |
|---------|-------------|
| `default` | Dokploy + TinyAuth + PocketID + Uptime Kuma |
| `coolify` | Coolify instead of Dokploy (requires own domain) |
| `beszel` | Beszel server metrics instead of Uptime Kuma |
| `minimal` | Dockge + Portainer + Netdata (traditional compose management) |

### Deployment Modes

| Mode | Engine | Use Case |
|------|--------|----------|
| `simple` | OpenTofu | Single-node, quick setup |
| `advanced` | Terramate | Drift detection, multi-stack orchestration |

## Requirements

- **Target server**: Ubuntu 22/24 or Debian 12 with root SSH access
- 2+ CPU cores, 4+ GB RAM, 50+ GB disk (4 cores / 8 GB recommended)

The CLI installs all dependencies (Docker, OpenTofu) on the target server automatically.

## Quick Start

### 1. Install the CLI

```bash
curl -sSL https://raw.githubusercontent.com/kombifyio/stackKits/main/install.sh | sh
```

Or build from source:

```bash
git clone https://github.com/kombifyio/stackKits.git && cd stackKits
make build    # Binary at: ./build/stackkit
```

### 2. Initialize and Configure

```bash
mkdir my-homelab && cd my-homelab
stackkit init base-kit
```

Edit `stack-spec.yaml` with your server details:

```yaml
name: my-homelab
stackkit: base-kit
variant: default
mode: simple
domain: homelab.example.com
ssh:
  host: <your-server-ip>
  user: root
  port: 22
```

### 3. Deploy

```bash
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

- [CLI Reference](docs/CLI.md) — all commands and flags
- [Stack Spec Reference](docs/stack-spec-reference.md) — specification format

## License

Apache 2.0 — see [LICENSE](LICENSE).
