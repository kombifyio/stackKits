# Phase 1: Target Refinement & Feature Audit

> **Purpose:** Define what stays and what goes.  
> **Input:** Baseline metrics (Phase 0)  
> **Output:** Feature Audit Matrix + Gap Analysis

---

## 1. Feature Audit Matrix

Create a matrix to categorize **every** significant component in your codebase:

### Template

| Component | Type | Maturity | Vision | Reality | Gap | Decision |
|-----------|------|----------|--------|---------|-----|----------|
| `internal/config` | Package | L2 🟢 | Public API | Private impl | Small | Keep |
| `_archive/foo.md` | Doc | L0 🔴 | None | Dead | Large | Remove |
| `cmd/cli/plan.go` | Feature | L1 🟡 | Full workflow | Partial | Large | Refactor |

### Column Definitions

- **Type:** Package, Feature, Doc, Test, Tool, Infrastructure
- **Maturity:** L0 (Scaffolding), L1 (Draft), L2 (Functional), L3 (Production)
- **Vision:** What the target state should be (from TARGET_STATE.md or ROADMAP.md)
- **Reality:** What currently exists
- **Gap:** Small, Medium, Large
- **Decision:** Keep, Refactor, Deprecate, Remove

---

## 2. Maturity Assessment

Assign **Maturity Level (L0-L3)** to every component.

| Level  |       Status       | Definition                                                                  | Action Required          |
| :----: | :----------------: | --------------------------------------------------------------------------- | ------------------------ |
| **L0** | 🔴 **Scaffolding** | Files exist but contain no logic. Placeholders. Dead code.                  | **Delete or Implement.** |
| **L1** |    🟡 **Draft**    | "Happy path" implementation. No error handling. Hardcoded values. No tests. | **Refactor.**            |
| **L2** | 🟢 **Functional**  | Works reliably. Configurable. Basic documentation exists.                   | **Maintain.**            |
| **L3** | ⭐ **Production**  | Fully tested. CI/CD integrated. Comprehensive docs. Security hardened.      | **Preserve.**            |

---

## 3. Gap Analysis

For each **Medium** or **Large** gap, document:

1. **Why it exists:** (Rushed development, planned for later, wrong technology choice, etc.)
2. **Impact if fixed:** (User experience, performance, maintainability)
3. **Effort to fix:** (Low: 1 day, Medium: 1 week, High: > 1 week)
4. **Recommended path:** (Refactor, Deprecate, Remove, Accept as Technical Debt)

### Example

```markdown
### Gap: CUE to Terraform code generation

**Why:** Initially attempted dynamic generation; reverted to static templates.
**Impact:** Limits reusability; requires manual sync between CUE and Terraform.
**Effort:** High (5-7 days)
**Path:** Implement generator (`internal/cue/bridge.go`), integrate into CI
**Timeline:** v1.0 (high priority)
```

---

## 4. Archival vs. Deletion Decision

| Question | Archive | Delete |
|----------|---------|--------|
| Will this be referenced later? | ✅ | ❌ |
| Is it historical/educational? | ✅ | ❌ |
| Is it completely obsolete? | ❌ | ✅ |
| Do I need to restore it? | ✅ | ❌ |

**Best Practice:** Use `_archive/` for **rarely** referenced material. Prefer git history for everything else.

---

## 5. Stakeholder Review

Before Phase 2, share the Feature Audit Matrix with team leads:

- [ ] All L0 items flagged for deletion?
- [ ] All L1 items have owners/tickets?
- [ ] Gap analysis makes sense?
- [ ] Timeline and effort estimates realistic?

---

## 6. Output Artifact

Save your decisions as `docs/cleanup/audit-matrix-[date].csv`:

```csv
Component,Type,Maturity,Decision,Owner,Deadline
internal/config,Package,L2,Keep,alice,2026-02-01
_archive/old.md,Doc,L0,Delete,bob,2026-01-30
cmd/cli/plan.go,Feature,L1,Refactor,charlie,2026-02-15
```

This becomes the "source of truth" for Phase 2 execution.
