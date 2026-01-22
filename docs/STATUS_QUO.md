# STATUS_QUO

> **Last Verified:** 2026-01-22  
> **Purpose:** Comprehensive audit of project assets with maturity assessment.  
> **Methodology:** Following PSCP (Project Standardization & Cleanup Protocol) from Cleanup-Plan.md

---

## Pointers

- Docs index: [README.md](README.md)
- Roadmap (milestones + backlog + gap analysis): [ROADMAP.md](ROADMAP.md)
- CLI reference: [CLI.md](CLI.md)

## Executive Summary

| Category | L0 (Scaffolding) | L1 (Draft) | L2 (Functional) | L3 (Production) |
|----------|------------------|------------|-----------------|-----------------|
| Documentation | 0 | 4 | 12 | 3 |
| Infrastructure | 0 | 2 | 6 | 2 |
| Pipeline/Tests | 0 | 2 | 2 | 1 |

**Overall Health:** 🟢 **Functional** - Core documentation solid, v1.0 foundation in place.

### Recent Cleanup (2026-01-22)
- ✅ Documentation consolidated under `docs/`
- ✅ CI/CD pipeline created
- ✅ CUE import errors fixed
- ✅ PaaS strategy implemented (Dokploy/Coolify)
- ✅ ROADMAP.md rewritten professionally
- ✅ German docs translated to English
- ✅ Cleanup methodology modularized into 5 phases (docs/cleanup/)
- ✅ docs/README.md navigation added
- ✅ Duplicate TARGET_STATE.md removed
- ✅ Canonical CLI reference restored as `docs/CLI.md`

---

## 1. Documentation Assets Audit

### 1.1 Canonical Documentation (docs/)

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [README.md](README.md) | **L3** ⭐ | Canonical docs index | **Preserve** |
| [CLI.md](CLI.md) | **L3** ⭐ | Implementation-aligned CLI reference | **Preserve** |
| [ARCHITECTURE.md](ARCHITECTURE.md) | **L2** 🟢 | System design | **Maintain** |
| [STATUS_QUO.md](STATUS_QUO.md) | **L2** 🟢 | Current state audit and known gaps | **Maintain** |
| [TARGET_STATE.md](TARGET_STATE.md) | **L3** ⭐ | Product vision and functional requirements | **Preserve** |
| [ROADMAP.md](ROADMAP.md) | **L3** ⭐ | Milestones + backlog + gap analysis | **Preserve** |
| [CHANGELOG.md](CHANGELOG.md) | **L2** 🟢 | Release history (Keep a Changelog) | **Maintain** |
| [Cleanup-Plan.md](Cleanup-Plan.md) | **L2** 🟢 | Cleanup protocol (PSCP) | **Maintain** |
| [DEFAULT_SPECS_README.md](DEFAULT_SPECS_README.md) | **L2** 🟢 | Default specs overview | **Maintain** |
| [../README.md](../README.md) | **L2** 🟢 | Repository entrypoint (links into docs) | **Maintain** |

### 1.2 ADR (Architectural Decision Records)

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [ADR-0001](../ADR/ADR-0001-documentation-standard.md) | **L2** 🟢 | Documentation standard | **Maintain** |
| [ADR-0002](../ADR/ADR-0002-docker-first-v1.md) | **L2** 🟢 | Docker-first strategy | **Maintain** |
| [ADR-0003](../ADR/ADR-0003-paas-strategy.md) | **L2** 🟢 | PaaS strategy | **Maintain** |

### 1.3 /docs/ Topic Guides

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [creating-stackkits.md](creating-stackkits.md) | **L1** 🟡 | Authoring guide; verify against current implementation | **Refactor** |
| [stack-spec-reference.md](stack-spec-reference.md) | **L2** 🟢 | Stack spec schema reference | **Maintain** |
| [templates.md](templates.md) | **L2** 🟢 | Templates guide | **Maintain** |
| [variants.md](variants.md) | **L2** 🟢 | Variants guide | **Maintain** |
| [NETWORKING_STANDARDS.md](NETWORKING_STANDARDS.md) | **L2** 🟢 | Networking conventions (local-first) | **Maintain** |

### 1.4 StackKit-Specific Documentation

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [base-homelab/README.md](../base-homelab/README.md) | **L2** 🟢 | Practical quick-start with variants | **Maintain** |
| [modern-homelab/README.md](../modern-homelab/README.md) | **L1** 🟡 | Scaffolding v0.1.0-alpha | **Refactor** |
| [ha-homelab/README.md](../ha-homelab/README.md) | **L1** 🟡 | Scaffolding planned | **Refactor** |

---

## 2. Infrastructure Assets Audit

### 2.1 Makefiles and Build

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [Makefile](../Makefile) | **L2** 🟢 | Comprehensive build targets (build, test, lint, coverage) | **Maintain** |
| [go.mod](../go.mod) | **L3** ⭐ | Standard Go module definition | **Preserve** |

### 2.2 Dockerfiles and Compose

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [marketing/Dockerfile](../marketing/Dockerfile) | **L3** ⭐ | Multi-stage build, production-ready nginx | **Preserve** |
| [marketing/docker-compose.yml](../marketing/docker-compose.yml) | **L2** 🟢 | Health checks, proper networking | **Maintain** |
| [website/Dockerfile](../website/Dockerfile) | **L2** 🟢 | Multi-stage build, similar to marketing | **Maintain** |
| [website/docker-compose.yml](../website/docker-compose.yml) | **L1** 🟡 | Uses deprecated version key | **Refactor** - remove version, add health checks |

### 2.3 StackKit Templates (IaC)

| Path | Maturity | Assessment | Action |
|------|----------|------------|--------|
| base-homelab/templates/simple/ | **L2** Green | Static main.tf exists (~800 lines), detailed but not CUE-generated | **Maintain** - bridge to CUE later |
| base-homelab/templates/advanced/ | **L0** Red | Directory exists, Terramate structure placeholder | **Implement** |
| modern-homelab/templates/ | **L0** Red | Structure only, no implementation | **Implement** |
| ha-homelab/templates/ | **L0** Red | Structure only, no implementation | **Implement** |

### 2.4 CUE Schemas

| Path | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [base/stackkit.cue](../base/stackkit.cue) | **L2** 🟢 | Comprehensive BaseStackKit schema | **Maintain** |
| [base/network.cue](../base/network.cue) | **L2** 🟢 | Network defaults and DNS config | **Maintain** |
| [base/security.cue](../base/security.cue) | **L2** 🟢 | SSH hardening, firewall, TLS schemas | **Maintain** |
| [base/system.cue](../base/system.cue) | **L2** 🟢 | System config and packages | **Maintain** |
| [base-homelab/*.cue](../base-homelab/) | **L2** 🟢 | stackfile.cue, services.cue, defaults.cue present | **Maintain** |
| modern-homelab/*.cue | **L1** Yellow | Basic structure, needs completion | **Refactor** |
| ha-homelab/*.cue | **L0** Red | Only services.cue, minimal content | **Implement** |

### 2.5 Web Projects

| Path | Maturity | Assessment | Action |
|------|----------|------------|--------|
| marketing/ | **L2** Green | Complete Vite+React+Tailwind project with Docker | **Maintain** |
| website/ | **L1** Yellow | Boilerplate README (Vite template), lacks project-specific docs | **Refactor** - add proper README |

---

## 3. Pipeline and Test Assets Audit

### 3.1 CI/CD Configuration

| File | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [.github/workflows/ci.yml](../.github/workflows/ci.yml) | **L2** 🟢 | CI pipeline (lint/test/build) | **Maintain** |

### 3.2 Test Infrastructure

| Path | Maturity | Assessment | Action |
|------|----------|------------|--------|
| [tests/run_validation.sh](../tests/run_validation.sh) | **L2** 🟢 | CUE validation runner | **Maintain** |
| [tests/validation_test.cue](../tests/validation_test.cue) | **L2** 🟢 | Layer validation tests | **Maintain** |
| [tests/integration/cli_test.go](../tests/integration/cli_test.go) | **L1** 🟡 | Basic CLI integration tests | **Refactor** - expand coverage |
| [tests/e2e/run_e2e.sh](../tests/e2e/run_e2e.sh) | **L1** 🟡 | E2E framework (manual VM) | **Refactor** - add CI-compatible mode |
| tests/unit/ | **L0** Red | **EMPTY** - No unit tests | **Implement** - priority for internal/ packages |

---

## 4. Archive Policy

This repo does not rely on an in-repo `_archive/` folder. If you need to retain historical material, use Git history (or an external archive repo).

---

## 5. Critical Gaps Analysis

### 5.1 Implementation vs. Documentation Gap

| Documented Feature | Implementation Status |
|--------------------|----------------------|
| CUE to Tofu code generation | 🟢 **Implemented** - bridge.go generates tfvars from CUE |
| Terramate advanced mode | 🔴 **Not Implemented** - code exists but not wired |
| Network standard enforcement | 🔴 **Not Implemented** - schemas exist, no enforcement |
| Multi-OS variants | 🟢 **Implemented** - ubuntu-24, ubuntu-22, debian-12 |
| Service variants | 🟢 **Implemented** - default, coolify, beszel, minimal |
| Drift detection | 🟡 **Partial** - Go code exists, not in main workflow |

### 5.2 Missing Critical Infrastructure

1. **No CI/CD Pipeline** - No GitHub Actions for automated testing
2. **No Unit Tests** - tests/unit/ is empty
3. **No Coverage Reports** - Makefile has target but no baseline
4. **No Release Automation** - Manual versioning

### 5.3 Duplicate/Conflicting Assets

| Issue | Files | Resolution |
|-------|-------|------------|
| Two web projects | marketing/, website/ | **Clarify purpose** - consolidate or differentiate |
| German + English docs | DEFAULT_SPECS_README.md | **Translate** - standardize on English |

---

## 6. Core Codebase Status (CLI)

The stackkit CLI is functional as a basic wrapper but lacks deep integration logic.

| Feature | Status | Reality Check |
|---------|--------|---------------|
| **Language** | Go 1.22 | |
| **Command: init** | Implemented | Works for creating directory structure |
| **Command: prepare** | Partial | Installs tools but lacks OS-level validation |
| **Command: plan** | Partial | Wraps tofu plan, Terramate not fully wired |
| **Command: apply** | Partial | Wraps tofu apply. No automated rollback |
| **Command: validate** | Partial | Validates CUE syntax only |
| **Code Generation** | Missing | No CUE to Terraform generation |

---

## 7. StackKits Implementation Status

| StackKit | Status | Infrastructure | Logic/Automation |
|----------|--------|----------------|------------------|
| **base-homelab** | Static Template | main.tf exists (~800 lines) | No CUE generation |
| **modern-homelab** | Scaffolding | Folder structure only | None |
| **ha-homelab** | Scaffolding | Metadata only | None |

---

## 8. Technology Integration Status

| Technology | Status | Notes |
|------------|--------|-------|
| **CUE** | Schema Only | Schemas exist, no enforcement |
| **OpenTofu** | Integrated | Basic execution works |
| **Terramate** | Code Exists | Not wired into main workflow |
| **Docker** | Integrated | Simple mode works correctly |

---

## 9. Maturity Definitions Reference

| Level | Status | Definition | Action Required |
|-------|--------|------------|-----------------|
| **L0** | Red Scaffolding | Placeholder, empty, or describes unimplemented features | Delete or Implement |
| **L1** | Yellow Draft | Incomplete, outdated, or partially implemented | Refactor |
| **L2** | Green Functional | Works reliably, basic documentation exists | Maintain |
| **L3** | Star Production | Fully tested, comprehensive docs, security hardened | Preserve |

---

## 10. Recommended Priority Actions

### Immediate (Week 1-2)
1. [x] ✅ Create GitHub Actions CI pipeline (lint, test, build) - **DONE 2026-01-22**
2. [x] ✅ Add unit tests for internal/ packages - **DONE 2026-01-22** (initial structure)
3. [x] ✅ Remove archive dependencies from canonical docs - **DONE 2026-01-22**
4. [x] ✅ Fix broken CUE imports (validation_test.cue, modern-homelab/stackkit.cue) - **DONE 2026-01-22**
5. [x] ✅ Consolidate gap analysis + backlog into ROADMAP.md - **DONE 2026-01-22**

### Short-term (Week 3-4)
6. [ ] Keep CLI.md aligned with actual CLI implementation
7. [ ] Consolidate or differentiate marketing/ vs website/
8. [ ] Translate DEFAULT_SPECS_README.md to English
9. [ ] Decide modern-homelab platform (Docker+Coolify recommended)

### Medium-term (Month 2)
10. [ ] Implement CUE to Tofu bridge (Layout Engine)
11. [ ] Wire Terramate advanced mode into CLI
12. [ ] Complete modern-homelab templates

---

## 11. Cleanup Notes

Changelog-level changes should be recorded in [CHANGELOG.md](CHANGELOG.md). This status report intentionally does not enumerate archived file paths.
