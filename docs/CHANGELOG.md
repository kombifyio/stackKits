# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Direct Connect Registry:** stackkit-server instances register with kombify for Kong API Gateway discovery. Includes heartbeat (60s interval), deregistration on shutdown, and post-deploy registration in `stackkit apply` for kombify.me domains. (`internal/kombifyme/registry.go`, `cmd/stackkit-server/main.go`)
- **Service URL Matrix (ADR-0006):** 3 domain modes x 3 reverse proxy backends = 9 deployment scenarios. PAAS selection (`paas:` field in stack-spec.yaml) determines whether platform services route through standalone Traefik, Dokploy's Traefik, or Coolify's Traefik. (`pkg/models/models.go`, `cmd/stackkit/commands/generate.go`, `base-kit/templates/simple/main.tf`)
- **Coolify PAAS Support:** Alternative to Dokploy — set `paas: coolify` in stack-spec.yaml. Coolify manages its own Traefik; platform services attach to Coolify's network for routing.
- **DNS-01 ACME Challenge:** Traefik can now obtain Let's Encrypt certificates via DNS-01 challenge for devices behind NAT. Supports Cloudflare, Hetzner, DigitalOcean, DuckDNS, Namecheap. Auto-selected when `tls.provider` is set in stack-spec.yaml. (`cmd/stackkit/commands/generate.go`)
- **TLSSpec in stack-spec.yaml:** New `tls:` section with `provider` (DNS provider) and `challenge` (tls/dns) fields. Environment variables: `STACKKIT_DNS_TOKEN`, `STACKKIT_DNS_EMAIL`.
- **Deploy Logging API:** Structured deploy log capture with SSE streaming. Endpoints: `GET /api/v1/logs`, `GET /api/v1/logs/latest`, `GET /api/v1/logs/{runID}`, `GET /api/v1/logs/{runID}/stream`. (`internal/api/handlers_logs.go`)
- **OpenAPI 3.1 Specification:** Full API spec at `/api/v1/openapi.yaml` for Kong Gateway integration. Covers all 14 endpoints including registry and logs.
- **Architecture V5:** 6-Concept Model replacing V4. Variant system removed, replaced by per-tool role system (default/alternative/optional/addon). 10 use cases defined.
- **Architecture V4:** 3-Concept Model (StackKit + Node-Context + Add-Ons) with Progressive Capability Model.
- **GoReleaser:** Cross-compilation for linux/darwin/windows (amd64 + arm64).
- **Release Workflow:** GitHub Actions `release.yml` triggers on `v*` tags.
- **CUE → Terraform Bridge:** `internal/cue/bridge.go` generates `terraform.tfvars.json` from CUE specifications.
- **CI/CD Pipeline:** GitHub Actions workflow for lint, test, build, and CUE validation.

### Fixed

- **CUE schemas:** All 4 kits validate cleanly against CUE v0.9.
- **Compute tiers:** Aligned to `low/standard/high` across Go + CUE.
- **Layer 3 validation:** Warns on PaaS presence instead of requiring it (Docker-first per ADR-0002).
- **Go validator:** Removed Kubernetes from valid platforms; added `bare-metal`.

### Removed

- **Kubernetes references:** Removed from all docs, Go code, and CUE schemas per ADR-0002.
- **`base/platform/` and `base/schema/`:** Deleted orphan CUE packages.
- **`plans/` and `missions/`:** Archived to `docs/_archive/`.
- **`marketing/` and `platforms/`:** Archived to `docs/_archive/`.

### Changed

- **All kits:** Version aligned to `4.0.0`.
- **Go CI:** Updated to Go 1.24.
- **Docs:** Consolidated 3 deployment docs into single `docs/DEPLOYMENT.md`.
- **ADRs:** Consolidated from root `ADR/` into `docs/ADR/`.

## [2.0.0] - 2026-01-10

### Changed

- **Major Architecture Shift:** Docker-First strategy adopted (ADR-001).
- Docs: Complete documentation overhaul and CLI design specification.
- Docs: Roadmap updated to reflect standalone project status.

## [1.0.0] - 2025-12-01

### Added

- Initial StackKit structure.
- `base-kit` StackKit (v1).
- CUE schema definitions and validation logic.
- Basic OpenTofu templates for Docker provisioning.
- CLI scaffold.

### Removed

- Deprecated `stackkits/` directory (older structure).
- Deprecated `_web` components.
