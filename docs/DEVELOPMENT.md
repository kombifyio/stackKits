# Development — kombify StackKits

## Prerequisites

- [Go](https://go.dev/) (1.22+)
- [CUE](https://cuelang.org/) CLI
- [Docker](https://docs.docker.com/get-docker/)

## Getting started

```bash
# Clone
git clone https://github.com/kombify/stackkits.git
cd stackkits

# Build
make build

# Run dev server
make dev
# → API on http://localhost:5280

# Run tests
make test

# Validate CUE schemas
cue vet ./...
```

## Project structure

```
cmd/                  # Entry point
pkg/                  # Core Go packages
api/                  # API definitions
base-homelab/         # Base Homelab StackKit
modern-homelab/       # Modern Homelab StackKit
ha-homelab/           # HA Homelab StackKit
base/                 # Shared CUE schemas
cue.mod/              # CUE module dependencies
```

## Common tasks

```bash
make dev              # Start dev server
make test             # Run tests
make build            # Build binary
cue vet ./...         # Validate all CUE schemas
```
