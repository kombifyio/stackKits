# Phase 2: Cleanup Execution

> **Purpose:** Execute deletions, refactors, and standardization.  
> **Input:** Feature Audit Matrix (Phase 1)  
> **Output:** Cleaned codebase + changelog

---

## 1. The "Delete First" Principle

**Code that doesn't exist cannot contain bugs.**

### 1.1 Safe Deletion Protocol

```bash
# Step 1: Backup (you already did this in Phase 0 with git tag)
git tag pre-cleanup

# Step 2: Delete L0 items (one commit per category)
git rm -r _archive/old-proposal.md
git commit -m "Remove: deprecated proposal docs (L0)"

# Step 3: Verify tests still pass
make test

# Step 4: Push
git push origin main
```

### 1.2 What to Delete

- [ ] All L0 (Scaffolding) files
- [ ] Dead code branches (commented-out code, old implementations)
- [ ] Duplicate documentation
- [ ] Obsolete test fixtures
- [ ] Deprecated API implementations (mark with `@deprecated` first, wait 1 version, then delete)

### 1.3 What to Archive (Optional)

If material has **educational or historical value**, move to `_archive/`:

```bash
mkdir -p _archive
mv docs/old-architecture.md _archive/
git add _archive/
git commit -m "Archive: move old architecture doc to reference"
```

**Rule:** Do NOT rely on `_archive/` as a permanent home. Use git history instead.

---

## 2. Refactoring Protocol

For L1 (Draft) components that need improvement:

### 2.1 Isolate

Decouple the component from dependencies:

```bash
# Example: Separate CLI from core logic
git checkout -b refactor/cli-isolation
# ... move business logic to internal/cli/logic.go
```

### 2.2 Test

Write regression test for existing behavior (if possible):

```go
func TestCLIPlan_Backward_Compat(t *testing.T) {
    // Ensure old behavior is preserved during refactor
}
```

### 2.3 Refactor

Apply the standard:

```bash
# Apply linting fixes
golangci-lint run ./... --fix

# Apply documentation standard (Diátaxis)
# - Add Tutorial or How-To Guide
# - Add Reference section
```

### 2.4 Verify

```bash
make test
make lint
git diff --stat
```

---

## 3. Standardization Framework

### 3.1 Directory Structure Standard

Enforce "A Place for Everything":

```
project/
├── cmd/              # Entry points (CLI, servers)
├── internal/         # Private application logic
├── pkg/              # Public, reusable libraries
├── docs/             # Documentation (canonical)
│   ├── cleanup/      # Cleanup methodology (reusable)
│   └── ADR/          # Architectural Decision Records
└── tests/            # Test fixtures and integration
```

### 3.2 Documentation Standard (Diátaxis Framework)

Every document should fit one of these categories:

| Category | Purpose | Example |
|----------|---------|---------|
| **Tutorial** | Learning-oriented | "Getting Started with StackKits" |
| **How-To** | Problem-oriented | "How to add a new service to base-homelab" |
| **Reference** | Information-oriented | "CLI Command Reference", API docs |
| **Explanation** | Understanding-oriented | "Why we chose Docker over Kubernetes" |

Move docs to the right category or delete if it doesn't fit.

### 3.3 Architectural Decision Record (ADR)

**Rule:** No major architectural change happens without a written decision.

**Format:**
```markdown
# ADR-0000: Title of Decision

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Context
[Why was this decision needed?]

## Decision
[What did we decide?]

## Consequences
[Positive and Negative outcomes]
```

**Location:** `docs/ADR/ADR-0000-title.md`

---

## 4. Deprecation Workflow

For public APIs or widely-used internal components:

1. **Mark:** Add deprecation notice
   ```go
   // Deprecated: Use NewFooV2() instead. Will be removed in v2.0.
   func NewFoo() *Foo { ... }
   ```

2. **Announce:** Update CHANGELOG.md
   ```markdown
   ### Deprecated
   - `NewFoo()` → use `NewFooV2()` instead
   ```

3. **Remove:** Delete in next major version

---

## 5. Commit Message Template

Keep changes traceable:

```
type(scope): short description

- Deleted: L0 placeholder file X
- Refactored: Moved Y to internal/ to follow standards
- Added: Missing tests for Z

Related to: [Feature Audit Matrix row N]
Phase: Phase 2 (Cleanup Execution)
```

---

## 6. Change Log

Maintain a running log during Phase 2:

```markdown
## Phase 2 Changes (2026-01-22)

### Deleted
- `_archive/old-proposal.md` (L0 scaffolding)
- `docs/outdated-guide.md` (superseded by new guide)
- Dead imports in `internal/config/loader.go`

### Refactored
- `cmd/cli/plan.go` → extracted logic to `internal/cli/executor.go`
- `docs/` docs reorganized by Diátaxis framework

### Added
- `docs/ADR/ADR-0003-paas-strategy.md`
- Regression tests for legacy behavior
```

---

## 7. Quality Gates During Execution

```bash
# After each major deletion/refactor:

# 1. Tests must pass
make test

# 2. No broken links
grep -r "http" docs/ | grep -v "https://"

# 3. Coverage hasn't dropped
go test -cover ./... | grep coverage

# 4. Lint is clean
golangci-lint run ./...

# 5. Git history is clean
git log --oneline -10
```

---

## 8. Rollback Plan

If something breaks:

```bash
# Revert to pre-cleanup state
git reset --hard pre-cleanup
git push origin main --force-with-lease

# OR revert individual commits
git revert <commit-hash>
```

