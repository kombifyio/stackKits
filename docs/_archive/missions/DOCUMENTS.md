# Document Standard

Each module in the missions structure follows a standard set of documents.

---

## Core Documents (Required)

| Document | Purpose |
|----------|---------|
| CONTRACT.md | What this module delivers (natural language) |
| CONTRACT.yaml | Machine-readable contract for tooling |

---

## Planning Documents (As Needed)

| Document | Purpose |
|----------|---------|
| PLAN.md | Brainstorming, roadmap, improvements |
| REVIEW.md | Current state assessment, gaps |

---

## Technical Documents (As Needed)

| Document | Purpose |
|----------|---------|
| VALIDATION.md | Validation rules, constraints, decision logic (CUE schemas) |
| AUTOMATION.md | Automation processes, data structures, integrations |
| TESTING.md | Testing strategy, test categories, acceptance criteria |

---

## Reference Documents (As Needed)

| Document | Purpose |
|----------|---------|
| DEFINITION.md | Detailed specification (when CONTRACT is not enough) |
| BEST-PRACTICES.md | Patterns, anti-patterns, lessons learned |

---

## Testing Standards

All StackKits must implement comprehensive testing. See [TESTING-STANDARDS.md](./TESTING-STANDARDS.md) for details.

### Test Categories

| Category | Scope | When Run |
|----------|-------|----------|
| **Unit Tests** | Individual functions, CUE validation | Every commit |
| **Integration Tests** | Component interactions, template generation | PR merge |
| **E2E Tests** | Full deployment cycle | Release candidates |
| **Validation Tests** | CUE schema conformance | Every commit |

### Test File Naming

```
tests/
├── unit/
│   └── {component}_test.go
├── integration/
│   └── {workflow}_test.go
├── e2e/
│   └── {stackkit}_e2e_test.go
└── validation/
    └── {schema}_test.cue
```

---

## Layer-Specific Documents

### Layer 1: Foundation
Focuses on patterns that apply everywhere.
- VALIDATION.md is critical (defines all schema rules)
- AUTOMATION.md defines lifecycle patterns
- TESTING.md defines universal test patterns

### Layer 2: Platform
Focuses on runtime specifics.
- VALIDATION.md covers platform constraints
- Templates and examples are important
- TESTING.md covers platform-specific tests

### Layer 3: StackKits
Focuses on complete deployable stacks.
- All document types may apply
- PLAN.md and REVIEW.md drive iteration
- TESTING.md defines acceptance tests

---

## Document Maturity Levels

| Level | Description | Required Documents |
|-------|-------------|-------------------|
| **Draft** | Initial planning | CONTRACT.md |
| **Alpha** | Active development | CONTRACT.md, CONTRACT.yaml, VALIDATION.md |
| **Beta** | Feature complete, testing | All above + TESTING.md |
| **Stable** | Production ready | All above + BEST-PRACTICES.md |

---

## StackKit Classification

All StackKits are professional-grade. Classification is by **architecture**, not skill level:

| Classification | Architecture | Example |
|----------------|--------------|---------|
| **Single-Server** | 1 node, local-only or single domain | base-homelab |
| **Multi-Server** | 2-5 nodes, hybrid local/cloud | modern-homelab |
| **High-Availability** | 3+ nodes, redundancy, failover | ha-homelab |

---

## Cross-References

- [TESTING-STANDARDS.md](./TESTING-STANDARDS.md) - Comprehensive testing guide
- [Layer 1: Foundation](./layer-1-foundation/README.md) - Base patterns
- [Layer 2: Platform](./layer-2-platform/README.md) - Runtime specifics
- [Layer 3: StackKits](./layer-3-stackkits/README.md) - Deployable stacks
