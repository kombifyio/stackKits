# StackKits Release Plan — Phase-Based Execution

> **Created:** 2026-02-21
> **Status:** Active
> **Branch:** `claude/stackkit-release-planning-m7mAF`
> **Context:** Post-v1.0-beta analysis, comprehensive repo assessment
> **Readiness Score:** 60/100 → Target 85/100 for v1.0 Release Candidate

---

## Current State Summary

### What's Done (Completed Beads Epics)
- **v1.0 Release Prep** (StackKits-vuz) — GoReleaser, CI/CD, docs, test coverage 80%
- **API & CLI Hardening** (StackKits-l3s) — 23 issues resolved (security, auth, rate limiting)
- **Security Hardening Round 2** (StackKits-mwa) — 10 issues resolved (timing attacks, CORS, etc.)
- **Admin Migration** (StackKits-egb) — Dedup, CrawlSource, evaluation state machine
- **Admin Platform Expansion** (StackKits-pba) — Prisma schema, n8n workflows, dashboard
- **Tech Debt Sprint** (StackKits-0qk) — TD-11/12/15/21/23 resolved
- **Website Migration** (StackKits-386) — Svelte website-v2 deployed on Azure

### What's Open (Remaining Beads Epics)
- **v1.1** (StackKits-2r8) — modern-homelab, Multi-Node, Coolify, VPN (Juli 2026)
- **v1.2** (StackKits-ci5) — ha-kit, Docker Swarm HA (Oktober 2026)
- **modern-homelab** (StackKits-j83) — Individual task, unstarted

### Critical Gaps Identified
1. **CUE→IaC Bridge** (TD-10): `bridge.go` generates only tfvars, not full Terraform — core promise unfulfilled
2. **modern-homelab**: Entirely K8s/k3s-based — needs complete Docker rewrite
3. **Add-On System**: Designed in ARCHITECTURE_V4 but not wired into CLI/runtime
4. **Context System**: Defined but not implemented
5. **E2E Testing**: base-kit not tested end-to-end
6. **ROADMAP.md outdated**: Many M0/M1 items marked unchecked but actually completed

---

## Execution Plan — 4 Phases

### Phase 1: Foundation & IaC Pipeline (2 weeks)
**Goal:** base-kit works end-to-end: `validate → generate → plan → apply`

| # | Task | Priority | Effort | Depends On |
|---|------|----------|--------|------------|
| 1.1 | Update ROADMAP.md — sync checkboxes with actual completion state | P1 | 2h | — |
| 1.2 | CUE→tfvars.json pipeline: rewrite bridge.go to use `cue export` | P0 | 3d | — |
| 1.3 | OpenTofu modularization: split main.tf into modules | P1 | 2d | — |
| 1.4 | base-kit E2E test: validate→generate→plan works | P0 | 2d | 1.2, 1.3 |
| 1.5 | CI pipeline: cue vet + Go tests on every push | P1 | 1d | — |
| 1.6 | JSON schema export for IDE support | P2 | 1d | 1.2 |

**Done Criteria:** `stackkit validate && stackkit generate && stackkit plan` succeeds for base-kit.

---

### Phase 2: Context System & Add-On Foundation (2 weeks)
**Goal:** Node-Context works. First Add-Ons are functional.

| # | Task | Priority | Effort | Depends On |
|---|------|----------|--------|------------|
| 2.1 | Define `#NodeContext` CUE schema | P0 | 1d | Phase 1 |
| 2.2 | Create `contexts/local.cue` — Docker, local TLS, Dokploy | P0 | 1d | 2.1 |
| 2.3 | Create `contexts/cloud.cue` — Let's Encrypt, Coolify | P1 | 1d | 2.1 |
| 2.4 | Create `contexts/pi.cue` — ARM images, reduced resources | P2 | 1d | 2.1 |
| 2.5 | Context-driven defaults in CUE (TLS, PAAS, resources) | P0 | 2d | 2.2, 2.3 |
| 2.6 | CLI: `--context` flag for init/generate/apply | P0 | 1d | 2.5 |
| 2.7 | Define `#AddOn` CUE schema | P1 | 1d | — |
| 2.8 | Implement first 3 Add-Ons: monitoring, backup, vpn-overlay | P1 | 3d | 2.7 |
| 2.9 | CLI: `stackkit addon list/add/remove` commands | P1 | 2d | 2.7 |

**Done Criteria:** `stackkit init --context local` and `stackkit addon add monitoring` work.

---

### Phase 3: StackKit Completion (3 weeks)
**Goal:** modern-homelab rewritten. dev-homelab functional. All StackKits validate.

| # | Task | Priority | Effort | Depends On |
|---|------|----------|--------|------------|
| 3.1 | modern-homelab: Delete all K8s/k3s/FluxCD schemas | P0 | 0.5d | — |
| 3.2 | modern-homelab: Rewrite as Docker multi-node with VPN overlay | P0 | 5d | 3.1, Phase 2 |
| 3.3 | modern-homelab: Coolify as default PAAS | P1 | 1d | 3.2 |
| 3.4 | modern-homelab: E2E test with 2-node config | P1 | 2d | 3.2 |
| 3.5 | dev-homelab: Fix package conflicts, restructure | P1 | 1d | — |
| 3.6 | dev-homelab: Write schema tests | P2 | 1d | 3.5 |
| 3.7 | ha-kit: Complete Docker Swarm schema stubs | P2 | 3d | Phase 2 |
| 3.8 | StackKit × Context matrix validation (8/9 combos) | P1 | 2d | 3.2, 3.7 |
| 3.9 | Migrate old variants → Add-Ons + Contexts | P1 | 2d | Phase 2, 3.5 |
| 3.10 | Delete `base-kit/variants/` directory | P2 | 0.5d | 3.9 |

**Done Criteria:** `cue vet` passes for all 4 StackKits. modern-homelab is Docker-based. 8/9 StackKit×Context combinations validate.

---

### Phase 4: Polish, Validation & Release (1 week)
**Goal:** v1.0 Release Candidate quality.

| # | Task | Priority | Effort | Depends On |
|---|------|----------|--------|------------|
| 4.1 | CUE decision logic: Port collision detection | P1 | 1d | Phase 3 |
| 4.2 | CUE decision logic: Service dependency validation | P1 | 1d | Phase 3 |
| 4.3 | CUE decision logic: Network mode decisions | P2 | 1d | Phase 2 |
| 4.4 | Update docs/CLI.md with Add-On/Context commands | P1 | 0.5d | Phase 2 |
| 4.5 | Update docs/creating-stackkits.md for v4 concepts | P1 | 0.5d | Phase 3 |
| 4.6 | Integration test suite: all StackKits × Contexts | P1 | 1d | Phase 3 |
| 4.7 | Tag v1.0.0-rc1, verify GoReleaser builds | P0 | 0.5d | All |

**Done Criteria:** All tests pass. Documentation current. Release candidate tagged.

---

## Timeline

```
Week 1-2:  Phase 1 — IaC Pipeline Foundation
Week 3-4:  Phase 2 — Context + Add-On System
Week 5-7:  Phase 3 — StackKit Completion
Week 8:    Phase 4 — Polish & Release Candidate

Target: v1.0.0-rc1 by mid-April 2026
```

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|:-----------:|:------:|------------|
| bridge.go rewrite more complex than estimated | Medium | High | Prototype with 1 service first |
| modern-homelab scope creep | High | Medium | Define MVP: 2-node Docker only |
| CUE export edge cases | Medium | Medium | Comprehensive test suite |
| Single developer bandwidth | High | High | Strict phase gates, no scope expansion |

---

## Beads Task Mapping

Each phase maps to a Beads epic with subtasks. See `.beads/issues.jsonl` for full task graph.

| Phase | Epic ID | Description |
|-------|---------|-------------|
| Phase 1 | TBD | IaC Pipeline Foundation |
| Phase 2 | TBD | Context + Add-On System |
| Phase 3 | Extends StackKits-2r8 | StackKit Completion |
| Phase 4 | TBD | Polish & Release Candidate |

---

*This plan will be updated as phases complete. Review at each phase gate.*
