# Phase 0: Preparations & Baseline Metrics

> **Purpose:** Establish quantitative baseline before cleanup to measure success.  
> **Philosophy:** "What gets measured gets managed." — Peter Drucker

---

## 1. Pre-Cleanup Audit Checklist

Before starting any cleanup operation, complete these preparation steps:

### 1.1 Create Safety Net

```bash
# Tag current state for rollback capability
git tag pre-cleanup -m "Snapshot before PSCP cleanup"
git push origin --tags

# Verify tests pass before changes
make test        # or: go test ./...
make lint        # or: golangci-lint run ./...
```

### 1.2 Gather Baseline Metrics

Collect baseline KPIs that will measure cleanup success. Prefer cross-platform tools.

Recommended (cross-platform):

```bash
# LOC + file counts by language
tokei

# Alternative LOC tool
cloc .

# Top 20 largest tracked text files (approx)
git ls-files | python - <<'PY'
import os, sys
paths = [p.strip() for p in sys.stdin if p.strip()]
text_ext = {'.go','.ts','.tsx','.js','.py','.java','.kt','.rs','.c','.cpp','.h','.md','.cue','.yaml','.yml','.json','.toml','.tf','.tmpl'}
rows = []
for p in paths:
   _, ext = os.path.splitext(p.lower())
   if ext not in text_ext:
      continue
   try:
      with open(p, 'rb') as f:
         data = f.read()
      # crude binary filter
      if b'\x00' in data[:4096]:
         continue
      loc = data.count(b'\n') + 1
      rows.append((loc, p))
   except OSError:
      pass
rows.sort(reverse=True)
for loc, p in rows[:20]:
   print(f"{loc:6d} {p}")
PY

# Diff summary after cleanup
git diff --stat
```

---

## 2. Repository Statistics Template

Document these metrics **before** and **after** cleanup:

### 2.1 File Inventory

| Category | Extension | Count | LOC | Notes |
|----------|-----------|-------|-----|-------|
| **Logic** | `.go` | ___ | ___ | Core business logic |
| **Schema** | `.cue` | ___ | ___ | Configuration validation |
| **Docs** | `.md` | ___ | ___ | Documentation |
| **Templates** | `.tf/.tmpl` | ___ | ___ | IaC templates |
| **Frontend** | `.tsx/.ts` | ___ | ___ | UI components |

### 2.2 Code Quality Baseline

```bash
# Cyclomatic complexity
gocyclo ./internal ./cmd ./pkg

# Test coverage
go test -cover ./...

# Linting results
golangci-lint run ./... --sort-results | wc -l
```

---

## 3. Success Criteria

Define what "done" looks like:

- [ ] All L0 (Scaffolding) files deleted or promoted to L1+
- [ ] All L1 (Draft) files have open tickets or are promoted
- [ ] Test coverage ≥ 80% for critical paths
- [ ] Zero broken links in documentation
- [ ] CI/CD pipeline fully green
- [ ] Metrics improved by X% (define threshold)

---

## 4. Stakeholder Communication

If working in a team:

```markdown
## Cleanup Initiative

**Scope:** [e.g., "Remove dead code + consolidate docs"]  
**Timeline:** [e.g., "2 weeks"]  
**Impact:** [e.g., "30% doc reduction, new test suite"]  
**Kickoff:** [date]  
**Next Phases:** Phase 1 (Feature Audit) → Phase 2 (Execution)  

**Questions?** See [Phase 0](0_preparations.md)
```

