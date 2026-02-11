# Architecture — kombify StackKits

## Overview

kombify StackKits provides infrastructure blueprints using CUE schemas. It validates user specifications (`kombination.yaml`) and generates configurations.

## Components

```
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│  kombination.yaml│────▶│  CUE Engine  │────▶│  Validated     │
│  (user spec)    │     │  (validation)│     │  Config Output │
└─────────────────┘     └──────┬───────┘     └────────────────┘
                               │
                        ┌──────▼───────┐
                        │  StackKit    │
                        │  Schemas     │
                        │  (base/*.cue)│
                        └──────────────┘
```

## StackKit hierarchy

| Kit | Target | Nodes | Level |
|-----|--------|-------|-------|
| `base-homelab` | Beginners | 1 | 0-1 |
| `modern-homelab` | Intermediate | 1-2 | 0-3 |
| `ha-homelab` | Advanced | 3+ | 0-4 |

## CUE schema structure

Each StackKit contains:
- **Kit definition** (`kit.cue`) — metadata, supported levels, required add-ons
- **Service schemas** (`services/*.cue`) — per-service validation rules
- **Add-on schemas** (`addons/*.cue`) — optional feature definitions
- **Defaults** — sensible default configurations

## Data flow

1. User creates/edits `kombination.yaml`
2. StackKits validates spec against the selected kit's CUE schemas
3. Validation produces either errors or a resolved configuration
4. Resolved config is passed to Stack for deployment

See also: [ARCHITECTURE_V4.md](ARCHITECTURE_V4.md) for the latest architecture revision.
