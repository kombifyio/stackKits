# Dev Homelab

> **Internal Development Only** - Not for publication

Minimal StackKit for e2e testing of CLI and integration tools.

## Purpose

This StackKit exists to:
1. **Test CLI commands** - init, validate, plan, apply, destroy, status
2. **Validate integration** - Kombify Administration, pipelines
3. **Prove contract compliance** - Before full base-homelab implementation
4. **Iterate quickly** - Minimal surface area for fast feedback

## What's Included

| Component | Description |
|-----------|-------------|
| Docker Network | `dev_net` (172.21.0.0/16) |
| whoami | Simple HTTP test endpoint |

## Quick Start

```bash
# Initialize
stackkit init dev-homelab

# Validate
stackkit validate

# Deploy
stackkit plan
stackkit apply

# Test
curl http://localhost:9080

# Cleanup
stackkit destroy
```

## Files

```
dev-homelab/
├── stackkit.yaml       # StackKit metadata
├── default-spec.yaml   # Default stack spec
├── defaults.cue        # CUE defaults
├── services.cue        # Service definitions
├── stackfile.cue       # Stack composition
├── templates/
│   └── simple/
│       └── main.tf     # OpenTofu config
└── tests/
    └── e2e_test.sh     # E2E test script
```

## Testing Contract Compliance

This StackKit validates:

- [ ] `stackkit init` creates valid stack-spec.yaml
- [ ] `stackkit validate` passes CUE validation
- [ ] `stackkit plan` generates valid OpenTofu plan
- [ ] `stackkit apply` deploys without errors
- [ ] whoami service responds at localhost:9080
- [ ] `stackkit status` shows healthy service
- [ ] `stackkit destroy` removes all resources

## Relationship to base-homelab

```
dev-homelab ──validates──> base-homelab-CONTRACT.yaml
                               │
                               ▼
                        base-homelab (full)
```

Once dev-homelab passes all tests, the patterns proven here
will be applied to the full base-homelab implementation.
