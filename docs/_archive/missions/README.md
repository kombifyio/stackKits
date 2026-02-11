# Missions

This folder contains the core definitions for everything we build. It's structured in 3 layers that build upon each other.

## Layer Architecture

```
Layer 3: StackKits        [base-homelab] [modern-homelab] [ha-homelab]
                                ▲              ▲              ▲
Layer 2: Platform              [docker]    [docker-swarm]  [kubernetes]
                                ▲              ▲              ▲
Layer 1: Foundation        [minimal]       [base]        [extended]
```

## Layers

### Layer 1: Foundation
Defines core patterns, security defaults, and configuration standards.
- **minimal** - Bare minimum, no opinions
- **base** - Sensible defaults for homelabs
- **extended** - Enterprise patterns, compliance, HA

### Layer 2: Platform
Defines container runtime and orchestration.
- **docker** - Single host, simple deployment
- **docker-swarm** - Multi-host clustering
- **kubernetes** - Full orchestration, complex workloads

### Layer 3: StackKits
Actual deployable stacks combining foundation + platform + services.
- **base-homelab** - Single-server Docker homelab (local-only or single domain)
- **modern-homelab** - Production-ready with CI/CD
- **ha-homelab** - High availability, multi-node

## How Layers Compose

A StackKit declaration references its dependencies:

```yaml
name: base-homelab
layers:
  foundation: base
  platform: docker
```

Each layer inherits and can override definitions from below.

## Folder Structure

```
missions/
├── layer-1-foundation/
│   ├── minimal/
│   ├── base/
│   └── extended/
├── layer-2-platform/
│   ├── docker/
│   ├── docker-swarm/
│   └── kubernetes/
└── layer-3-stackkits/
    ├── base-homelab/
    ├── modern-homelab/
    └── ha-homelab/
```
