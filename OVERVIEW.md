# kombify StackKits -- Overview

**One-Liner:** Declarative infrastructure blueprint engine that turns CUE definitions into fully deployed homelab and self-hosted stacks.

**Purpose:**
kombify StackKits defines reusable infrastructure compositions entirely in CUE, a typed configuration language. It solves the problem of deploying multi-service homelab environments (reverse proxy, PaaS, monitoring, identity, etc.) by encoding all service definitions, constraints, and defaults into validated schemas. The `stackkit` CLI reads these CUE definitions, generates OpenTofu and Docker Compose artifacts internally, and applies them to a target server in a single automated step. It eliminates manual server configuration and ad-hoc Docker commands for self-hosted infrastructure.

**Core Tasks:**
- Define infrastructure blueprints (StackKits) as CUE schemas with typed service definitions, constraints, and defaults
- Provide a CLI (`stackkit init/prepare/generate/plan/apply/destroy/status`) for the full deployment lifecycle
- Generate OpenTofu HCL and Docker Compose artifacts from CUE definitions (internal engine, never user-facing)
- Deploy 3-layer stacks (Foundation, Platform, Applications) to servers via SSH with zero manual steps
- Auto-detect node context (local, cloud, pi) and apply hardware-aware defaults
- Serve an HTTP API (`stackkit-server`) for catalog browsing, spec validation, and artifact generation
- Provide composable add-ons (monitoring, backup, VPN, media, smart-home, GPU workloads, etc.)
- Host a SvelteKit marketing/documentation website (`website-v2/`, deployed to stackkits.kombify.io)

**Tech Stack:**
- Go 1.24 (CLI and API server, Cobra for commands)
- CUE (schema definitions, configuration validation -- the single source of truth)
- OpenTofu (internal IaC execution engine, never user-facing)
- Docker / Docker Compose (container runtime and orchestration)
- SvelteKit 5 + Tailwind CSS 4 + TypeScript (marketing website)
- Playwright (website E2E and visual regression tests)
- GoReleaser + Dagger (build and release pipeline)
- Doppler (secrets management)
- Azure Container Apps (website hosting)

**Boundaries (does NOT do):**
- Does NOT provide a web UI for managing deployments -- that is kombify Stack (techstack.kombify.io)
- Does NOT manage user accounts, orgs, or billing -- that is kombify Core
- Does NOT handle API gateway routing or authentication -- that is kombify API (Kong)
- Does NOT store persistent user data in a database -- that is kombify DB (PostgreSQL)
- Does NOT provide AI-assisted recommendations or optimization -- that is kombify Sphere
- Does NOT simulate or test stacks in sandboxed environments -- that is kombify Sim

**Ecosystem Role:**
- Consumed by kombify Stack, which loads StackKit definitions and exposes them through a web UI wizard
- Standalone at Level 0 (CLI-only); integrates at Level 1+ when controlled by kombify Stack's control plane
- At Level 2+, a gRPC agent on the target server executes StackKit operations on behalf of kombify Stack
- Owns all StackKit definitions (CUE schemas), add-on definitions, and the `stackkit` CLI binary
- The HTTP API (`/api/v1/stackkits`, `/api/v1/validate`, `/api/v1/generate`) is consumed by kombify Stack for catalog and validation
- No direct dependency on kombify API (Kong), kombify DB, or Zitadel -- those are platform concerns handled by kombify Stack/Core

**Marketing Pitch:**
kombify StackKits lets you deploy a complete self-hosted infrastructure -- reverse proxy, app platform, monitoring, identity, and more -- with a single command. Define what you want in a simple spec file, and StackKits handles the rest: validated blueprints, automated provisioning, and zero manual server configuration. From a single home server to a hybrid cloud setup, your infrastructure is always one `stackkit apply` away.

**Status:** Active development. Base Kit is functional and deployable. Modern Homelab and HA Kit exist as schema definitions only. The CLI covers the full lifecycle. The HTTP API is implemented. 17 add-on categories are defined. The marketing website is built but deployment maturity varies.
