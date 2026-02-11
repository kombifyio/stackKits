# StackKits — Technical Debt Register

> **Last Updated:** 2026-02-16  
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

### ~~TD-27: API Arbitrary Filesystem Write (C1)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Removed `outputDir` from request; handler now always uses temp dir + returns content.

### ~~TD-28: No API Authentication (C2)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Added `apiKeyMiddleware` with `--api-key` flag / `STACKKITS_API_KEY` env var. Health + OpenAPI endpoints exempt.

### ~~TD-29: OpenAPI Compute Tier Enum Mismatch (C3)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Updated OpenAPI spec `ComputeSpec.tier` enum from `[minimal, standard, performance]` to `[low, standard, high]`.

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

### ~~TD-30: CLI generate Does Not Use Template Renderer (I5)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Rewrote `copyOrRenderTemplates` to use `template.Renderer` instead of plain file copy.

### ~~TD-31: iac and terramate Packages Are Dead Code (I6)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12. CLI commands (validate, plan, apply, destroy) now use `iac.NewExecutorFromSpec()`. Expanded `iac.Executor` interface with `Validate`, `Output` methods and `ExecResult` type. Both OpenTofu and Terramate backends wired through unified interface.

### ~~TD-32: internal/errors Package Mostly Unused (I8)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12. Adopted `internal/errors` across API handlers and middleware. `writeStructuredError` returns category, code, and suggestions in JSON responses. Auth, rate-limit, validation, generation, and not-found errors now use structured error types. Added `validateStackKitName` with OpenAPI regex enforcement.

### TD-11: Headscale Port Conflict (W9)

**Location:** `modern-homelab/services.cue`  
**Problem:** Headscale binds host port 443, Traefik also binds port 443.  
**Impact:** Services cannot co-exist on the same node.  
**Fix:** Headscale uses alternate port or runs behind Traefik as upstream.  
**Milestone:** M3

---

## P2 — Medium Priority

### ~~TD-33: No API Rate Limiting (I1)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Added per-IP sliding-window rate limiter with `--rate-limit` flag / `STACKKITS_RATE_LIMIT` env (default: 60 req/min). Health endpoints exempt.

### ~~TD-34: Zero API Handler Test Coverage (I2)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Added `handlers_test.go` with 42 test cases covering all handlers + middleware (API key, CORS, rate limiting).

### ~~TD-35: Logging Middleware Missing Response Status (I3)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Added `statusResponseWriter` wrapper to capture HTTP status code in logs.

### ~~TD-36: CLI status --json Flag Not Implemented (I4)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Implemented JSON output mode in `runStatus` using same data as table output.

### ~~TD-37: CLI prepare Memory Check Missing (I7)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Implemented `runtime.ReadMemStats` + `/proc/meminfo` parsing on Linux, with graceful OS fallback.

### TD-38: Interactive init Is a Stub (I9)

**Location:** `cmd/stackkit/commands/init.go` L78-82  
**Problem:** Running `stackkit init` without arguments lists available StackKits and errors out. No interactive selection.  
**Fix:** Add bubbletea or promptui-based interactive wizard for StackKit, domain, email, compute tier.  
**Milestone:** M4
**Task:** StackKits-l3s.12

### ~~TD-39: Hardcoded stackKitDirs in API Handler (I10)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Replaced hardcoded `stackKitDirs` with auto-discovery loop scanning baseDir for `stackkit.yaml`.

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

**Location:** `tests/unit/`, `internal/api/`  
**Problem:** `tests/unit/` is essentially empty. `internal/api/` (handlers.go ~580 lines, server.go ~190 lines) has **zero test coverage** despite implementing all 13 API endpoints. `internal/config`, `internal/cue`, `internal/template` also lack tests.  
**Impact:** No regression safety for core packages. API regressions are undetectable.  
**Fix:** Write unit tests for all `internal/` packages, prioritizing `internal/api/` (httptest-based handler tests).  
**Milestone:** M1 (API tests), M3 (remaining packages)  
**Task:** StackKits-l3s.5

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

### ~~TD-40: CORS Wildcard Not Configurable (N1)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Added `--cors-origins` flag / `STACKKITS_CORS_ORIGINS` env with per-request origin matching and `Vary: Origin`.

### ~~TD-41: No Pagination on List Endpoints (N2)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12. Added `?limit=N&offset=M` query params; response now returns `{"items":[], "total":N, "limit":L, "offset":O}` envelope.

### ~~TD-42: Deprecated strings.Title Usage (N5)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-11. Replaced with `cases.Title(language.English)` from `golang.org/x/text`.

### ~~TD-43: No Shell Completion Command (N6)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12. Added `stackkit completion bash|zsh|fish|powershell` using Cobra built-in generators.

### ~~TD-44: tfvars Format Inconsistency (N7)~~ → RESOLVED

> Moved to [Resolved](#resolved) on 2026-02-12. Standardized on JSON `.tfvars.json` in both CLI generate and API.

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
| TD-27 | API arbitrary filesystem write | 2026-02-11 | Removed `outputDir` from request; `handleGenerateTFVars` uses temp dir + returns content |
| TD-28 | No API authentication | 2026-02-11 | Added `apiKeyMiddleware` with `--api-key` flag / `STACKKITS_API_KEY` env. Health + OpenAPI exempt |
| TD-29 | OpenAPI compute tier enum mismatch | 2026-02-11 | Updated `ComputeSpec.tier` from `[minimal, standard, performance]` to `[low, standard, high]` |
| TD-30 | CLI generate doesn't use template Renderer | 2026-02-11 | Rewrote `copyOrRenderTemplates` to use `template.Renderer` |
| TD-35 | Logging middleware missing response status | 2026-02-11 | Added `statusResponseWriter` wrapper to capture HTTP status in logs |
| TD-36 | CLI status `--json` flag not implemented | 2026-02-11 | Implemented JSON output mode in `runStatus` |
| TD-42 | Deprecated `strings.Title` usage | 2026-02-11 | Replaced with `cases.Title(language.English)` from `golang.org/x/text` |
| TD-33 | No API rate limiting | 2026-02-11 | Per-IP sliding-window rate limiter with `--rate-limit` flag (default 60/min), health exempt |
| TD-34 | Zero API handler test coverage | 2026-02-11 | Added `handlers_test.go` with 42 test cases for all handlers + middleware |
| TD-37 | CLI prepare memory check missing | 2026-02-11 | `runtime.ReadMemStats` + `/proc/meminfo` on Linux, graceful OS fallback |
| TD-39 | Hardcoded `stackKitDirs` in API handler | 2026-02-11 | Auto-discover StackKit dirs via `stackkit.yaml` presence |
| TD-40 | CORS wildcard not configurable | 2026-02-11 | `--cors-origins` flag / `STACKKITS_CORS_ORIGINS` env with per-request matching |
| TD-31 | iac/terramate packages are dead code | 2026-02-12 | CLI validate/plan/apply/destroy now use `iac.NewExecutorFromSpec`. Expanded `iac.Executor` with `Validate`, `Output`, `ExecResult` |
| TD-32 | internal/errors package mostly unused | 2026-02-12 | `writeStructuredError` in API, structured errors for auth/rate-limit/validation/not-found. `validateStackKitName` regex. validatePartial expanded to cover email/domain/ssh/compute/nodes |
| TD-41 | No pagination on list endpoints | 2026-02-12 | Added `?limit=N&offset=M` query params with paginated response envelope `{items, total, limit, offset}` |
| TD-43 | No shell completion command | 2026-02-12 | Added `stackkit completion bash\|zsh\|fish\|powershell` via Cobra generators |
| TD-44 | tfvars format inconsistency | 2026-02-12 | Standardized on JSON `.tfvars.json` in both CLI and API |

---

*This register is the **task-planning source of truth** for StackKits. Items are updated when debt is added, resolved, or re-prioritized. Reference it alongside the [Roadmap](docs/ROADMAP.md).*
