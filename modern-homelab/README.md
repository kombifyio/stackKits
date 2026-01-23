# Modern Homelab StackKit

> ⚠️ **v1.1 PLANNED - Not part of v1.0 release**
> 
> **Status: Alpha/Planning** - Architecture designed, implementation not started

This StackKit is planned for **StackKits v1.1** and is **not functional** in the current release. The architecture and specifications below represent the planned design.

---

## Prerequisites (v1.1)

This StackKit has significant requirements compared to `base-homelab`:

| Requirement | Details |
|-------------|---------|
| **Own Domain** | You must own a domain with DNS control (e.g., Cloudflare, Hetzner DNS) |
| **Minimum 2 Nodes** | At least 1 cloud VPS + 1 local server |
| **PaaS Platform** | Uses **Coolify** (not Dokploy like base-homelab) |
| **Public IP** | Cloud node requires public IPv4 |
| **DNS Provider API** | For automated TLS certificate provisioning |

> 💡 **Looking for something simpler?** Use [`base-homelab`](../base-homelab/) instead - it works on a single local machine with Dokploy and is **fully functional in v1.0**.

---

## What This StackKit Will Provide (v1.1)

Multi-server hybrid homelab with **Docker + Coolify** for users who need:
- Public-facing services with automatic TLS
- Multi-node deployments (cloud + local servers)
- Professional PaaS experience via Coolify
- Secure remote access to on-premises servers via VPN

## Planned Architecture

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

| Feature | base-homelab (v1.0) | modern-homelab (v1.1 planned) |
|---------|---------------------|-------------------------------|
| **Status** | ✅ Functional | ⏳ Planned |
| Nodes | Single server | Multi-server (cloud + local) |
| Platform | Docker | Docker |
| PaaS | Dokploy | **Coolify** |
| Network | Local only | Public + VPN overlay |
| Access | LAN/Tailscale | Internet + VPN |
| DNS | Optional | **Required** (ACME) |
| Monitoring | Optional | Full PLG stack |
| Use case | Home network | Hybrid/public services |

## Planned Core Components

### Required Services (planned for deployment)

| Service | Role | Deployment |
|---------|------|------------|
| **Traefik** | Reverse proxy + TLS | Cloud node |
| **Headscale** | VPN coordination | Cloud node |
| **Tailscale Agent** | VPN client | All nodes |
| **Coolify** | PaaS (container orchestration) | Cloud node |

### Monitoring Stack (planned default variant)

| Service | Role | Deployment |
|---------|------|------------|
| **Prometheus** | Metrics collection | Cloud node |
| **Grafana** | Dashboards | Cloud node |
| **Loki** | Log aggregation | Cloud node |
| **Promtail** | Log shipper | All nodes |
| **Uptime Kuma** | Status page | Cloud node |

## Planned Variants

> ⚠️ These variants are designed but not implemented yet.

### default
Full monitoring stack with Coolify, Headscale, and PLG (Prometheus/Loki/Grafana).

### minimal
Just Coolify + Headscale + Uptime Kuma. No heavy monitoring.

### beszel
Lightweight alternative using Beszel instead of PLG stack.

## Requirements (v1.1)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Cloud Nodes | 1 | 1-2 |
| Local Nodes | 1 | 1+ |
| CPU (cloud) | 2 cores | 4 cores |
| Memory (cloud) | 4 GB | 8 GB |
| **Domain** | **Required** | **Required** |
| **DNS Provider** | **Required** | Cloudflare/Hetzner |

## Example Specification (v1.1)

> ⚠️ This specification format is planned and may change before v1.1 release.

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

> **Target Release: v1.1**

### Completed (Design Phase)
- [x] StackKit metadata structure (stackkit.yaml)
- [x] CUE schema design (stackkit.cue)
- [x] Service definitions (services.cue)
- [x] Default values structure (defaults.cue)
- [x] Architecture documentation

### Not Started (Implementation)
- [ ] OpenTofu templates
- [ ] Coolify integration
- [ ] Headscale/Tailscale automation
- [ ] Variant configurations
- [ ] Integration tests
- [ ] End-to-end deployment testing

## Changelog

### v0.1.0-alpha (2025-01) - Design Phase
- Initial architecture design
- Docker + Coolify architecture specification
- Service definitions: Traefik, Headscale, Coolify, PLG monitoring
- Multi-node hybrid topology design (cloud + local nodes)

---

## See Also

- [`base-homelab`](../base-homelab/) - **Recommended for v1.0** - Single-node homelab with Dokploy
- [`ha-homelab`](../ha-homelab/) - High-availability homelab (also v1.1 planned)

## License

MIT
