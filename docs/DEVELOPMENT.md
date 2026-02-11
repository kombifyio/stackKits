# Development — kombify StackKits

## Prerequisites

- [Go](https://go.dev/) 1.24+
- [CUE](https://cuelang.org/) CLI 0.9+
- [Docker](https://docs.docker.com/get-docker/) (optional)
- Make

## Getting Started

```bash
# Clone
git clone https://github.com/KombiverseLabs/StackKits.git
cd StackKits

# Build CLI
make build
# → ./bin/stackkit

# Run tests
make test

# Validate CUE schemas
cue vet ./...
```

## Project Structure

```
cmd/stackkit/         # CLI entry point + commands
internal/             # Go internal packages (cue, docker, validation, ...)
pkg/models/           # Public Go models
base/                 # Core CUE schemas (imported by all kits)
base-homelab/         # Single Environment Kit
dev-homelab/          # Developer Kit
ha-homelab/           # High-Availability Kit
modern-homelab/       # Multi-Node Kit (planned)
docs/                 # Documentation
website-v2/           # Documentation site (SvelteKit)
cue.mod/              # CUE module dependencies
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `STACKKITS_PORT` | `5280` | API server port |
| `STACKKITS_DATA_DIR` | `./data` | Data directory |
| `STACKKITS_LOG_LEVEL` | `info` | Log verbosity |

See [SETTINGS-CLASSIFICATION.md](SETTINGS-CLASSIFICATION.md) for the full settings taxonomy.

## Common Tasks

```bash
make build            # Build binary → ./bin/stackkit
make test             # Run Go tests
cue vet ./...         # Validate all CUE schemas
cue eval ./base-homelab/  # Evaluate a schema
go test ./...         # Run tests directly
```
