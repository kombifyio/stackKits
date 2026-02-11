# StackKits — Technical Debt Register

> **Last Updated:** 2026-02-12  
> **Architecture:** v4 (see [ARCHITECTURE_V4.md](docs/ARCHITECTURE_V4.md))  
> **Roadmap:** [docs/ROADMAP.md](docs/ROADMAP.md)

---

## Purpose & Role

**This document is the single source of truth for task-planning and backlog management** in the StackKits repo. Use it to:
- **Plan sprints/sessions** — pick items by priority (P0 first)
- **Track what needs doing** — every actionable item lives here
- **Measure progress** — items move to "Resolved" when done

For milestone timelines and release strategy, see [docs/ROADMAP.md](docs/ROADMAP.md).

---

## Overview

Items are categorized by severity and mapped to roadmap milestones.

**Severity levels:**
- **P0 (Blocker)** — Breaks builds, tests, or deployments
- **P1 (High)** — Incorrect behavior, data inconsistency, or architectural violation
- **P2 (Medium)** — Suboptimal patterns, missing features, or maintenance burden
- **P3 (Low)** — Cosmetic, minor inconsistencies, nice-to-have cleanups

---

## P0 — Blockers

### ~~TD-01: CUE Package Declaration Errors~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-02: Schema Duplication~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-03: dev-homelab Package Conflict~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

---

## P1 — High Priority

### ~~TD-04: Compute Tier Naming Inconsistency~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-05: Platform Type Mismatch~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-06: Layer 3 PAAS Validation Inverted~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-07: Dual Main Schemas in base-homelab~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### TD-08: modern-homelab Entirely K8s-Based

**Location:** `modern-homelab/` (all files)  
**Problem:** All CUE schemas, services, defaults, and tests reference K8s/k3s/FluxCD/Longhorn. Architecture v4 defines modern-homelab as Docker multi-node with VPN overlay.  
**Impact:** Entire StackKit is non-functional for the current architecture.  
**Fix:** Complete rewrite of all `.cue` files. Delete K8s schemas and tests.  
**Milestone:** M3

### ~~TD-09: Services Format Inconsistency (W8)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-13.

### TD-10: Missing CUE→Terraform Code Generator

**Location:** `internal/template/`, `bridge.go`  
**Problem:** The core promise — generating OpenTofu configs from CUE — is not implemented. `bridge.go` only generates `tfvars`. `generate.go` copies templates verbatim instead of rendering.  
**Impact:** Users must manually write/maintain `main.tf`. CUE schemas are decorative, not functional.  
**Fix:** Implement proper CUE export → tfvars.json pipeline. OpenTofu modules replace monolithic `main.tf`.  
**Milestone:** M1

### TD-11: Headscale Port Conflict (W9)

**Location:** `modern-homelab/services.cue`  
**Problem:** Headscale binds host port 443, Traefik also binds port 443.  
**Impact:** Services cannot co-exist on the same node.  
**Fix:** Headscale uses alternate port or runs behind Traefik as upstream.  
**Milestone:** M3

---

## P2 — Medium Priority

### TD-12: Variants Directory Still Exists

**Location:** `base-homelab/variants/`  
**Problem:** Old monolithic variant system (8 files across `os/`, `compute/`, `service/`) still present despite v4 replacing it with Add-Ons + Contexts.  
**Impact:** Confusion about current architecture. Code references old patterns.  
**Fix:** Migrate to Add-Ons and Contexts, then delete directory.  
**Milestone:** M4

### ~~TD-13: Version Metadata Inconsistency (W11)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-14: OpenTofu Validation Not Executed~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-13.

### TD-15: Missing Go Unit Tests

**Location:** `tests/unit/`  
**Problem:** Test directory is essentially empty. `internal/config`, `internal/cue`, `internal/template` have no tests.  
**Impact:** No regression safety for core packages.  
**Fix:** Write unit tests for all `internal/` packages.  
**Milestone:** M3

### ~~TD-16: Coolify Image Typo~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

### ~~TD-17: Whoami Service Missing Host Port~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

### ~~TD-18: HealthCheck Format Inconsistency (W5)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### ~~TD-19: Committed Binary~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

### ~~TD-20: Junk File at Root~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

---

## P3 — Low Priority

### TD-21: Two Website Projects

**Location:** `marketing/` (Vite+React) and `website-v2/` (SvelteKit)  
**Problem:** Two separate web projects with no clear canonical status.  
**Impact:** Maintenance burden, unclear which is deployed.  
**Fix:** Decide canonical site, archive the other.  
**Milestone:** M9

### ~~TD-22: plans/ and missions/ Directories~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11.

### TD-23: kombify-admin/ Local Prisma Schema

**Location:** `kombify-admin/`  
**Problem:** Local admin UI uses its own Prisma schema instead of centralized `kombify-DB` tables.  
**Impact:** Data duplication, schema drift from central DB.  
**Fix:** Migrate to `kombify-DB` `content_*` tables (see `kombify-DB/TECHNICAL_DEBT.md` TD-10).  
**Milestone:** M9

### TD-24: GitHub Org References (kombihq)

**Location:** `cue.mod/module.cue`, all CUE imports (20+ files)  
**Problem:** References `github.com/kombihq/stackkits` — org name may change.  
**Impact:** Low until Go module depends on resolvable import. CUE local evaluation still works.  
**Fix:** Update when org name is finalized. Deferred due to impact on 3+ Go modules.  
**Milestone:** Deferred

### ~~TD-25: Domain Validation Inconsistency (W10)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-14. HA domain regex changed from TLD blocklist to positive hostname format validation. `step-ca` added as TLS provider for local domains. See ADR-0004.

### ~~TD-26: Dokploy/Coolify Selection Logic (W12)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Original `docs/architecture.md` (which contained the confusing rule) was archived. ROADMAP M2 now correctly specifies: \"Dokploy for local, Coolify for cloud/multi-node\".

---

## Resolved

| TD# | Description | Resolved | How |
|-----|------------|----------|-----|
| TD-01 | CUE package declarations in subdirs | 2026-02-12 | Deleted `base/platform/` and `base/schema/` — unreachable duplicate packages |
| TD-02 | Schema duplication (PAASConfig etc.) | 2026-02-12 | Canonical source is `base/layers.cue`; deleted `base/platform/` duplicates |
| TD-07 | Dual schemas in base-homelab | 2026-02-12 | Deleted `#BaseHomelabKit` (unused); `#BaseHomelabStack` is canonical (all tests use it) |
| TD-13 | Version metadata inconsistency | 2026-02-12 | Aligned to `4.0.0` in both `stackkit.yaml` and `stackfile.cue` |
| TD-18 | HealthCheck snake_case vs camelCase | 2026-02-12 | Fixed `start_period` → `startPeriod` in `dev-homelab/services.cue` |
| TD-03 | dev-homelab package conflict (`devhomelab` → `dev_homelab`) | 2026-02-11 | Unified package name across all 4 CUE files + templates |
| TD-16 | Coolify image typo (`coolabsio` → `coollabsio`) | 2026-02-11 | Fixed in `base/platform/paas.cue` |
| TD-17 | Whoami service missing host port | 2026-02-11 | Host port added in `dev-homelab/exports.cue` |
| TD-19 | Committed binary (`stackkit.exe`) | 2026-02-11 | Deleted from repo, `.gitignore` covers `*.exe` |
| TD-20 | Junk file (`{{range`) at root | 2026-02-11 | Deleted |
| — | License inconsistency (K2) | 2026-02-10 | Apache 2.0 unified in LICENSE + README |
| — | `modern-homelab/stackkit.cue` naming | 2026-02-11 | Renamed to `stackfile.cue` for consistency |
| — | `stack-spec.yaml` deprecated fields | 2026-02-11 | Removed `variant`/`mode`, added `context`, fixed tier naming |
| — | ha-homelab `object-storage` missing from ServiceType | 2026-02-12 | Added to `#ServiceType` enum in `base/stackkit.cue` |
| — | dev-homelab import alias shadowing | 2026-02-12 | Changed import to `dockerplatform "..."` |
| — | dev-homelab schema mismatches (14 errors) | 2026-02-12 | Fixed base schemas (middlewares, tinyauth, category, driver) + dev-homelab values (maxFile, retention struct, paths) |
| TD-04 | Compute tier naming (`minimal/performance` → `low/high`) | 2026-02-12 | Aligned Go models, validator, tests, and CLI to CUE naming (`low/standard/high`) |
| TD-05 | Platform type mismatch (`kubernetes` in Go validator) | 2026-02-12 | Removed `kubernetes`, added `bare-metal` in Go validator per ADR-0002 |
| TD-06 | Layer 3 PAAS validation inverted | 2026-02-12 | Rewrote `validateLayer3`: warns if PAAS found (PAAS belongs in Layer 2), no longer requires it |
| — | K8s refs in docs (stack-spec-reference, TARGET_STATE) | 2026-02-12 | Removed K8s schema sections, examples, and references from active docs |
| TD-22 | plans/ and missions/ directories | 2026-02-11 | Archived to `docs/_archive/plans/` and `docs/_archive/missions/` |
| TD-26 | Dokploy/Coolify selection logic | 2026-02-11 | Source doc archived; ROADMAP M2 clarifies: local→Dokploy, cloud→Coolify |
| TD-09 | Services format inconsistency (list vs map) | 2026-02-13 | Standardized to map `[string]: #ServiceDefinition` in base/stackkit.cue, base-homelab/services.cue, dev-homelab/stackfile.cue — matches ha/modern-homelab and Go `StackSpec.Services` |
| TD-14 | OpenTofu validation not executed | 2026-02-13 | `cmd/stackkit/commands/validate.go` now uses `tofu.Executor.Validate()` with JSON error parsing, init-if-needed, and install check |
| TD-25 | Domain validation inconsistency | 2026-02-14 | HA regex changed to positive hostname format; `step-ca` TLS provider added for local domains. See ADR-0004 |

---

*This register is the **task-planning source of truth** for StackKits. Items are updated when debt is added, resolved, or re-prioritized. Reference it alongside the [Roadmap](docs/ROADMAP.md).*
