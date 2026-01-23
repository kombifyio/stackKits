# Cleanup Methodology

> **Version:** 2.0  
> **Purpose:** A systematic approach to transform any codebase into a clean, maintainable, production-ready state.

---

## Overview

This folder contains a five-phase methodology for codebase cleanup and standardization:

| Phase | Document | Purpose |
|-------|----------|---------|
| **0** | [Preparations](0_preparations.md) | Baseline metrics, audit framework, success criteria |
| **1** | [Target Refinement](1_target_refinement.md) | Feature audit, categorization matrix |
| **2** | [Cleanup Execution](2_cleanup_execution.md) | Deletion protocols, refactoring guides |
| **3** | [Verification](3_refactor_verification.md) | Quality gates, regression testing |
| **4** | [Production Readiness](4_production_readiness.md) | Release preparation, operational checklist |

---

## Quick Start

### For a Full Cleanup

1. **Read Phase 0** — Gather baseline metrics
2. **Complete Phase 1** — Create Feature Audit Matrix
3. **Execute Phase 2** — Delete and refactor
4. **Verify Phase 3** — Run quality gates
5. **Prepare Phase 4** — Ready for production

### For Targeted Cleanup

- Just deleting dead code? → Start at Phase 2
- Just verifying quality? → Start at Phase 3
- Preparing a release? → Start at Phase 4

---

## Core Principles

1. **Measure First** — Cannot improve what you don't measure
2. **Delete Before Refactor** — Code that doesn't exist can't have bugs
3. **Automate Quality** — CI/CD should enforce standards
4. **Document Decisions** — Future you will thank present you

---

## When to Use This Methodology

| Scenario | Start Phase |
|----------|-------------|
| New project audit | Phase 0 |
| Legacy codebase cleanup | Phase 0 |
| Pre-release quality check | Phase 3 |
| Quarterly maintenance | Phase 1 (quick audit) |
| Security remediation | Phase 3 (security gates) |

---

## Relationship to Other Docs

This framework is designed to plug into any project's existing documentation structure.

Recommended minimal "core docs" to keep cleanup work traceable:

- **Baseline** (Phase 0): `cleanup-baseline.yaml` or equivalent
- **Target definition** (Phase 1): short "keep/remove" feature scope + decision log
- **Change log** (Phase 2): list of removed/refactored items and why
- **Verification report** (Phase 3): commands run, results, and remaining risks
- **Production checklist** (Phase 4): release readiness gates
