# CLAUDE.md - kombify StackKits

---

## !! STOP — READ THIS BEFORE ANYTHING ELSE !!

**CUE IS THE ONLY SOURCE OF TRUTH FOR A STACKKIT.**

- A StackKit is defined by its `.cue` files. Nothing else.
- Terraform/OpenTofu, Docker Compose, shell scripts = **GENERATED OUTPUT**. They do not exist until `stackkit generate` creates them.
- **NEVER write, edit, or manually run Terraform/OpenTofu.** It is an internal engine, not a user-facing tool.
- **NEVER manually deploy, configure, or patch anything on a server.** `stackkit apply` does everything, fully automated.
- If you are touching anything other than `.cue` files to "change" a StackKit, you are doing it wrong.

**The correct workflow:**
1. Change `.cue` files
2. `stackkit generate` (produces artifacts — do not edit them)
3. `stackkit apply` (deploys everything — no manual steps)

**There is no step 4.** If someone suggests one, the CUE definition is incomplete.

---

## Project Overview
Infrastructure-as-Code StackKit definitions and CLI tool. Defines reusable infrastructure compositions using CUE.

## Tech Stack
- Language: Go 1.24 + CUE
- CLI: Custom stackkit binary
- Testing: Go test + E2E shell scripts

## Critical Rules

### A StackKit IS its CUE definitions
A StackKit is defined entirely by its CUE schemas and service definitions. OpenTofu/Terraform files, Docker Compose files, and all deployment artifacts are GENERATED OUTPUT — they are never authored or edited directly.

**How StackKits work:**
1. CUE definitions describe services, configuration, layers, and constraints
2. `stackkit generate` produces all deployment artifacts (OpenTofu, Compose, etc.)
3. `stackkit apply` deploys ALL layers (L1 Foundation, L2 Platform, L3 Applications) to a fresh server

**To change a StackKit, you change its CUE definitions. Nothing else.**

**NEVER:**
- Edit generated files (`main.tf`, compose YAML, or any output artifact)
- Manually deploy, start, stop, or modify anything on the server/VM
- Do incremental patches — every change means a fresh deployment from scratch
- Ship a StackKit where any layer requires manual post-deploy steps

**Testing:** A valid test is `stackkit apply` on a clean server producing a fully working stack. Any test that requires manual intervention on the server is broken by definition.

### NEVER use localhost addresses for users
All service URLs shown to users, generated in configs, or used in outputs MUST use proper domain names (e.g. `whoami.stack.local`, `dokploy.stack.local`), NEVER `localhost:PORT`. This applies to:
- OpenTofu outputs and deployment summaries
- CLI output messages
- Documentation and examples
- E2E test verification URLs shown to users
- Any user-facing URL references

The architecture uses Traefik reverse proxy with domain-based routing. Services are accessed via `<service>.<domain>`, not via raw ports on localhost.

### NEVER use ports 3000 or 3001 as external/host ports
These ports conflict with common dev tools (Next.js, React dev servers, Grafana, etc.). Use 4000/4001 instead. Internal container ports (what the app listens on inside the container) are exempt from this rule. Enforced by pre-commit hook.

## Standards
Follows kombify Core/standards/STANDARDS.md

## Development
go build -o stackkit ./cmd/stackkit
mise run dev

## Dependencies
- kombify Stack: Consumes StackKit definitions
