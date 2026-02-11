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

### TD-27: API Arbitrary Filesystem Write (C1)

**Location:** `internal/api/handlers.go` L449 (`handleGenerateTFVars`)  
**Problem:** `outputDir` field in the request body lets a client specify an arbitrary server path. The handler writes files to that path without restriction.  
**Impact:** Path write vulnerability — any external caller can write to arbitrary server filesystem locations.  
**Fix:** Remove `outputDir` from API requests (always use temp dir + return content), or restrict to a sandboxed directory.  
**Milestone:** M1
**Task:** StackKits-l3s.1

### TD-28: No API Authentication (C2)

**Location:** `internal/api/server.go` (middleware chain)  
**Problem:** No API key, JWT, or any auth middleware. CORS headers reference `X-API-Key`, `X-User-ID`, `X-Org-ID` but these are never validated.  
**Impact:** Anyone can call all API endpoints if the server is exposed beyond localhost.  
**Fix:** Add API-key or JWT validation middleware. Support `X-API-Key` header validation for Kong Gateway integration.  
**Milestone:** M1
**Task:** StackKits-l3s.2

### TD-29: OpenAPI Compute Tier Enum Mismatch (C3)

**Location:** `api/openapi/stackkits-v1.yaml` — `ComputeSpec.tier`  
**Problem:** OpenAPI spec says `[minimal, standard, performance]` but Go code (fixed in TD-04) validates `[low, standard, high]`. The spec was not updated when TD-04 was resolved.  
**Impact:** API clients using the OpenAPI spec will send invalid enum values.  
**Fix:** Update OpenAPI spec to `[low, standard, high]` to match Go code and CUE schemas.  
**Milestone:** M1
**Task:** StackKits-l3s.3

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

### TD-30: CLI generate Does Not Use Template Renderer (I5)

**Location:** `cmd/stackkit/commands/generate.go` L128  
**Problem:** `copyOrRenderTemplates` calls `copyFile` instead of using `internal/template/Renderer`. Templates are copied verbatim rather than rendered with variable substitution.  
**Impact:** Generated output contains template placeholders instead of actual values.  
**Fix:** Wire the existing `template.Renderer` into the generate command. Related to TD-10.  
**Milestone:** M1
**Task:** StackKits-l3s.8

### TD-31: iac and terramate Packages Are Dead Code (I6)

**Location:** `internal/iac/executor.go` (~380 lines), `internal/terramate/executor.go` (~459 lines)  
**Problem:** CLI commands directly use `internal/tofu/`. The unified `iac.Executor` interface and Terramate wrapper are built and tested (~475 lines of tests) but never used.  
**Impact:** ~840 lines of production code + tests are dead code. Terramate mode is unreachable from CLI.  
**Fix:** Wire `iac.Executor` into CLI commands. Support `--engine terramate` flag.  
**Milestone:** M6
**Task:** StackKits-l3s.9

### TD-32: internal/errors Package Mostly Unused (I8)

**Location:** `internal/errors/errors.go` (~271 lines)  
**Problem:** Rich error system with categories, severity, auto-fix suggestions, and structured context — but CLI commands and API handlers use plain `fmt.Errorf` everywhere.  
**Impact:** Poor error UX. Users get unstructured error messages. Auto-fix suggestions never shown.  
**Fix:** Adopt `internal/errors` across CLI and API. Replace `fmt.Errorf` with structured errors where user-facing.  
**Milestone:** M3
**Task:** StackKits-l3s.11

### TD-11: Headscale Port Conflict (W9)

**Location:** `modern-homelab/services.cue`  
**Problem:** Headscale binds host port 443, Traefik also binds port 443.  
**Impact:** Services cannot co-exist on the same node.  
**Fix:** Headscale uses alternate port or runs behind Traefik as upstream.  
**Milestone:** M3

---

## P2 — Medium Priority

### TD-33: No API Rate Limiting (I1)

**Location:** `internal/api/server.go`  
**Problem:** No rate limiting middleware. Generation endpoints are computationally expensive.  
**Fix:** Add configurable rate limiter (per-IP or per-API-key).  
**Milestone:** M1
**Task:** StackKits-l3s.4

### TD-34: Zero API Handler Test Coverage (I2)

**Location:** `internal/api/`  
**Problem:** No unit tests for handlers.go (~580 lines) or server.go (~190 lines). All 13 endpoints untested.  
**Fix:** Add httptest-based unit tests for every handler.  
**Milestone:** M1
**Task:** StackKits-l3s.5

### TD-35: Logging Middleware Missing Response Status (I3)

**Location:** `internal/api/server.go` L160  
**Problem:** `loggingMiddleware` doesn't wrap `http.ResponseWriter` so cannot capture HTTP status code in logs.  
**Fix:** Use a `statusResponseWriter` wrapper to capture status code and content length.  
**Milestone:** M1
**Task:** StackKits-l3s.6

### TD-36: CLI status --json Flag Not Implemented (I4)

**Location:** `cmd/stackkit/commands/status.go` L37  
**Problem:** `--json` flag is registered but JSON output path is not implemented.  
**Fix:** Add JSON output mode using same data as table output.  
**Milestone:** M3
**Task:** StackKits-l3s.7

### TD-37: CLI prepare Memory Check Missing (I7)

**Location:** `cmd/stackkit/commands/prepare.go` L262  
**Problem:** `checkLocalResources` reports "Memory: (check manually)" instead of actually checking available RAM.  
**Fix:** Use `runtime.MemStats` or read `/proc/meminfo` on Linux, `GlobalMemoryStatusEx` on Windows.  
**Milestone:** M3
**Task:** StackKits-l3s.10

### TD-38: Interactive init Is a Stub (I9)

**Location:** `cmd/stackkit/commands/init.go` L78-82  
**Problem:** Running `stackkit init` without arguments lists available StackKits and errors out. No interactive selection.  
**Fix:** Add bubbletea or promptui-based interactive wizard for StackKit, domain, email, compute tier.  
**Milestone:** M4
**Task:** StackKits-l3s.12

### TD-39: Hardcoded stackKitDirs in API Handler (I10)

**Location:** `internal/api/handlers.go` L81  
**Problem:** Hardcoded list of StackKit directories. Adding new StackKits requires code change.  
**Fix:** Auto-discover StackKit directories from filesystem via `stackkit.yaml` presence.  
**Milestone:** M3
**Task:** StackKits-l3s.13

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

### TD-40: CORS Wildcard Not Configurable (N1)

**Location:** `internal/api/server.go` CORS middleware  
**Problem:** CORS origin is hardcoded to `*`. Should be configurable for production.  
**Fix:** Add `--cors-origins` flag or env var.  
**Milestone:** M3
**Task:** StackKits-l3s.14

### TD-41: No Pagination on List Endpoints (N2)

**Location:** `internal/api/handlers.go` `handleListStackKits`  
**Problem:** Returns all StackKits in single response. Not an issue at 4 StackKits but won't scale.  
**Fix:** Add `?limit=` and `?offset=` query params.  
**Milestone:** M6
**Task:** StackKits-l3s.15

### TD-42: Deprecated strings.Title Usage (N5)

**Location:** `internal/template/renderer.go`  
**Problem:** Uses `strings.Title()` which is deprecated in Go 1.18+ (doesn't handle Unicode correctly).  
**Fix:** Replace with `cases.Title(language.English).String()` from `golang.org/x/text`.  
**Milestone:** M3
**Task:** StackKits-l3s.18

### TD-43: No Shell Completion Command (N6)

**Location:** `cmd/stackkit/commands/root.go`  
**Problem:** No `completion` subcommand. Cobra supports `GenBashCompletion`, `GenZshCompletion`, `GenFishCompletion` etc.  
**Fix:** Add `stackkit completion bash|zsh|fish|powershell` command.  
**Milestone:** M4
**Task:** StackKits-l3s.19

### TD-44: tfvars Format Inconsistency (N7)

**Location:** CLI `generate` writes HCL `.tfvars`, API writes JSON `.tfvars.json`  
**Problem:** Two different output formats for the same logical output.  
**Fix:** Standardize on JSON `.tfvars.json` (OpenTofu supports both) or support both with a flag.  
**Milestone:** M3
**Task:** StackKits-l3s.20

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
