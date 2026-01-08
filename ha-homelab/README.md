# High Availability Homelab StackKit

Enterprise-grade homelab with high availability, automatic failover, and distributed services.

> ⚠️ **Status: Scaffolding Only** - This StackKit is under development.

## Overview

The HA Homelab extends the Modern Homelab with:
- **High Availability k3s** with embedded etcd
- **Load balancing** across multiple master nodes
- **Distributed storage** with automatic replication
- **Automatic failover** for all critical services
- **Multi-site** support (optional)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        High Availability Homelab                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                         ┌─────────────┐                                      │
│                         │ Load        │                                      │
│                         │ Balancer    │                                      │
│                         │ (HAProxy/   │                                      │
│                         │  MetalLB)   │                                      │
│                         └──────┬──────┘                                      │
│                                │                                             │
│     ┌──────────────────────────┼──────────────────────────┐                 │
│     │                          │                          │                  │
│     ▼                          ▼                          ▼                  │
│ ┌──────────┐             ┌──────────┐             ┌──────────┐              │
│ │  Master  │◄───────────►│  Master  │◄───────────►│  Master  │              │
│ │  Node 1  │   etcd      │  Node 2  │   etcd      │  Node 3  │              │
│ │          │   sync      │          │   sync      │          │              │
│ └────┬─────┘             └────┬─────┘             └────┬─────┘              │
│      │                        │                        │                     │
│      │    ┌───────────────────┴───────────────────┐    │                     │
│      │    │                                       │    │                     │
│      ▼    ▼                                       ▼    ▼                     │
│ ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                   │
│ │ Worker 1 │   │ Worker 2 │   │ Worker 3 │   │ Worker N │                   │
│ └──────────┘   └──────────┘   └──────────┘   └──────────┘                   │
│                                                                              │
│ ┌────────────────────────────────────────────────────────────────────────┐  │
│ │                    Distributed Storage (Longhorn/Ceph)                  │  │
│ │                         Auto-replication across nodes                   │  │
│ └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Planned Features

### High Availability Control Plane
- [ ] 3+ master nodes with embedded etcd
- [ ] Automatic leader election
- [ ] Control plane load balancing

### Distributed Storage
- [ ] Longhorn with 3x replication
- [ ] Optional Ceph integration
- [ ] S3-compatible backup targets

### Load Balancing
- [ ] MetalLB for bare-metal LB
- [ ] HAProxy for external access
- [ ] Automatic health checks

### Monitoring & Alerting
- [ ] Prometheus HA setup
- [ ] Thanos for long-term metrics
- [ ] PagerDuty/Slack integration

### Disaster Recovery
- [ ] Velero backups
- [ ] Cross-site replication
- [ ] RTO/RPO guarantees

## Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Master Nodes | 3 | 5 |
| Worker Nodes | 2 | 3+ |
| CPU/Node | 4 cores | 8 cores |
| RAM/Node | 8 GB | 16 GB |
| Disk/Node | 100 GB SSD | 256 GB NVMe |
| Network | Gigabit | 10 Gigabit |

## Deployment Modes

Inherits from base architecture:
- **Simple:** OpenTofu-only with Go integration
- **Advanced:** Terramate with drift detection (recommended for HA)

## Status

🚧 **Under Development** - Target: Q3 2025

See [ROADMAP.md](../../docs/ROADMAP.md) for timeline.
