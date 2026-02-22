# Layer 3: StackKits

Deployable stacks combining foundation + platform + services.

## Modules

| Module | Foundation | Platform | Description |
|--------|------------|----------|-------------|
| base-homelab | base | docker | Single-server Docker homelab (local-only or single domain) |
| modern-homelab | base | docker | Production-ready with CI/CD pipelines |
| ha-homelab | extended | docker-swarm | High availability, multi-node |

## What StackKits Define

- Service composition (which services to deploy)
- Variant selection logic (PaaS choice, monitoring choice)
- Configuration templates
- Deployment automation
- Success criteria

## Development Flow

```
base-homelab ──proves──> full StackKit patterns work
     │
     ▼
modern-homelab, ha-homelab ──extend──> for advanced use cases
```
