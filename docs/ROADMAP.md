# StackKits Roadmap

> **Last Updated:** 2026-01-22  
> **Status:** Active Development  
> **Current Version:** v1.0.0-beta

---

## Vision

StackKits provides standardized, pre-validated infrastructure blueprints for homelab and self-hosted environments. We enable technically minded users to deploy modern infrastructure without mastering every detail of Docker, Terraform, and system administration.

---

## Release Strategy

| Version | Target | Focus | Status |
|---------|--------|-------|--------|
| **v1.0** | Q1 2026 | base-homelab complete, single-server deployments | 🟡 In Progress |
| **v1.1** | Q2 2026 | modern-homelab, multi-node with Coolify | 📋 Planned |
| **v1.2** | Q3 2026 | ha-homelab, Docker Swarm HA | 📋 Planned |
| **v2.0** | 2027 | Kubernetes support, API module | 🔮 Future |

---

## v1.0 - Foundation Release

**Theme:** "Make base-homelab production-ready"

### ✅ Completed
- [x] CUE schema architecture (3-layer model)
- [x] CLI scaffold (`init`, `validate`, `plan`, `apply`, `destroy`, `status`)
- [x] base-homelab templates (simple mode)
- [x] CI/CD pipeline (GitHub Actions)
- [x] Documentation structure (TARGET_STATE, STATUS_QUO, ADRs)
- [x] PaaS strategy: Dokploy (no domain) / Coolify (with domain)

### 🔄 In Progress
- [x] **CUE → Terraform Bridge**
  - Read `stackfile.cue` and generate `terraform.tfvars.json`
  - Validate CUE values before Terraform execution
  - _Implemented: `internal/cue/bridge.go`_

- [x] **Variant System Polish**
  - `default` variant: Dokploy + Uptime Kuma
  - `coolify` variant: Coolify + Uptime Kuma  
  - `beszel` variant: Dokploy + Beszel
  - `minimal` variant: Dockge + Portainer
  - _Implemented: `base-homelab/variants/service/`_

- [x] **Documentation Alignment**
  - Reduced core docs count (removed cleanup/ subfolder, _archive/)
  - Updated docs/README.md navigation
  - _Priority: Completed_

### 📋 To Do
- [ ] Network standards enforcement (KombiStack network: `172.20.0.0/16`)
- [ ] Terramate integration for `--advanced` mode (defer wiring to v1.1)
- [ ] Unit test coverage to 80%
- [ ] Release automation and versioning

---

## v1.1 - Multi-Node Release

**Theme:** "Enable hybrid cloud + local deployments"

### Scope
- [ ] **modern-homelab completion**
  - Multi-node Docker deployment
  - Coolify as default PaaS (requires own domain)
  - VPN overlay (Headscale/Tailscale)
  - Cloud node + local node topology

- [ ] **Terramate Advanced Mode**
  - Wire Terramate to CLI (`stackkit plan --advanced`)
  - Drift detection implementation
  - Multi-stack orchestration

- [ ] **Cloud Provider Support**
  - Hetzner Cloud integration
  - DigitalOcean integration
  - Vultr integration

### Prerequisites
- v1.0 stable release
- base-homelab fully tested in production

---

## v1.2 - High Availability Release

**Theme:** "Production-grade homelab infrastructure"

### Scope
- [ ] **ha-homelab completion**
  - Docker Swarm HA (3+ nodes)
  - Manager quorum, replicated services
  - Shared storage (GlusterFS or NFS)
  - Load balancing and failover

- [ ] **Enhanced Monitoring**
  - Prometheus + Grafana stack
  - Loki for log aggregation
  - Alerting integration

- [ ] **Backup & Recovery**
  - Automated backup strategies
  - Disaster recovery procedures
  - Offsite backup integration

### Prerequisites
- v1.1 stable release
- modern-homelab proven in hybrid deployments

---

## v2.0 - Platform Expansion (Future)

**Theme:** "Enterprise-ready features"

### Scope
- [ ] **Kubernetes Platform Layer**
  - K3s as lightweight Kubernetes
  - Kubernetes-native StackKits
  - Migration path from Docker

- [ ] **API Module**
  - REST API for remote management
  - Integration with external tools
  - Multi-tenant support

- [ ] **Add-On Marketplace**
  - Curated add-on library
  - Community contributions
  - Quality and compatibility checks

---

## Technical Debt & Maintenance

## Gap Analysis (Vision vs. Reality)

This section captures the key delta between target vision and current implementation.

| Area | Target | Current | Gap |
|------|--------|---------|-----|
| StackKits | 3 templates | 1 complete | High |
| CLI | 10+ commands | 8 core commands | Medium |
| Platforms | Docker + K8s | Docker only | Medium |
| Execution Modes | Simple + Advanced | Simple only | Medium |

### v1.0 blockers (P0/P1)

- **CUE → Terraform bridge**: implement real generation path (templates are currently static)
- **Unit test coverage**: increase coverage for internal logic and CLI flows
- **Modern Homelab alignment**: pick a platform direction and remove conflicting references

### Decision: modern-homelab platform

Recommendation for v1.x: **Docker + Coolify** (K8s deferred to v2.0).

## Backlog (Living List)

These are the prioritized work items to reach the roadmap milestones.

### 🔴 High Priority (v1.0 Blockers)

#### Core Functionality

| ID | Item | Impact | Status |
|----|------|--------|--------|
| **F-001** | CUE → Terraform bridge | Blocks dynamic generation | ✅ Done |
| **F-002** | Variant system polish | User experience | ✅ Done |
| **F-003** | Unit test coverage to 80% | Quality gate | 🟡 In Progress |

#### Technical Debt

| ID | Item | Location | Risk | Status |
|----|------|----------|------|--------|
| **TD-012** | CUE missing schema directory validation | `internal/cue` | Med | ✅ Fixed |
| **TD-013** | Error handling for `SaveDeploymentState` | `internal/config` | Med | 🟡 Open |
| **TD-022** | Windows path compatibility | `internal/*` | Low | 🟡 Open |
| **TD-035** | Documentation cleanup | `docs/` | Low | ✅ Done |

### 🟡 Medium Priority (v1.0 Nice-to-Have)

#### Features

| ID | Item | Impact |
|----|------|--------|
| **F-004** | CLI rollback capability | Reliability |
| **F-005** | Lock file support (`.stackkit.lock`) | Consistency |
| **F-006** | JSON output for `status` command | Automation |

#### Technical Debt

| ID | Item | Location |
|----|------|----------|
| **TD-029** | Structured logging system | `internal/*` |
| **TD-030** | Improve plan output parsing | `internal/tofu` |
| **TD-035** | Documentation cleanup | `docs/` |

### 🟢 Low Priority (v1.1+)

| ID | Item | Target Version |
|----|------|----------------|
| **F-007** | Terramate advanced mode wiring | v1.1 |
| **F-008** | Cloud provider integration (Hetzner/DO) | v1.1 |
| **F-009** | Interactive mode for CLI | v1.1 |
| **F-010** | Import existing docker-compose setups | v1.2 |
| **F-011** | Kubernetes support (K3s) | v2.0 |

---

## Decision Log

Key architectural decisions are documented in [ADR/](ADR/):

- **ADR-0001:** Documentation Standard (Diátaxis Framework)
- **ADR-0002:** Docker-First Strategy for v1.x

---

## Contributing

We welcome contributions! See our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

**Priority areas for contribution:**
1. Testing and bug reports for base-homelab
2. Documentation improvements
3. Service schema definitions
4. Template enhancements
