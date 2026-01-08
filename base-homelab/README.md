# Base Homelab StackKit

> **Single-server homelab with Docker and essential services**

## 🎯 Overview

The **Base Homelab** StackKit provides everything you need to run a modern homelab on a single server:

- **Traefik** - Reverse proxy with automatic SSL
- **Dockge** - Visual Docker Compose management
- **Dozzle** - Real-time log viewer
- **Netdata** - System monitoring dashboard

## 📋 Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 50 GB | 100+ GB |
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |

## 🚀 Quick Start

```yaml
# kombination.yaml
name: my-homelab
goals:
  storage: true
nodes:
  - name: server-1
    os: ubuntu-24
    resources:
      cpu: 4
      memory: 8
```

## 📦 Included Services

### Traefik (Reverse Proxy)
- Automatic HTTPS via Let's Encrypt
- Docker integration
- Dashboard at `http://traefik.local:8080`

### Dockge (Container Management)
- Visual compose file editor
- One-click deployments
- Access at `http://dockge.local`

### Dozzle (Log Viewer)
- Real-time container logs
- Filtering and search
- Access at `http://logs.local`

### Netdata (Monitoring)
- System metrics dashboard
- Container monitoring
- Access at `http://monitor.local`

## 🔧 Variants

### OS Variants
- `ubuntu-24` - Ubuntu 24.04 LTS (recommended)
- `ubuntu-22` - Ubuntu 22.04 LTS
- `debian-12` - Debian 12 Bookworm

### Compute Variants
- `high` - 8+ CPU, 16+ GB RAM: Full stack with Prometheus/Grafana
- `standard` - 4-7 CPU, 8-15 GB RAM: Default services
- `low` - <4 CPU or <8 GB RAM: Lightweight alternatives

## 📁 File Structure

```
base-homelab/
├── stackkit.yaml       # Metadata
├── stackfile.cue       # Main schema
├── services.cue        # Service definitions
├── defaults.cue        # Smart defaults
├── variants/
│   ├── os/
│   │   ├── ubuntu-24.cue
│   │   ├── ubuntu-22.cue
│   │   └── debian-12.cue
│   └── compute/
│       ├── high.cue
│       ├── standard.cue
│       └── low.cue
└── templates/
    ├── simple/
    │   └── main.tf.tpl
    └── advanced/
        └── stacks/
```

## 🔒 Security

- SSH hardening (key-only auth)
- UFW firewall enabled
- TLS 1.2+ enforced
- Non-root container execution

## 📖 Documentation

- [Service Configuration](docs/services.md)
- [Networking](docs/networking.md)
- [Customization](docs/customization.md)
