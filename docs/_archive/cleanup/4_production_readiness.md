# Phase 4: Production Readiness

> **Purpose:** Prepare for release and sustained maintenance.  
> **Input:** Verified codebase (Phase 3)  
> **Output:** Release checklist + operational procedures

---

## 1. Pre-Release Checklist

### 1.1 Code Quality

- [ ] All tests pass locally (`make test`)
- [ ] CI/CD pipeline fully green
- [ ] Test coverage ≥ 80% (or your threshold)
- [ ] Zero security vulnerabilities (`go list -json -m all | nancy sleuth`)
- [ ] Dependencies up-to-date and compatible
- [ ] No deprecated language features
- [ ] No hardcoded secrets or credentials

### 1.2 Documentation

- [ ] README.md is current and accurate
- [ ] CHANGELOG.md has full entry for this release
- [ ] All public APIs documented
- [ ] Examples run without modification
- [ ] Architecture docs reflect actual implementation
- [ ] All links in docs are valid
- [ ] Installation instructions are tested

### 1.3 Deployment

- [ ] Docker builds succeed
- [ ] Terraform/IaC configurations validated
- [ ] No breaking changes without deprecation period
- [ ] Migration guide provided (if applicable)
- [ ] Rollback procedure documented

### 1.4 Operational

- [ ] Logging/observability in place
- [ ] Error handling is user-friendly
- [ ] Performance baseline established
- [ ] Monitoring/alerting configured
- [ ] On-call runbook prepared

---

## 2. Release Versioning

Follow [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH[-prerelease][+build]

Example: v1.2.3-rc1+build.2026.01.22
```

### 2.1 Release Types

| Version | Timing | Contains | Example |
|---------|--------|----------|---------|
| **Patch** | Every 1-2 weeks | Bug fixes only | v1.0.1 |
| **Minor** | Every 1-2 months | Features + bug fixes | v1.1.0 |
| **Major** | Every 6+ months | Breaking changes | v2.0.0 |

---

## 3. Release Procedures

### 3.1 Tag Release

```bash
# Create annotated tag (preferred)
git tag -a v1.0.0 -m "Release v1.0.0: Initial stable release"

# Sign tag (recommended for production)
git tag -s v1.0.0 -m "Release v1.0.0 (signed)"

# Push tag
git push origin v1.0.0
```

### 3.2 Update CHANGELOG

```markdown
## [1.0.0] - 2026-01-22

### Added
- CUE to Terraform bridge for dynamic code generation
- Variant system (default, coolify, beszel, minimal)
- CLI commands: init, validate, plan, apply, destroy

### Fixed
- Import errors in CUE schemas
- Documentation links

### Removed
- Deprecated _archive/ folder structure
```

### 3.3 Release Announcement

```markdown
# StackKits v1.0.0 Released 🎉

**Key Features:**
- Single-server base-homelab deployment
- 4 service variants (Dokploy, Coolify, Beszel, minimal)
- CUE schema validation before Terraform

**Breaking Changes:** None (first stable release)

**Installation:**
```
stackkit init --stackkit base-homelab
```

**Documentation:** [Link to docs]
**Download:** [Link to releases]
```

---

## 4. Post-Release Procedures

### 4.1 Monitor & Support

```bash
# Monitor for reported issues
# Channel: GitHub Issues, Slack, email

# Typical response time: SLA
# - Critical (broken in production): < 4 hours
# - Major (feature not working): < 1 day
# - Minor (edge case, workaround exists): < 1 week
```

### 4.2 Patch Releases

```bash
# Hotfix workflow
git checkout -b hotfix/v1.0.1
# ... fix the issue
git commit -m "Fix: [description]"
git tag v1.0.1
git push origin v1.0.1
```

---

## 5. Ongoing Maintenance

### 5.1 Weekly Cadence

```markdown
## Monday (Planning)
- Review open issues + PRs
- Plan week's work
- Check dependency security advisories

## Wednesday (Review)
- Code review sprint
- Test complex PRs locally
- Update documentation

## Friday (Release Prep)
- Finalize week's changes
- Run full test suite
- Tag release candidate if ready
```

### 5.2 Monthly Cadence

```markdown
## End of Month
- Tag patch or minor release
- Create release announcement
- Update ROADMAP.md with progress
- Review metrics (coverage, performance)
- Plan next sprint
```

### 5.3 Quarterly Review

```markdown
## Each Quarter
- Run Phase 1 (Feature Audit) to identify debt
- Assess if Phase 2 (Cleanup) is needed
- Update ROADMAP with major milestones
- Solicit user feedback
- Plan architectural changes (via ADRs)
```

---

## 6. Sustained Quality

### 6.1 Automated Enforcement

Ensure cleanup doesn't regress:

```bash
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: check-yaml
      - id: check-merge-conflict
      - id: trailing-whitespace
      - id: end-of-file-fixer
```

### 6.2 Code Ownership

Assign owners to critical paths:

```
# CODEOWNERS
/internal/cue/ @alice
/internal/tofu/ @bob
/docs/ @charlie
/cmd/cli/ @alice @bob
```

### 6.3 Decision Log (ADRs)

Every architectural decision → ADR:

```
docs/ADR/ADR-0004-k3s-vs-docker-swarm.md
docs/ADR/ADR-0005-variant-system-design.md
```

---

## 7. Success Metrics

Track these over time:

| Metric | Baseline | Target | Cadence |
|--------|----------|--------|---------|
| Test Coverage | 78% | ≥90% | Monthly |
| Linting Warnings | 0 | 0 | Every PR |
| Mean Time to Fix (MTBF) | N/A | <24h | Monthly |
| Documentation Staleness | 0 | 0 | Quarterly |
| Dependency Updates | Backlog | <1 month | Monthly |

---

## 8. Sign-Off for Release

```markdown
## Release Sign-Off v1.0.0

- [ ] All Phase 3 (Verification) gates passed
- [ ] CHANGELOG.md complete and accurate
- [ ] Version numbers updated
- [ ] Release notes approved by team
- [ ] Documentation reviewed by community
- [ ] Performance benchmarked
- [ ] Security audit complete

**Release Manager:** [name]  
**Release Date:** 2026-01-22  
**Status:** ✅ READY FOR PRODUCTION

**Post-Release On-Call:** [name]
```

---

## 9. Appendix: Broken Windows Policy

Maintain the cleanup indefinitely:

- ✅ **Zero Tolerance:** Do not leave `TODO` without a GitHub issue.
- ✅ **Boy Scout Rule:** Always leave the file cleaner than you found it.
- ✅ **Stop the Line:** If a standard is unclear, pause and write an ADR. Do not guess.
- ✅ **Automate:** If a rule can be enforced by CI/CD, automate it.

