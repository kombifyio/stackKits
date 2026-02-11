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

### TD-04: Compute Tier Naming Inconsistency

**Location:** Go models vs CUE schemas  
**Problem:** Go uses `minimal/standard/performance`, CUE uses `low/standard/high`.  
**Impact:** Go↔CUE bridge produces mismatches; user-facing inconsistency.  
**Fix:** Align to CUE naming (`low/standard/high`) everywhere.  
**Milestone:** M0

### TD-05: Platform Type Mismatch

**Location:** Go validator in `internal/` vs CUE schemas  
**Problem:** Go validator accepts `"kubernetes"`, but CUE only allows `docker/docker-swarm/bare-metal`. ADR-0002 explicitly excludes Kubernetes from v1.  
**Impact:** Specs with `kubernetes` pass Go validation but fail CUE validation.  
**Fix:** Remove `kubernetes` from Go validator.  
**Milestone:** M0

### TD-06: Layer 3 PAAS Validation Inverted

**Location:** Go `layer_validator.go`  
**Problem:** Go code searches for PAAS in Layer 3, but per architecture PAAS is Layer 2 and Layer 3 MUST NOT contain PAAS services.  
**Impact:** Incorrect validation — rejects valid configs, accepts invalid ones.  
**Fix:** Invert logic: Layer 3 rejects PAAS services, Layer 2 allows them.  
**Milestone:** M0

### ~~TD-07: Dual Main Schemas in base-homelab~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12.

### TD-08: modern-homelab Entirely K8s-Based

**Location:** `modern-homelab/` (all files)  
**Problem:** All CUE schemas, services, defaults, and tests reference K8s/k3s/FluxCD/Longhorn. Architecture v4 defines modern-homelab as Docker multi-node with VPN overlay.  
**Impact:** Entire StackKit is non-functional for the current architecture.  
**Fix:** Complete rewrite of all `.cue` files. Delete K8s schemas and tests.  
**Milestone:** M3

### TD-09: Services Format Inconsistency (W8)

**Location:** `base.#BaseStackKit` vs `base-homelab/stackfile.cue`  
**Problem:** Base defines `services: [...#ServiceDefinition]` (ordered list). base-homelab defines `services: { traefik: ..., dokploy: ... }` (named map/struct).  
**Impact:** Cannot validate base-homelab services against base schema.  
**Fix:** Adopt named map (struct) everywhere — enables `services.traefik.enabled` access. Update `base.#BaseStackKit`.  
**Milestone:** M1

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

### TD-14: OpenTofu Validation Not Executed

**Location:** `internal/tofu/validate.go`  
**Problem:** `validate` command prints "valid" without actually running `tofu validate`.  
**Impact:** False sense of validation.  
**Fix:** Shell out to `tofu validate` on generated files.  
**Milestone:** M1

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

### TD-22: plans/ and missions/ Directories

**Location:** `plans/`, `missions/`  
**Problem:** Historical planning documents from early development. May reference outdated concepts.  
**Impact:** Low — not actively used but may confuse new contributors.  
**Fix:** Review and archive or delete if superseded.  
**Milestone:** M0

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

### TD-25: Domain Validation Inconsistency (W10)

**Location:** `ha-homelab/stackfile.cue` vs `base-homelab/stackfile.cue`  
**Problem:** HA rejects local domains (`!~"\\.(local|lan)$"`), Base allows them. Unclear if HA requiring public domains is intentional.  
**Impact:** Confusing user experience.  
**Fix:** Clarify in ADR: HA can use local or public. If local, Keepalived VIP; if public, cloud LB.  
**Milestone:** M3

### TD-26: Dokploy/Coolify Selection Logic (W12)

**Location:** `docs/architecture.md`, services definitions  
**Problem:** Architecture doc says "no domain → Dokploy, domain → Coolify". But Dokploy supports custom domains fine.  
**Impact:** Confusing simplified rule.  
**Fix:** Clarify: "local → Dokploy (simpler), multi-node/cloud → Coolify (required for remote)".  
**Milestone:** M0

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

---

*This register is the **task-planning source of truth** for StackKits. Items are updated when debt is added, resolved, or re-prioritized. Reference it alongside the [Roadmap](docs/ROADMAP.md).*
