# Project Standardization & Cleanup Protocol (PSCP)

> **Version:** 2.1  
> **Status:** Active

A concise methodology for codebase cleanup and standardization.

---

## 🏗️ Phase 1: The Deep Discovery (Audit)

**Objective:** Establish absolute visibility. We cannot clean what we do not measure.

### 1.1. The Asset Taxonomy

Create a living inventory (`STATUS_QUO.md`) categorized by asset type. Do not just list files; categorizes them:

- **Logic Assets:** Source code, scripts, libraries.
- **Infrastructure Assets:** Terraform, Dockerfiles, Kubernetes manifests.
- **Documentation Assets:** READMEs, Wikis, Architecture decision records.
- **Pipeline Assets:** CI/CD configurations, Build scripts, Linters.

### 1.2. The Maturity Assessment

Assign a **Maturity Level (L0-L3)** to every major component identified above.

| Level  |       Status       | Definition                                                                  | Action Required          |
| :----: | :----------------: | --------------------------------------------------------------------------- | ------------------------ |
| **L0** | 🔴 **Scaffolding** | Files exist but contain no logic. Placeholders. Dead code.                  | **Delete or Implement.** |
| **L1** |    🟡 **Draft**    | "Happy path" implementation. No error handling. Hardcoded values. No tests. | **Refactor.**            |
| **L2** | 🟢 **Functional**  | Works reliably. Configurable. Basic documentation exists.                   | **Standardize.**         |
| **L3** | 🌟 **Production**  | Fully tested. CI/CD integrated. Comprehensive docs. Security hardened.      | **Preserve.**            |

### 1.3. The Dependency Audit

- **External Deps:** List all libraries/tools. Identify deprecated versions or security risks (CVEs).
- **Internal Deps:** Map the dependency graph. Identify circular dependencies or "Spaghetti Code".

---

## 📐 Phase 2: The Standardization Framework (Definition)

**Objective:** Define the rules of the game before playing.

### 2.1. Directory Structure Standard

Enforce a "Place for Everything".

- `/cmd` or `/app`: Entry points.
- `/internal` or `/src`: Private application logic.
- `/pkg` or `/lib`: Publicly reusable libraries.
- `/docs`: Documentation (Architecture, Standards).
- `/deploy` or `/infrastructure`: IaC and container definitions.

### 2.2. Documentation Standard (Diátaxis Framework)

Documentation must be structured by **function**, not just existence.

1.  **Tutorials:** "Learning-oriented" steps for beginners. (e.g., _Getting Started_)
2.  **How-To Guides:** "Problem-oriented" recipes. (e.g., _How to add a new API endpoint_)
3.  **Reference:** "Information-oriented" specs. (e.g., _API Swagger, Class Docs_)
4.  **Explanation:** "Understanding-oriented" background. (e.g., _Architecture Overview, ADRs_)

### 2.3. The Architectural Decision Record (ADR)

**Rule:** No major architectural change happens without a written decision.

- **Location:** `/ADR/`
- **Format:** `ADR-0000-title-of-decision.md`
- **Content:** Status, Context, Decision, Consequences (Positive & Negative).

---

## 🔭 Phase 3: Architecture Alignment (Convergence)

**Objective:** Bridge the gap between Reality (Phase 1) and Vision (Target State).

### 3.1. Gap Analysis

Maintain a gap analysis to map the delta (Vision vs Reality).

- **Canonical location:** `docs/ROADMAP.md` (Gap Analysis + backlog)

- **Missing Features:** Required by Vision but absent in Reality.
- **Zombie Features:** Present in Reality but absent in Vision. (Candidate for deletion).
- **Architectural Violations:** Code correctly implementing a feature but in the wrong way (e.g., "Hardcoded IP" vs "Dynamic Discovery").

### 3.2. Remediation Strategy

For every gap, assign a strategy:

- **Refactor:** Rewrite in place to meet standards.
- **Replatform:** Replace underlying technology (e.g., K3s -> Docker Swarm).
- **Retire:** Remove the capability entirely.
- **Accept:** Document as "Technical Debt" and schedule for later.

---

## 🧹 Phase 4: Execution ( The Cleanup)

**Objective:** aggressive but safe reduction of entropy.

### 4.1. The "Delete First" Principle

Code that doesn't exist cannot contain bugs.

1.  **Backup:** Tag the repository before starting (`git tag pre-cleanup`).
2.  **Prune:** Delete L0 (Scaffolding) and Zombie features.
3.  **Archive (preferred):** Do not rely on an in-repo `_archive/` folder. Prefer Git history (or an external archive repo) for historical material.

### 4.2. Refactoring Protocol

1.  **Isolate:** decouple the component from its dependencies.
2.  **Test:** Write a regression test for the existing behavior (if possible).
3.  **Refactor:** Apply the standard.
4.  **Verify:** Ensure tests pass.

### 4.3. Deprecation Workflow

For public APIs or shared internal libraries:

1.  **Mark:** Add `@deprecated` annotation and log warnings.
2.  **Announce:** Communicate the timeline for removal in `CHANGELOG.md`.
3.  **Remove:** Delete in the next major version.

---

## ✅ Phase 5: Verification (The Quality Gate)

**Objective:** Ensure the cleanup is permanent.

### 5.1. Definition of Done

A component is only "Clean" when:

- [ ] It has a clear owner/purpose.
- [ ] It follows the Directory Standard.
- [ ] It has L2 (Functional) or L3 (Production) maturity.
- [ ] It is documented in `README.md` or `godoc`.

### 5.2. Automated Enforcement

Codify the rules into the pipeline.

- **Linting:** Enforce style guides (e.g., `golangci-lint`, `eslint`).
- **Structure Tests:** Script to verify file existence/location.
- **Dead Link Check:** Verify documentation links.

---

## 🚀 Appendix: The "Broken Windows" Policy

- **Zero Tolerance:** Do not leave "todo" comments without a tracker ticket.
- **Boy Scout Rule:** Always leave the file cleaner than you found it.
- **Stop the Line:** If a standard is unclear, pause and write an ADR. Do not guess.
