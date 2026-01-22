# Phase 3: Verification & Quality Gates

> **Purpose:** Ensure the cleanup is permanent and sustainable.  
> **Input:** Cleaned codebase (Phase 2)  
> **Output:** Verification report + quality baseline

---

## 1. Definition of Done (Quality Checklist)

A component is only "Clean" when:

- [ ] **Clear Owner/Purpose:** Every file/package has a documented reason to exist
- [ ] **Follows Directory Standard:** In the right place according to project structure
- [ ] **L2+ Maturity:** Functional (L2) or Production (L3) quality
- [ ] **Documented:** Inline comments + README or godoc for public APIs
- [ ] **Tested:** At minimum, public interfaces have tests
- [ ] **Lints Clean:** No warnings from golangci-lint, eslint, etc.
- [ ] **No Broken Links:** All internal documentation references are valid

---

## 2. Automated Enforcement

Codify the rules into your CI/CD pipeline:

### 2.1 Linting

```bash
# Go
golangci-lint run ./... --deadline=5m

# TypeScript
eslint src/ --format=json

# Markdown
markdownlint docs/
```

### 2.2 Structure Tests

Script to verify file placement:

```bash
#!/bin/bash
# Verify no files in wrong places
[ -d "_archive" ] && echo "ERROR: _archive should not exist" && exit 1
[ -d "docs/legacy" ] && echo "ERROR: docs/legacy should not exist" && exit 1
echo "✓ Directory structure OK"
```

### 2.3 Link Verification

```bash
# Check all documentation links
find docs/ -name "*.md" -exec grep -l "\[.*\](.*)" {} \; | xargs -I {} \
  grep -o '\[.*\](\([^)]*\))' {} | sed 's/.*(\([^)]*\))/\1/' | \
  while read link; do
    if [[ $link =~ ^http ]]; then
      curl -s -o /dev/null -w "%{http_code}" "$link"
    else
      [ -f "$link" ] || echo "ERROR: Broken link: $link"
    fi
  done
```

### 2.4 Test Coverage

```bash
# Go
go test -cover ./... | grep -E "coverage.*%" | awk '{
  if ($NF < 80.0) {
    print "ERROR: Coverage below 80%"
    exit 1
  }
}'

# Fail if any package < 70%
go test ./... -coverprofile=coverage.out
go tool cover -func=coverage.out | awk '$3 < 70 {exit 1}'
```

### 2.5 Dead Code Detection

```bash
# Go
go install github.com/dominikh/go-tools/cmd/unused@latest
unused ./...

# JavaScript
npx depcheck
```

---

## 3. Post-Cleanup Metrics

Collect the same metrics as Phase 0, compare:

### 3.1 Quantitative Changes

```markdown
## Metrics Comparison

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| LOC (Go) | 12,450 | 11,890 | -4.5% ✅ |
| LOC (Docs) | 45,000 | 28,000 | -38% ✅ |
| Files (total) | 180 | 165 | -8% ✅ |
| Cyclomatic Complexity (avg) | 8.2 | 7.1 | -13% ✅ |
| Test Coverage | 62% | 78% | +16% ✅ |
| Linting Warnings | 47 | 0 | -100% ✅ |
| Broken Doc Links | 12 | 0 | -100% ✅ |
```

### 3.2 Qualitative Assessment

```markdown
## Qualitative Improvements

- ✅ Directory structure now consistent with standards
- ✅ New team members find docs easier to navigate
- ✅ Onboarding time reduced (estimated 2 days → 1 day)
- ✅ Test suite now easy to extend
- ✅ CI/CD pipeline validates automatically
```

---

## 4. Regression Testing

Run full test suite + integration tests:

```bash
# Unit tests
make test

# Integration tests (if applicable)
make test-integration

# E2E tests (if applicable)
make test-e2e

# Coverage report
make coverage
open coverage.html
```

### 4.1 Manual Verification Checklist

- [ ] CLI still works (`stackkit --help`)
- [ ] Example workflows still execute
- [ ] Documentation builds without errors
- [ ] All links in README.md resolve
- [ ] Docker builds succeed
- [ ] Terraform plans work (if applicable)

---

## 5. Known Issues & Technical Debt Log

Document remaining imperfections:

```markdown
## Remaining Technical Debt (v1.0)

| ID | Issue | Severity | Target |
|----|-------|----------|--------|
| TD-001 | Slow test suite (10m) | Low | v1.1 |
| TD-002 | Mock external APIs | Medium | v1.0 |
| TD-003 | Add performance benchmarks | Low | v1.2 |

(See docs/ROADMAP.md for full backlog)
```

---

## 6. Sign-Off

When all gates are green:

```markdown
## Phase 3 Sign-Off

- [ ] All automated checks pass (CI/CD green)
- [ ] Manual verification complete
- [ ] Metrics improved vs. baseline
- [ ] No regression bugs found
- [ ] Team review complete
- [ ] Code ready for release

**Verified by:** [name]  
**Date:** 2026-01-22  
**Status:** ✅ APPROVED
```

---

## 7. Post-Verification Actions

1. **Archive Phase 2 changelog:** Save as `docs/cleanup/changelog-2026-01-22.md`
2. **Tag release candidate:** `git tag v1.0.0-rc1`
3. **Notify team:** Share metrics + sign-off
4. **Proceed to Phase 4:** Production Readiness

