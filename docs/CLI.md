# StackKit CLI (`stackkit`)

This document describes the **implemented** `stackkit` CLI in this repository.

## Install

### Build from source (recommended for dev)

```bash
make build
./build/stackkit version
```

### Go install

```bash
go install github.com/kombihq/stackkits/cmd/stackkit@latest
stackkit version
```

## Global flags

These flags work for all subcommands:

- `-v, --verbose` Enable verbose output
- `-q, --quiet` Suppress non-essential output
- `-C, --chdir` Change to directory before running (default: `.`)
- `-s, --spec` Path to stack specification file (default: `stack-spec.yaml`)

## Common workflow

```bash
mkdir my-homelab
cd my-homelab

stackkit init base-homelab
stackkit prepare
stackkit generate
stackkit plan
stackkit apply
```

## Commands

### `stackkit init [stackkit]`

Create a new `stack-spec.yaml` in the current directory.

```bash
stackkit init base-homelab
stackkit init base-homelab --variant default
stackkit init base-homelab --mode simple
stackkit init base-homelab --compute-tier auto
```

Flags:

- `--variant` Service variant to use (default: `default`)
- `--compute-tier` Compute tier (default: `standard`)
- `--mode` Deployment mode (default: `simple`)
- `-o, --output` Output directory for generated files (default: `deploy`)
- `-f, --force` Overwrite existing files
- `--non-interactive` Run in non-interactive mode (fail if input required)

### `stackkit prepare` (alias: `prep`)

Prepare a system for StackKit deployments and validate the spec (if present).

```bash
stackkit prepare
stackkit prepare --spec ./stack-spec.yaml
stackkit prepare --host 192.168.1.100 --user root
stackkit prepare --dry-run --host 192.168.1.100 --user root
```

Flags:

- `--host` Target host (default: `localhost`)
- `--user` SSH username (remote only)
- `--key` SSH private key path (remote only)
- `--dry-run` Show what would be done
- `--skip-docker` Skip Docker checks/install
- `--skip-tofu` Skip OpenTofu checks/install
- `--auto-fix` Auto-correct fixable issues (default: `true`)

### `stackkit generate` (alias: `gen`)

Generate OpenTofu files from the spec and StackKit templates.

```bash
stackkit generate
stackkit generate -o deploy
stackkit generate -o deploy --force
```

Flags:

- `-o, --output` Output directory (default: `deploy`)
- `-f, --force` Overwrite existing output directory

### `stackkit plan`

Run `tofu plan` inside `./deploy`.

```bash
stackkit plan
stackkit plan -o plan.tfplan
```

Flags:

- `-o, --out` Save plan to a file
- `--destroy` Create destroy plan (currently accepted but not wired through)

### `stackkit apply [plan-file]`

Run `tofu apply` inside `./deploy`.

```bash
stackkit apply
stackkit apply --auto-approve
stackkit apply deploy/plan.tfplan
```

Flags:

- `--auto-approve` Skip interactive approval

### `stackkit destroy`

Run `tofu destroy` inside `./deploy`.

```bash
stackkit destroy
stackkit destroy --auto-approve
stackkit destroy --auto-approve --force
```

Flags:

- `--auto-approve` Skip interactive approval (otherwise you must type `yes`)
- `--force` Continue even if errors occur

### `stackkit status`

Show deployment status by inspecting Docker containers.

```bash
stackkit status
stackkit status --json
```

Flags:

- `--json` Output as JSON (currently accepted but not implemented)

### `stackkit validate [file]`

Validate spec files and optionally all CUE files.

```bash
stackkit validate
stackkit validate ./stack-spec.yaml
stackkit validate --all
```

Flags:

- `--all` Validate all CUE files found under the working directory

### `stackkit version`

Print version information.

```bash
stackkit version
```
