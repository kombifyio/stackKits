# Modern Homelab StackKit

> ⚠️ **Status: Scaffolding (v0.1.0-alpha)** - Structure defined, templates in progress

Multi-server hybrid homelab with **Docker + Coolify** for users who need:
- Public-facing services
- Multi-node deployments (cloud + local servers)
- Professional PaaS experience
- Remote access to on-premises servers

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PUBLIC INTERNET                              │
└─────────────────────────────┬───────────────────────────────────────┘
                              │ HTTPS (443)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     CLOUD NODE (VPS)                                │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Traefik                                   │   │
│  │              (Reverse Proxy + TLS)                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐   │
│  │  Coolify     │ │  Headscale   │ │  Prometheus + Grafana    │   │
│  │  (PaaS)      │ │  (VPN Coord) │ │  Loki (Logs)             │   │
│  └──────────────┘ └──────────────┘ └──────────────────────────┘   │
│                              │ Tailscale VPN (100.x.x.x)           │
└──────────────────────────────┼──────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  LOCAL NODE 1 │   │  LOCAL NODE 2 │   │  LOCAL NODE N │
│  (On-Prem)    │   │  (On-Prem)    │   │  (On-Prem)    │
│               │   │               │   │               │
│ ┌───────────┐ │   │ ┌───────────┐ │   │ ┌───────────┐ │
│ │ Tailscale │ │   │ │ Tailscale │ │   │ │ Tailscale │ │
│ │  Agent    │ │   │ │  Agent    │ │   │ │  Agent    │ │
│ └───────────┘ │   │ └───────────┘ │   │ └───────────┘ │
│ ┌───────────┐ │   │ ┌───────────┐ │   │ ┌───────────┐ │
│ │  Docker   │ │   │ │  Docker   │ │   │ │  Docker   │ │
│ │Workloads  │ │   │ │Workloads  │ │   │ │Workloads  │ │
│ └───────────┘ │   │ └───────────┘ │   │ └───────────┘ │
└───────────────┘   └───────────────┘   └───────────────┘
```

## Comparison: base-homelab vs modern-homelab

| Feature | base-homelab | modern-homelab |
|---------|--------------|----------------|
| Nodes | Single server | Multi-server (cloud + local) |
| Platform | Docker | Docker |
| PaaS | Dokploy | **Coolify** |
| Network | Local only | Public + VPN overlay |
| Access | LAN/Tailscale | Internet + VPN |
| DNS | Optional | Required (ACME) |
| Monitoring | Optional | Full PLG stack |
| Use case | Home network | Hybrid/public services |

## Core Components

### Required Services (always deployed)

| Service | Role | Deployment |
|---------|------|------------|
| **Traefik** | Reverse proxy + TLS | Cloud node |
| **Headscale** | VPN coordination | Cloud node |
| **Tailscale Agent** | VPN client | All nodes |
| **Coolify** | PaaS (container orchestration) | Cloud node |

### Monitoring Stack (default variant)

| Service | Role | Deployment |
|---------|------|------------|
| **Prometheus** | Metrics collection | Cloud node |
| **Grafana** | Dashboards | Cloud node |
| **Loki** | Log aggregation | Cloud node |
| **Promtail** | Log shipper | All nodes |
| **Uptime Kuma** | Status page | Cloud node |

## Variants

### default
Full monitoring stack with Coolify, Headscale, and PLG (Prometheus/Loki/Grafana).

### minimal
Just Coolify + Headscale + Uptime Kuma. No heavy monitoring.

### beszel
Lightweight alternative using Beszel instead of PLG stack.

## Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Cloud Nodes | 1 | 1-2 |
| Local Nodes | 0 | 1+ |
| CPU (cloud) | 2 cores | 4 cores |
| Memory (cloud) | 4 GB | 8 GB |
| Domain | Required | Required |
| DNS Provider | Required | Cloudflare/Hetzner |

## Quick Start

```yaml
# kombination.yaml
apiVersion: kombistack.io/v1alpha1
kind: Stack
metadata:
  name: my-homelab
spec:
  stackKit: modern-homelab
  variant: default
  
  cluster:
    name: homelab
    domain: example.com
    
    nodes:
      cloud:
        - name: vps-1
          provider:
            type: hetzner
            region: fsn1
            size: cx21
          network:
            publicIp: "1.2.3.4"
      
      local:
        - name: homeserver
          provider:
            type: bare-metal
          network:
            localIp: "192.168.1.100"
    
    vpn:
      serverUrl: "https://hs.example.com"
      baseDomain: "example.com"
    
    tls:
      provider: letsencrypt
      email: admin@example.com
```

## File Structure

```
modern-homelab/
├── stackkit.yaml      # Metadata and variant definitions
├── stackkit.cue       # Main CUE schema
├── services.cue       # Service definitions (Docker + Coolify)
├── defaults.cue       # Default values per variant
├── README.md          # This file
├── templates/
│   └── simple/        # OpenTofu templates (TODO)
├── tests/
│   └── *.cue          # CUE validation tests
└── variants/
    └── *.cue          # Variant-specific configs
```

## Implementation Status

- [x] StackKit metadata (stackkit.yaml)
- [x] CUE schema (stackkit.cue)
- [x] Service definitions (services.cue)
- [x] Default values (defaults.cue)
- [ ] OpenTofu templates
- [ ] Variant configurations
- [ ] Integration tests

## Changelog

### v0.1.0-alpha (2025-01)
- Initial scaffolding
- Docker + Coolify architecture (replaced k8s design)
- Service definitions: Traefik, Headscale, Coolify, PLG monitoring
- Multi-node hybrid topology (cloud + local nodes)
- Implemented: cert-manager, Velero
- Added: Smart defaults by cluster tier
- Added: OpenTofu templates

## License

MIT
