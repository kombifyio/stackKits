# StackKits CLI Reference

> **Version:** 1.0 (Planned)  
> **Status:** Design Phase

This document describes the planned `stackkit` CLI tool for standalone StackKit deployments without KombiStack.

## Overview

The `stackkit` CLI enables infrastructure deployment directly from the terminal. It handles:

- StackKit discovery and selection
- Configuration validation (CUE)
- OpenTofu execution
- Drift detection and updates
- System prerequisites (Docker, OpenTofu)

## Installation

### Quick Install (Recommended)

```bash
# Linux/macOS
curl -fsSL https://stackkits.dev/install.sh | bash

# Windows (PowerShell)
irm https://stackkits.dev/install.ps1 | iex
```

### Package Managers

```bash
# Homebrew (macOS/Linux)
brew install kombihq/tap/stackkit

# APT (Debian/Ubuntu)
sudo apt install stackkit

# DNF (Fedora/RHEL)
sudo dnf install stackkit
```

### From Source

```bash
go install github.com/kombihq/stackkits/cmd/stackkit@latest
```

## Commands

### `stackkit init`

Initialize a new deployment from a StackKit.

```bash
# Interactive mode
stackkit init

# Specify StackKit
stackkit init base-homelab

# With variant
stackkit init base-homelab --variant minimal

# With configuration file
stackkit init base-homelab -f config.yaml
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --file` | Spec file path | `./stack-spec.yaml` |
| `--variant` | Service variant | `default` |
| `--compute-tier` | Resource tier | `auto` |
| `--os` | Target OS variant | `auto-detect` |
| `--output` | Output directory | `./deploy` |

**Example Output:**

```
$ stackkit init base-homelab --variant minimal
✓ Downloading StackKit: base-homelab v2.0.0
✓ Detected OS: Ubuntu 24.04 (noble)
✓ Detected Resources: 4 CPU, 8GB RAM → tier: standard
✓ Validating configuration...
✓ Generated deployment in ./deploy

Next steps:
  1. Review configuration:  cat ./deploy/main.tf
  2. Preview changes:       stackkit plan
  3. Deploy:                stackkit apply
```

### `stackkit prepare` (alias: `prep`)

Prepare a bare system for StackKit deployment AND validate/adjust the spec file.

```bash
# Prepare current system (tools only)
sudo stackkit prepare

# Prepare + validate spec (RECOMMENDED)
stackkit prep --spec ./default-spec.yaml

# Prepare remote system
stackkit prep --host 192.168.1.100 --user admin --spec ./default-spec.yaml

# Dry-run mode
stackkit prep --dry-run --spec ./default-spec.yaml
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--spec` | Spec file to validate/adjust | None |
| `--host` | Remote host IP/hostname | `localhost` |
| `--user` | SSH username | Current user |
| `--key` | SSH private key path | `~/.ssh/id_rsa` |
| `--dry-run` | Show what would be installed/changed | `false` |
| `--skip-docker` | Skip Docker installation | `false` |
| `--skip-tofu` | Skip OpenTofu installation | `false` |
| `--auto-fix` | Auto-correct fixable issues | `true` |

**What `prep` does:**

#### 1. Tool Installation

- **System packages:** curl, ca-certificates, gnupg
- **Docker:** docker-ce, docker-compose-plugin
- **OpenTofu:** Latest stable version
- **Optional:** CUE (for local validation)

#### 2. Spec Validation (with `--spec`)

```bash
$ stackkit prep --spec ./my-homelab.yaml

✓ Validating spec file...
  ✓ CUE Schema: Valid
  ✓ Required fields: Complete
  
⚠️ Auto-corrections applied:
  • ssh.key_path: ~/.ssh/id_ed25519 → /home/admin/.ssh/id_ed25519
  • network.subnet: (empty) → 172.20.0.0/16 (default)
  
✓ Hardware check (192.168.1.100):
  ✓ RAM: 8GB (required: 4GB)
  ✓ CPU: 4 cores (required: 2)
  ✓ Disk: 50GB free (required: 20GB)
  ✓ Ports: 80, 443 available
  ✓ Docker: 27.5.1 (required: 24.0+)
  
✓ Spec file updated: ./my-homelab.yaml
```

#### 3. Auto-Fix Capabilities

| Issue | Auto-Fix Action |
|-------|-----------------|
| `~/.ssh/...` path | Expand to absolute path |
| Missing `network.subnet` | Apply default (172.20.0.0/16) |
| Missing `network.gateway` | Derive from subnet |
| Port conflicts | Suggest alternatives |
| Insufficient RAM | Suggest `compute.tier: minimal` |

#### 4. Hardware Validation

When `--spec` is provided and node IPs are configured:

```bash
# Remote hardware check
$ stackkit prep --spec ./ha-homelab.yaml

Checking node: node-1 (192.168.1.101)...
  ✓ SSH: Connected (user: admin)
  ✓ OS: Ubuntu 24.04 (arm64)
  ✓ RAM: 16GB (required: 8GB)
  ✓ Docker: Not installed → will be installed
  
Checking node: node-2 (192.168.1.102)...
  ✓ SSH: Connected (user: admin)
  ⚠️ RAM: 4GB (required: 8GB) → downgrading tier to 'minimal'
  ✓ Docker: 27.3.0 (required: 24.0+)
  
Summary:
  • 2/2 nodes reachable
  • 1 auto-fix applied (compute tier adjustment)
  • Ready for: stackkit apply
```

### `stackkit validate`

Validate a spec file against the CUE schema without making changes.

```bash
# Validate spec file
stackkit validate ./my-spec.yaml

# Validate with specific StackKit
stackkit validate ./my-spec.yaml --kit base-homelab

# Strict mode (no warnings allowed)
stackkit validate ./my-spec.yaml --strict
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--kit` | StackKit to validate against | Auto-detect from spec |
| `--strict` | Treat warnings as errors | `false` |
| `--json` | Output as JSON | `false` |

**Example Output:**

```bash
$ stackkit validate ./incomplete-spec.yaml

Validating against: base-homelab v2.0.0

❌ Errors:
  • nodes[0].ssh.key_path: required field missing
  • services: must contain at least 1 item

⚠️ Warnings:
  • network.tls.mode: 'self-signed' - consider 'letsencrypt' for production
  • nodes[0].compute.tier: 'minimal' may not support all services

Result: INVALID (2 errors, 2 warnings)
```

### `stackkit plan`

Preview infrastructure changes without applying.

```bash
# Plan from current directory
stackkit plan

# Plan specific deployment
stackkit plan -d ./deploy

# Detailed output
stackkit plan --verbose
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --dir` | Deployment directory | `./deploy` |
| `-o, --out` | Save plan to file | None |
| `--verbose` | Show detailed changes | `false` |
| `--json` | Output as JSON | `false` |

### `stackkit apply`

Apply the infrastructure configuration.

```bash
# Apply with confirmation
stackkit apply

# Auto-approve (CI/CD)
stackkit apply --auto-approve

# Apply specific plan file
stackkit apply --plan plan.tfplan
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-d, --dir` | Deployment directory | `./deploy` |
| `--auto-approve` | Skip confirmation | `false` |
| `--plan` | Use saved plan file | None |
| `--parallelism` | Max parallel operations | `10` |

### `stackkit destroy`

Remove all deployed infrastructure.

```bash
# Destroy with confirmation
stackkit destroy

# Auto-approve
stackkit destroy --auto-approve

# Target specific resource
stackkit destroy --target docker_container.traefik
```

### `stackkit status`

Show current deployment status.

```bash
# Basic status
stackkit status

# Detailed with service health
stackkit status --health

# JSON output
stackkit status --json
```

**Example Output:**

```
$ stackkit status --health
StackKit: base-homelab v2.0.0
Variant: default
Status: DEPLOYED

Services:
  ✓ traefik       Running  https://traefik.home.local
  ✓ dokploy       Running  https://deploy.home.local
  ✓ uptime-kuma   Running  https://status.home.local

Resources:
  Containers: 3 running
  Volumes: 5 (2.1 GB used)
  Networks: 1

Last applied: 2026-01-10 14:30:00 UTC
```

### `stackkit drift`

Detect configuration drift.

```bash
# Check for drift
stackkit drift

# Auto-fix drift
stackkit drift --fix

# Continuous monitoring
stackkit drift --watch --interval 5m
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--fix` | Apply fixes automatically | `false` |
| `--watch` | Continuous monitoring | `false` |
| `--interval` | Check interval (watch mode) | `5m` |

### `stackkit list`

List available StackKits.

```bash
# List all
stackkit list

# Filter by tag
stackkit list --tag homelab

# Show details
stackkit list --verbose
```

**Example Output:**

```
$ stackkit list
NAME             VERSION  DESCRIPTION                           TAGS
base-homelab     2.0.0    Single-server homelab                 homelab, docker
modern-homelab   1.0.0    Local + Cloud hybrid (2 nodes)        homelab, hybrid
ha-homelab       1.0.0    Multi-cloud high availability (3+)    homelab, ha, k8s
```

### `stackkit validate`

Validate configuration without deploying.

```bash
# Validate kombination.yaml
stackkit validate

# Validate specific file
stackkit validate -f my-config.yaml

# Strict mode (no warnings allowed)
stackkit validate --strict
```

### `stackkit update`

Update an existing deployment.

```bash
# Update to latest StackKit version
stackkit update

# Update specific service
stackkit update --service traefik

# Preview update
stackkit update --dry-run
```

### `stackkit logs`

View service logs.

```bash
# All services
stackkit logs

# Specific service
stackkit logs traefik

# Follow mode
stackkit logs -f

# With timestamps
stackkit logs --timestamps
```

## Configuration File

### `kombination.yaml`

```yaml
# kombination.yaml - StackKit Configuration
apiVersion: stackkit/v1
kind: Kombination

metadata:
  name: my-homelab
  description: Personal home server setup

# StackKit selection
stackkit: base-homelab
variant: default
computeTier: standard

# Domain configuration
domain: homelab.local
acmeEmail: admin@example.com

# Network mode
network:
  mode: local  # or: public
  subnet: "172.20.0.0/16"

# Node configuration
nodes:
  - name: server-1
    os: ubuntu-24
    ip: 192.168.1.100
    resources:
      cpu: 4
      memory: 8192  # MB
      storage: 100  # GB

# Service overrides
services:
  traefik:
    dashboard: true
    logLevel: INFO
  dokploy:
    enabled: true

# Optional: Add-ons
addons:
  - monitoring
  - backup-restic
```

### Environment Variables

```bash
# Override configuration
export STACKKIT_DOMAIN="homelab.example.com"
export STACKKIT_ACME_EMAIL="admin@example.com"
export STACKKIT_VARIANT="minimal"

# SSH configuration
export STACKKIT_SSH_USER="admin"
export STACKKIT_SSH_KEY="~/.ssh/homelab"

# Logging
export STACKKIT_LOG_LEVEL="debug"  # debug, info, warn, error

# State backend
export STACKKIT_STATE_BACKEND="local"  # local, s3, gcs
```

## Workflows

### Fresh Server Deployment

```bash
# 1. Prepare the server
sudo stackkit prepare

# 2. Initialize StackKit
stackkit init base-homelab --variant default

# 3. Review configuration
cat kombination.yaml

# 4. Preview changes
stackkit plan

# 5. Deploy
stackkit apply

# 6. Verify
stackkit status --health
```

### Update Existing Deployment

```bash
# 1. Check current status
stackkit status

# 2. Detect drift
stackkit drift

# 3. Preview update
stackkit update --dry-run

# 4. Apply update
stackkit update
```

### Modify Service Configuration

```bash
# 1. Edit configuration
vim kombination.yaml

# 2. Validate changes
stackkit validate

# 3. Preview changes
stackkit plan

# 4. Apply changes
stackkit apply
```

### Add Custom Service

```bash
# Edit kombination.yaml to add:
# services:
#   custom-app:
#     image: myapp:latest
#     ports: [8080]

# Apply changes
stackkit apply

# Verify
stackkit status
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | Configuration validation failed |
| `3` | Plan/Apply failed |
| `4` | Drift detected |
| `5` | Prerequisites missing |

## Shell Completion

```bash
# Bash
stackkit completion bash > /etc/bash_completion.d/stackkit

# Zsh
stackkit completion zsh > ~/.zsh/completion/_stackkit

# Fish
stackkit completion fish > ~/.config/fish/completions/stackkit.fish

# PowerShell
stackkit completion powershell >> $PROFILE
```

## Troubleshooting

### Common Issues

**Docker not running:**
```bash
$ stackkit apply
Error: Docker daemon is not running

Fix: sudo systemctl start docker
```

**Permission denied:**
```bash
$ stackkit apply
Error: Permission denied for /var/run/docker.sock

Fix: sudo usermod -aG docker $USER && newgrp docker
```

**OpenTofu not found:**
```bash
$ stackkit apply
Error: OpenTofu not found in PATH

Fix: sudo stackkit prepare --skip-docker
```

### Debug Mode

```bash
# Enable debug logging
STACKKIT_LOG_LEVEL=debug stackkit apply

# Trace OpenTofu commands
TF_LOG=TRACE stackkit apply
```

## Next Steps

- [Architecture](architecture.md) - Understand the system design
- [Creating StackKits](creating-stackkits.md) - Build custom StackKits
- [Variant System](variants.md) - OS and compute variants
