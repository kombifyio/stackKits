# StackKits Roadmap

> **Last Updated:** 2026-02-07  
> **Status:** Active Development — Architecture v4 Transition  
> **Current Version:** v1.0.0-beta  
> **Architecture:** [ARCHITECTURE_V4.md](./ARCHITECTURE_V4.md)

---

## Executive Summary

StackKits v4 introduces a fundamental redesign around **three concepts** (StackKit as architecture pattern, Node-Context, and composable Add-Ons) plus a **Progressive Capability Model** (Levels 0–4). This roadmap focuses on implementing these concepts while completing the already functional Base Kit.

### Current State Assessment

| Component | Status | Notes |
|-----------|--------|-------|
| CUE base schemas | 90% | ~2800 lines, production-quality. Package bugs in `base/platform/` and `base/schema/` |
| base-homelab | 60% | CUE validates, services defined, needs E2E testing + Add-On migration |
| dev-homelab | 40% | Package conflicts in `exports.cue`, needs restructuring |
| modern-homelab | 0% | Schema only, all services `status: "planned"` |
| ha-homelab | 0% | Schema only, 8 explicit TODOs |
| stackkit CLI | 80% | 9 commands functional (Go), needs Add-On support |
| Add-On system | 0% | **NEW** — replaces monolithic variants |
| Context system | 0% | **NEW** — replaces manual compute tier selection |
| kombify Stack integration | 30% | Unifier pipeline exists, needs v4 alignment |

---

## Phase Overview

```
Phase 1 (Weeks 1-4):    Foundation — Fix bugs, create Add-On/Context scaffolding
Phase 2 (Weeks 5-8):    StackKit Completion — base E2E, modern/ha redefinition
Phase 3 (Weeks 9-12):   Integration — kombify Stack alignment, Unifier v4
Phase 4 (Weeks 13-16):  Operations — Day-2, marketplace, documentation
```

---

## Phase 1: Foundation (Weeks 1–4)

**Goal:** Fix existing bugs, establish Add-On and Context infrastructure, complete Base Kit.

### 1.1 CUE Bug Fixes (P0)

- [ ] Fix package declarations in `base/platform/*.cue` (declares `package base` in subdirectory)
- [ ] Fix package declarations in `base/schema/*.cue` (same issue)
- [ ] Resolve schema duplication between `base/layers.cue` and `base/platform/*.cue`
- [ ] Fix `dev-homelab/exports.cue` package conflict with `stackfile.cue`
- [ ] Align Go↔CUE naming: compute tiers (`minimal/standard/performance` → consistent naming)
- [ ] Align Go↔CUE naming: platform types (Go accepts `kubernetes`, CUE doesn't)
- [ ] Fix Layer 3 PAAS validation logic (currently inverted)
- [ ] Resolve `base-homelab/stackfile.cue` dual schema (`#BaseHomelabStack` vs `#BaseHomelabKit`)
- [ ] Align CUE module path: `github.com/kombihq/stackkits` (match kombify Stack expectation)

### 1.2 Add-On System Scaffolding

Create the composable Add-On infrastructure that replaces monolithic variants.

```
addons/
├── _schema/
│   └── addon.cue              # #AddOn schema definition
├── monitoring/
│   ├── addon.cue              # Metadata, compatibility, constraints
│   └── services.cue           # Prometheus + Grafana + Alertmanager
├── backup/
│   ├── addon.cue
│   └── services.cue           # Restic + targets
├── vpn-overlay/
│   ├── addon.cue
│   └── services.cue           # Headscale/Tailscale
└── README.md
```

- [ ] Define `#AddOn` CUE schema with metadata, compatibility, resources, services
- [ ] Create `addons/` directory structure
- [ ] Migrate `base-homelab/variants/coolify.cue` → `addons/coolify-paas/addon.cue`
- [ ] Migrate `base-homelab/variants/beszel.cue` → `addons/monitoring/` (subset)
- [ ] Migrate `base-homelab/variants/minimal-compute.cue` → `contexts/pi.cue` defaults
- [ ] Migrate `base-homelab/variants/secure-variant.cue` → base security defaults (fold in)
- [ ] Implement Add-On dependency resolution in CUE
- [ ] Add `stackkit addon add/list/remove` CLI commands

### 1.3 Context System Scaffolding

Create Node-Context modules for environment-aware defaults.

```
contexts/
├── local.cue               # Full Docker, local TLS, Dokploy
├── cloud.cue               # Let's Encrypt, Coolify, egress-aware
└── pi.cue                  # ARM images, reduced services, tmpfs
```

- [ ] Define context detection criteria in CUE constraints
- [ ] Create `contexts/local.cue` with local hardware defaults
- [ ] Create `contexts/cloud.cue` with cloud provider defaults
- [ ] Create `contexts/pi.cue` with Raspberry Pi / ARM defaults
- [ ] Implement context-driven PAAS selection (Dokploy for local, Coolify for cloud)
- [ ] Implement context-driven TLS strategy (self-signed vs Let's Encrypt)
- [ ] Implement context-driven resource limits

### 1.4 Base Kit E2E Testing

- [ ] Create test environment (local VM or Docker via kombify Sim)
- [ ] Test full OpenTofu deployment flow
- [ ] Validate Layer 1 identity (LLDAP + Step-CA)
- [ ] Validate Layer 2 platform (Traefik + Dokploy)
- [ ] Validate Layer 3 applications via Dokploy
- [ ] Run with each Context (local, cloud, pi)

### Phase 1 Deliverables

| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| All CUE bugs fixed | `cue vet ./base/... ./base-homelab/...` passes |
| Add-On schema | `#AddOn` schema defined, 3+ add-ons migrated from variants |
| Context modules | `local.cue`, `cloud.cue`, `pi.cue` with smart defaults |
| base-homelab E2E | Full deployment succeeds in local context |
| CLI Add-On commands | `stackkit addon add/list/remove` functional |

---

## Phase 2: StackKit Completion (Weeks 5–8)

**Goal:** Complete all three StackKits as architecture patterns, not node-count definitions.

### 2.1 Base Kit Refinement

- [ ] Remove old `variants/` directory (replaced by Add-Ons and Contexts)
- [ ] Consolidate to single schema (`#BaseHomelabKit` only)
- [ ] Update `default-spec.yaml` to v2 `kombination.yaml` format
- [ ] Document Base Kit as "single-environment pattern" (local or cloud VPS)
- [ ] Add Context × base matrix tests (local, cloud, pi)

### 2.2 Modern Homelab Kit Implementation

Redefine as **hybrid infrastructure pattern** (always local + cloud).

- [ ] Define VPN overlay networking as core requirement (not add-on)
- [ ] Implement Coolify as default PAAS (required for multi-environment)
- [ ] Add split DNS configuration (local vs public)
- [ ] Define service placement rules (which services go where)
- [ ] Implement `modern × local` context (local + Tailscale exit node)
- [ ] Implement `modern × cloud` context (multi-cloud mesh)
- [ ] Create E2E test with 2-node deployment (1 local + 1 cloud)

### 2.3 High Availability Kit Implementation

Redefine as **high-availability cluster pattern**.

- [ ] Implement Docker Swarm orchestration config
- [ ] Add Keepalived VIP for load balancing
- [ ] Define quorum-based consensus rules in CUE
- [ ] Implement LLDAP cluster configuration
- [ ] Implement Step-CA HA mode
- [ ] Add Authentik as L2 identity (cluster-aware)
- [ ] Implement `ha × local` context (Swarm cluster, local LB)
- [ ] Implement `ha × cloud` context (managed LB, auto-scaling)
- [ ] Mark `ha × pi` as not recommended (resource validation)

### 2.4 Context-Driven Defaults Matrix

Implement the 9 curated configurations (3 StackKits × 3 Contexts):

| | local | cloud | pi |
|---|---|---|---|
| **base** | Dokploy, self-signed TLS | Coolify, Let's Encrypt | Lean Docker, reduced services |
| **modern** | Tailscale exit node, hybrid DNS | Multi-cloud mesh | Edge relay role |
| **ha** | Swarm + Keepalived | Cloud HA + managed LB | N/A (not recommended) |

- [ ] Implement all 9 combinations as CUE constraint sets
- [ ] Validate each combination with `cue vet`
- [ ] Create test fixtures for each combination

### Phase 2 Deliverables

| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| base-homelab v4.0 | Clean schema, no variants, context-aware (Base Kit) |
| modern-homelab v4.0 | Hybrid pattern implemented, 2-node E2E test (Modern Homelab Kit) |
| ha-homelab v4.0 | Cluster pattern implemented, Swarm config (High Availability Kit) |
| 9-cell matrix | All StackKit × Context combinations validate |
| Updated kombination.yaml | v2 spec format with stackkit/context/addons |

---

## Phase 3: kombify Stack Integration (Weeks 9–12)

**Goal:** Align the kombify Stack Unifier pipeline with StackKits v4 concepts.

### 3.1 Unifier Pipeline v4 Alignment

Update `pkg/unifier/` in kombify Stack to understand the new 3-concept model.

- [ ] Update `resolver.go`: StackKit selection by architecture pattern (not node count)
- [ ] Update `addons.go`: Load Add-Ons from `addons/` directory (not inline conditions)
- [ ] Update `analyze.go`: Generate Node-Context from agent hardware reports
- [ ] Update `unify.go`: Merge StackKit + Context + Add-Ons into unified CUE evaluation
- [ ] Update `stackkit_loader.go`: Load `contexts/*.cue` alongside StackKit schemas
- [ ] Align CUE module path: both repos use `github.com/kombihq/stackkits`

### 3.2 StackKit Resolver Update

Current resolver uses aliases like `hybrid-cloud`, `cloud-native`, `minimal-arm`. Update to:

| Old Alias | New Resolution |
|-----------|---------------|
| `hybrid-cloud` | `modern` StackKit + `cloud` Context |
| `cloud-native` | `modern` StackKit + `cloud` Context |
| `minimal-arm` | `base` StackKit + `pi` Context |
| `developer-local` | `base` StackKit + `local` Context |
| `high-availability` | `ha` StackKit + auto Context |

- [ ] Refactor resolver to return StackKit + Context pair
- [ ] Remove node-count-based selection logic
- [ ] Add pattern-based selection (single-env → base, hybrid → modern, HA → ha)

### 3.3 Web Wizard Update

Update kombify Stack frontend wizard for 3-concept model.

- [ ] Step 1: Choose architecture pattern (base/modern/ha) with visual comparison
- [ ] Step 2: Node registration (Context auto-detected per node)
- [ ] Step 3: Add-On selection (filtered by StackKit + Context compatibility)
- [ ] Step 4: Customization (service overrides, domain, etc.)
- [ ] Step 5: Review + deploy

### 3.4 Agent Integration for Context Detection

- [ ] Agent reports hardware profile on `Register` RPC (RAM, CPU, arch, GPU)
- [ ] Agent reports cloud provider metadata (if available)
- [ ] kombify Stack classifies Context from agent report
- [ ] Context flows into Unifier pipeline

### Phase 3 Deliverables

| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| Unifier v4 | Pipeline processes StackKit + Context + Add-Ons |
| Resolver v4 | Pattern-based StackKit selection |
| Web wizard v4 | 3-concept flow in frontend |
| Context auto-detection | Agent → Context classification working |

---

## Phase 4: Operations & Ecosystem (Weeks 13–16)

**Goal:** Day-2 operations, Add-On marketplace, documentation, community.

### 4.1 Day-2 Operations (Level 3)

- [ ] Drift detection for Add-On configurations
- [ ] Certificate auto-renewal orchestration
- [ ] Service health monitoring via agent heartbeats
- [ ] Rolling update support for ha StackKit
- [ ] Configuration change rollback

### 4.2 Add-On Ecosystem

- [ ] Add-On registry/marketplace (kombify Sphere integration)
- [ ] Community Add-On contribution workflow
- [ ] Add-On versioning and compatibility matrix
- [ ] `stackkit addon search` for marketplace discovery

### 4.3 Documentation

- [ ] Update Mintlify docs with v4 concepts
- [ ] Create StackKit selection guide (pattern-based)
- [ ] Create Add-On authoring guide
- [ ] Create Context customization guide
- [ ] Update API reference for v4 spec format
- [ ] Migration guide from v3 variants to v4 Add-Ons

### 4.4 Level 4 Preparation (SaaS)

- [ ] Define AI-assisted operations API surface
- [ ] Natural language → kombination.yaml prototype
- [ ] Cost optimization engine for cloud contexts
- [ ] Community intelligence aggregation (anonymized)

### Phase 4 Deliverables

| Deliverable | Acceptance Criteria |
|-------------|---------------------|
| Day-2 operations | Drift detection, cert renewal, health monitoring |
| Add-On marketplace | Registry with search, install, version management |
| Complete documentation | All Mintlify pages updated, guides published |
| Level 4 prototype | NLP config demo in kombify Sphere |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| `cue vet` passes for all StackKits | 100% |
| E2E deployment success rate (base) | > 95% |
| StackKit × Context combinations validated | 8/9 (ha×pi excluded) |
| Add-Ons migrated from variants | All |
| kombify Stack Unifier processes v4 format | Yes |
| Documentation coverage | > 90% |
| Time to deploy (base, local, no add-ons) | < 10 minutes |

---

## Architecture Reference

For detailed architecture documentation, see [ARCHITECTURE_V4.md](./ARCHITECTURE_V4.md).

Key concepts:
- **StackKit** = Architecture pattern (base/modern/ha)
- **Node-Context** = Runtime environment (local/cloud/pi), auto-detected
- **Add-Ons** = Composable extensions (replace variants)
- **Progressive Capability Model** = Levels 0–4 (CLI → SaaS)
- **3-Layer Architecture** = L1 Foundation, L2 Platform, L3 Applications (preserved)
