# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **CUE → Terraform Bridge:** `internal/cue/bridge.go` generates `terraform.tfvars.json` from CUE specifications.
- **Service Variants:** Complete variant system with 4 options:
  - `default`: Dokploy + Uptime Kuma (no domain required)
  - `coolify`: Coolify + Uptime Kuma (requires domain)
  - `beszel`: Dokploy + Beszel (monitoring focus)
  - `minimal`: Dockge + Portainer + Netdata (lightweight)
- **Variant Tests:** `base-homelab/tests/variant_test.cue` for testing all variants.
- **CI/CD Pipeline:** GitHub Actions workflow for lint, test, build, and CUE validation.
- **ROADMAP.md:** Now includes gap analysis + backlog (single source of truth).
- **Unit Tests:** Initial unit test structure in `tests/unit/`.

### Fixed

- **modern-homelab/stackkit.cue:** Fixed import `#StackKitBase` → `#BaseStackKit`.
- **tests/validation_test.cue:** Fixed broken platform imports (commented out K8s).
- **modern-homelab schema:** Aligned metadata fields with base schema.

### Removed

- **`_archive/` folder:** Historical content now tracked via git history only.
- **`docs/cleanup/` folder:** Methodology consolidated into single `Cleanup-Plan.md`.
- Consolidated planning docs into canonical docs.

### Changed

- **Cleanup-Plan.md:** Simplified to single file (v2.1), removed modular structure.
- **docs/README.md:** Updated navigation, removed references to deleted folders.
- **STATUS_QUO.md:** Updated with cleanup summary and implementation status.

## [2.0.0] - 2026-01-10

### Changed

- **Major Architecture Shift:** Docker-First strategy adopted (ADR-001).
- Docs: Complete documentation overhaul and CLI design specification.
- Docs: Roadmap updated to reflect standalone project status.

## [1.0.0] - 2025-12-01

### Added

- Initial StackKit structure.
- `base-homelab` StackKit (v1).
- CUE schema definitions and validation logic.
- Basic OpenTofu templates for Docker provisioning.
- CLI scaffold.

### Removed

- Deprecated `stackkits/` directory (older structure).
- Deprecated `_web` components.
