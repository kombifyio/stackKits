# Base Homelab v1 Mission (Archive)

> **Status:** ARCHIVED - Reference Only  
> **Created:** 2026-01-29  
> **Superseded By:** New 3-layer structure

---

## ⚠️ This folder is kept for reference

The planning documents here were the initial detailed planning for base-homelab.
They have been condensed and integrated into the new 3-layer mission structure:

- **Contracts** → `missions/layer-3-stackkits/base-homelab/CONTRACT.md`
- **Validation** → `missions/layer-1-foundation/base/VALIDATION.md` + `missions/layer-3-stackkits/base-homelab/VALIDATION.md`
- **Automation** → `missions/layer-1-foundation/base/AUTOMATION.md`
- **Plan/Review** → `missions/layer-3-stackkits/base-homelab/PLAN.md` + `REVIEW.md`

---

## 📋 Original Documents (Reference)

| Document | Purpose |
|----------|---------|
| [base-homelab-REVIEW.md](./base-homelab-REVIEW.md) | Detailed production readiness assessment |
| [base-homelab-PLAN.md](./base-homelab-PLAN.md) | Detailed brainstorming and roadmap |
| [base-homelab-DEFINITION.md](./base-homelab-DEFINITION.md) | Full specification (645 lines) |
| [base-homelab-VALIDATION.md](./base-homelab-VALIDATION.md) | Detailed validation rules (585 lines) |
| [base-homelab-AUTOMATION.md](./base-homelab-AUTOMATION.md) | Full automation spec with Prisma (980 lines) |
| [base-homelab-BEST-PRACTICES.md](./base-homelab-BEST-PRACTICES.md) | Tools, patterns, lessons |

These contain more detail than the new condensed versions and may be useful for deep dives.

---

## 🎯 Original Mission Objectives

### Primary Goals

1. **Production Readiness** - Make base-homelab deployable in production
2. **Complete Documentation** - User guides, troubleshooting, reference
3. **Test Coverage** - Increase from <40% to >80%
4. **All Variants Working** - Test and validate all 4 variants

### Secondary Goals

1. **Automation Foundation** - Set up data structures for tool management
2. **Process Definition** - Define workflows for updates and changes
3. **Best Practices** - Document patterns for future StackKit development

---

## � Rollout Strategy

### Phase 1: dev-homelab MVP
1. Test CLI workflow with minimal StackKit (whoami only)
2. Validate integration with Kombify Administration
3. Prove contract compliance
4. Iterate quickly with minimal surface area

### Phase 2: base-homelab Full Implementation
1. Apply patterns validated in dev-homelab
2. Implement all services per CONTRACT.yaml
3. Test all 4 variants
4. Release v1.0.0

```
dev-homelab ──validates──> base-homelab-CONTRACT.yaml
                               │
                               ▼
                        base-homelab (full)
```

---

## �📊 Current Assessment

| Area | Score | Target |
|------|-------|--------|
| CUE Schemas | 85% | 95% |
| CLI Commands | 75% | 90% |
| Templates | 90% | 95% |
| Documentation | 80% | 95% |
| Testing | 40% | 80% |
| Overall | 🟡 74% | 🟢 90% |

---

## 🔑 Key Decisions Required

1. **Secret Management** - How to handle secrets in stack-spec.yaml?
2. **State Backend** - Local vs. remote state storage?
3. **Version Pinning** - Pin to tags or digests?
4. **Upgrade Path** - How to migrate between StackKit versions?

---

## 📅 Timeline

| Phase | Duration | Focus |
|-------|----------|-------|
| **Phase 1** | Week 1-2 | Fix gaps from REVIEW.md |
| **Phase 2** | Week 3-4 | Increase test coverage |
| **Phase 3** | Week 5-6 | Documentation & polish |
| **Phase 4** | Week 7 | Release candidate testing |
| **Release** | Week 8 | v1.0.0 stable |

---

## 🔗 Related Documents

- [../../ROADMAP.md](../../ROADMAP.md) - Overall project roadmap
- [../../TARGET_STATE.md](../../TARGET_STATE.md) - Product vision
- [../../STATUS_QUO.md](../../STATUS_QUO.md) - Current state audit
- [../../../base-homelab/README.md](../../../base-homelab/README.md) - StackKit documentation

---

## ✅ Document Workflow

```
PLAN.md                 DEFINITION.md              Code
(brainstorm)    ───▶    (golden template)    ───▶  (implementation)
     │                         │                         │
     │                         │                         │
     ▼                         ▼                         ▼
  Ideas              Approved specs              Working code
  Proposals          Canonical definitions       Tests pass
  Questions          Schema decisions            Deployed
```

**Rules:**
1. New ideas go in PLAN.md first
2. Approved changes update DEFINITION.md
3. Code follows DEFINITION.md
4. VALIDATION.md governs all validation logic
