# StackKits Architecture v4.0

> **Version:** 4.0  
> **Date:** 2026-02-07  
> **Status:** Accepted  
> **Supersedes:** [Architecture v3.0](./architecture.md)

---

## Executive Summary

StackKits v4 introduces a fundamental redesign based on three concepts:

1. **StackKit** — An architecture pattern (not a node-count definition)
2. **Node-Context** — Where and on what hardware the stack runs
3. **Add-Ons** — Composable capability extensions (replacing monolithic variants)

These three concepts combine with a **Progressive Capability Model** (Levels 0–4) that describes how StackKits integrates into the broader kombify ecosystem, from standalone CLI usage to AI-assisted operations.

---

## 1. The Three Concepts

### 1.1 StackKit = Architecture Pattern

A StackKit defines **how infrastructure is architecturally organized**, not how many servers are involved.

| StackKit | Architecture Pattern | Core Idea |
|----------|---------------------|-----------|
| **Base Kit** | Single environment | All services in one deployment target — local server or cloud VPS. Docker Compose, one logical unit. |
| **Modern Homelab Kit** | Hybrid infrastructure | Bridges local and cloud. VPN overlay, distributed services, public endpoints. |
| **High Availability Kit** | HA cluster | Redundancy, failover, quorum-based consensus. Cluster-first architecture. |

**Key Insight:** A Base Kit can run on a single cloud VPS or a home server — the environment doesn't change the architecture pattern. A Modern Homelab Kit requires at least one local node (the "homelab" part) bridged with cloud. The StackKit defines the *pattern*, not the *scale*.

```
StackKit ≠ Server Count
StackKit = Architecture Pattern = How services relate to each other
```

### 1.2 Node-Context = Where + What

Node-Context describes the runtime environment. It is auto-detected (not user-chosen) based on hardware capabilities and provider metadata.

| Context | Detection Criteria | Characteristics |
|---------|-------------------|-----------------|
| **local** | Physical hardware, no cloud metadata, x86_64/ARM | Full control, local network, no egress costs |
| **cloud** | Cloud provider metadata detected (AWS, Azure, Hetzner, etc.) | Public IP, egress costs, provider-managed networking |
| **pi** | ARM architecture + low memory (< 4GB) or Raspberry Pi detection | Resource-constrained, SD card storage, power-efficient |

**Auto-Detection Flow:**
```
Agent boots → Reports hardware + provider metadata
    → kombify Stack classifies Node-Context
    → StackKit receives Context as input
    → CUE defaults resolve per Context
```

**What Context Affects:**
- Resource limits (memory, CPU reservations)
- Storage driver selection (overlay2 vs devicemapper vs tmpfs)
- Image architecture (amd64 vs arm64 vs arm/v7)
- Network configuration (local DNS vs cloud DNS vs mDNS)
- TLS strategy (self-signed vs Let's Encrypt vs managed)
- Backup strategy (local NAS vs S3 vs B2)

### 1.3 Add-Ons = Composable Extensions

Add-Ons replace the old monolithic "variants" system. Each Add-On is a self-contained CUE module that extends a StackKit with additional capabilities.

**Old (Variants — monolithic, mutually exclusive):**
```
base-homelab/variants/
├── coolify.cue          # Replaces entire PAAS
├── beszel.cue           # Replaces monitoring
├── minimal-compute.cue  # Conflicts with standard
└── secure-variant.cue   # Overlaps with base security
```

**New (Add-Ons — composable, stackable):**
```
addons/
├── monitoring/          # Prometheus + Grafana + Alertmanager
│   └── addon.cue
├── backup/              # Restic + S3/B2/NAS targets
│   └── addon.cue
├── vpn-overlay/         # Headscale/Tailscale mesh
│   └── addon.cue
├── gpu-workloads/       # NVIDIA/AMD GPU passthrough
│   └── addon.cue
├── ci-cd/               # Gitea + Drone CI
│   └── addon.cue
├── media/               # Jellyfin + *arr stack
│   └── addon.cue
└── smart-home/          # Home Assistant + MQTT + Zigbee
    └── addon.cue
```

**Add-On Rules:**
1. Add-Ons **MUST** declare which StackKits they are compatible with
2. Add-Ons **MUST** declare their Context constraints (e.g., `gpu-workloads` requires `local` or `cloud`, not `pi`)
3. Add-Ons **MAY** depend on other Add-Ons (dependency graph)
4. Add-Ons **MUST NOT** modify Layer 1 foundation settings
5. Add-Ons **MAY** extend Layer 2 (platform services) or Layer 3 (applications)
6. Multiple Add-Ons can be active simultaneously (composable)

**Add-On CUE Schema:**
```cue
#AddOn: {
    metadata: {
        name:        string
        version:     string
        description: string
        author:      string
    }

    compatibility: {
        stackkits: [...string]              // ["base", "modern", "ha"]
        contexts:  [...string]              // ["local", "cloud", "pi"]
        requires:  [...string] | *[]        // other addon names
        conflicts: [...string] | *[]        // mutually exclusive addons
    }

    resources: {
        minMemoryMB: int | *0
        minCPUCores: number | *0
        requiresGPU: bool | *false
    }

    services: [...#AddonService]

    // CUE constraints that merge into the StackKit
    constraints: _
}
```

---

## 2. Context-Driven Defaults Matrix

The combination of StackKit × Context produces **9 curated base configurations**. Each cell represents a fully resolved, validated default configuration.

```
                    ┌─────────────┬─────────────┬─────────────┐
                    │   local     │   cloud     │     pi      │
        ┌───────────┼─────────────┼─────────────┼─────────────┤
        │   base    │ Full Docker │ Minimal VPS │ Lean Docker │
        │           │ Compose,    │ setup,      │ ARM images, │
        │           │ local TLS,  │ Let's       │ tmpfs,      │
        │           │ Dokploy     │ Encrypt,    │ reduced     │
        │           │             │ Coolify     │ services    │
        ├───────────┼─────────────┼─────────────┼─────────────┤
        │  modern   │ Local +     │ Multi-cloud │ Edge node   │
        │           │ Tailscale   │ mesh,       │ in hybrid   │
        │           │ exit node,  │ distributed │ network,    │
        │           │ hybrid DNS  │ services    │ relay role  │
        ├───────────┼─────────────┼─────────────┼─────────────┤
        │    ha     │ Swarm       │ Cloud HA    │ N/A         │
        │           │ cluster,    │ with managed│ (pi context │
        │           │ Keepalived, │ LB, auto-   │ + HA = not  │
        │           │ local LB    │ scaling     │ recommended)│
        └───────────┴─────────────┴─────────────┴─────────────┘
```

**CUE Resolution:**
```cue
// Smart defaults resolve per StackKit × Context
#ResolvedDefaults: {
    _stackkit: "base" | "modern" | "ha"
    _context:  "local" | "cloud" | "pi"

    // PAAS selection
    if _context == "cloud" || _stackkit == "modern" {
        paas: type: "coolify"
    }
    if _context == "local" && _stackkit == "base" {
        paas: type: "dokploy"
    }

    // TLS strategy
    if _context == "cloud" {
        tls: mode: "letsencrypt"
    }
    if _context == "local" {
        tls: mode: "self-signed"  // via Step-CA
    }
    if _context == "pi" {
        tls: mode: "self-signed"
    }

    // Resource limits
    if _context == "pi" {
        resources: {
            memoryLimitMB: 256
            cpuShares:     512
        }
    }
}
```

---

## 3. Progressive Capability Model

StackKits operates across 5 capability levels. Each level unlocks additional functionality while maintaining full backward compatibility.

```
Level 4  ┌────────────────────────────┐  SaaS-only
         │   AI-Assisted Operations   │  (kombify Sphere)
         │   Natural language config,  │
         │   predictive scaling,       │
         │   anomaly detection         │
Level 3  ├────────────────────────────┤
         │   Runtime Intelligence      │  kombify Stack
         │   Live monitoring, auto-    │  (Agent Protocol)
         │   remediation, Day-2 ops    │
Level 2  ├────────────────────────────┤
         │   Worker Agent Integration  │  kombify Stack
         │   gRPC agent, placement     │  (gRPC + mTLS)
         │   engine, capability        │
         │   validation                │
Level 1  ├────────────────────────────┤
         │   kombify Stack Control     │  kombify Stack
         │   Plane: Unifier pipeline,  │  (Web UI + API)
         │   wizard UI, StackKit       │
         │   resolver, Add-On system   │
Level 0  ├────────────────────────────┤
         │   Standalone CLI            │  stackkit CLI
         │   stackkit init/validate/   │  (pure CLI)
         │   generate/apply            │
         └────────────────────────────┘
```

### Level 0: Standalone CLI

The `stackkit` CLI operates completely independently. No network access, no API, no accounts required.

```bash
# Full workflow at Level 0
stackkit init base-homelab          # Create kombination.yaml with Base Kit defaults
stackkit validate                   # CUE validation
stackkit generate                   # Produce OpenTofu files
stackkit apply                      # Provision infrastructure
```

**Capabilities:**
- CUE schema validation
- OpenTofu/Terramate file generation
- Direct provisioning via SSH
- Local state management
- Template rendering

**Limitations:**
- No auto-detection of Node-Context (user must specify in `kombination.yaml`)
- No Add-On marketplace (local add-ons only)
- No multi-node coordination
- No Day-2 operations

### Level 1: kombify Stack Control Plane

When used through kombify Stack, StackKits gains the Unifier pipeline, a web wizard, and automatic StackKit resolution.

```
User → kombify Stack UI (Wizard)
    → kombination.yaml (generated)
    → Unifier Pipeline:
        1. Parse IntentSpec
        2. Resolve StackKit (auto-detect from topology)
        3. Detect & merge Add-Ons
        4. CUE validation + unification
        5. Generate IaC artifacts
        6. Queue provisioning job
```

**Capabilities (beyond Level 0):**
- Web-based configuration wizard
- Automatic StackKit selection based on declared topology
- Add-On detection and automatic activation (e.g., cloud nodes → `cloud-integration` add-on)
- Visual service graph
- Job queue for async provisioning
- State persistence (PocketBase)
- Multi-user access

### Level 2: Worker Agent Integration

When nodes run the kombify agent, the system gains real-time hardware awareness and placement intelligence.

```
Node boots → Agent starts → gRPC Register(capabilities)
    → kombify Stack updates Worker Registry
    → Placement Engine runs filter + score
    → Services placed optimally across nodes
    → Agent executes commands via CommandStream
```

**Capabilities (beyond Level 1):**
- Real-time Node-Context auto-detection (via agent hardware reports)
- Kubernetes-inspired placement engine (filter → score)
- Capability-based service placement (GPU, ARM, storage)
- Live health monitoring via heartbeats
- Command execution without SSH (gRPC CommandStream)
- Pre-flight checks before provisioning (`RunPreChecks` RPC)

**Agent Protocol (gRPC + mTLS):**
```protobuf
service AgentService {
    rpc Register(RegisterRequest) returns (RegisterResponse);
    rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);
    rpc CommandStream(stream CommandRequest) returns (stream CommandResponse);
    rpc ReportStatus(StatusReport) returns (StatusResponse);
    rpc RunPreChecks(PreCheckRequest) returns (PreCheckResponse);
}
```

### Level 3: Runtime Intelligence

Day-2 operations with continuous monitoring, drift detection, and automatic remediation.

```
Agent heartbeat → Health data → kombify Stack
    → Anomaly detected (service down, disk full, cert expiring)
    → Remediation plan generated
    → User approves (or auto-remediation if enabled)
    → CommandStream executes fix
    → Status verified
```

**Capabilities (beyond Level 2):**
- Continuous drift detection (IaC state vs actual)
- Certificate auto-renewal orchestration
- Service health monitoring and auto-restart
- Resource scaling recommendations
- Configuration change rollback
- Multi-node rolling updates
- Backup verification and rotation

### Level 4: AI-Assisted Operations (SaaS-only)

Available exclusively through **kombify Sphere** (the SaaS platform). Uses AI to provide predictive operations and natural language configuration.

```
User: "Add monitoring to my homelab"
    → NLP intent parsing
    → Matching Add-On: monitoring (Prometheus + Grafana)
    → Compatibility check: StackKit=base, Context=local ✓
    → Resource check: 512MB available ✓
    → Generate kombination.yaml diff
    → User approves → Unifier pipeline → Deploy
```

**Capabilities (beyond Level 3):**
- Natural language infrastructure configuration
- Predictive scaling based on usage patterns
- Anomaly detection with ML models
- Cost optimization for cloud contexts
- Security vulnerability scanning and patching
- Community intelligence (anonymized best practices)

**SaaS-only rationale:** Level 4 requires ML model serving, training data aggregation, and continuous model updates that are impractical for self-hosted deployments.

---

## 4. Lifecycle Integration

### Day 0 → Day 1 → Day 2+ Flow

```
DAY 0: PLANNING                     DAY 1: PROVISIONING              DAY 2+: OPERATIONS
(kombify Stack or CLI)               (StackKits)                      (kombify Stack)
                                                                       
┌──────────────────┐                ┌──────────────────┐             ┌──────────────────┐
│ User Intent      │                │ CUE Validation   │             │ Health Monitoring │
│ • What services? │───────────────▶│ • Schema checks  │            │ • Heartbeats     │
│ • How many nodes?│  kombination   │ • Constraint      │            │ • Drift detect   │
│ • Cloud or local?│    .yaml       │   resolution     │            │ • Cert renewal   │
└──────────────────┘                │ • Default merging │            └──────────────────┘
                                    └────────┬─────────┘                     │
                                             │                               │
                                    ┌────────▼─────────┐             ┌───────▼──────────┐
                                    │ IaC Generation    │             │ Change Management│
                                    │ • main.tf         │             │ • Plan changes   │
                                    │ • docker-compose  │             │ • Apply updates  │
                                    │ • bootstrap.sh    │             │ • Rollback       │
                                    └────────┬─────────┘             └──────────────────┘
                                             │
                                    ┌────────▼─────────┐
                                    │ Provisioning      │
                                    │ • tofu apply      │
                                    │ • Or: Agent exec  │
                                    └──────────────────┘
```

**Responsibility Boundaries:**
- **kombify Stack** owns: User interaction, Unifier pipeline, job queue, state, web UI, agent management
- **StackKits** owns: CUE schemas, validation rules, defaults, templates, IaC generation logic
- **kombify Stack** returns after Day 1: Day-2 operations, monitoring, change management

### Integration Mode (Auto-Determined)

The integration mode is **not a user choice**. It is determined automatically by how the user accesses StackKits:

| Access Method | Integration Mode | Capability Level |
|---------------|-----------------|------------------|
| `stackkit` CLI directly | Standalone | Level 0 |
| kombify Stack API/UI | Integrated | Level 1+ |
| kombify Stack + Agent | Full | Level 2+ |
| kombify Sphere (SaaS) | AI-Assisted | Level 4 |

---

## 5. CUE Schema Architecture

### Module Structure

```
github.com/kombihq/stackkits/
├── base/                           # Core schemas (Layer 1 + 2)
│   ├── stackkit.cue               # #BaseStackKit definition
│   ├── system.cue                 # #SystemConfig
│   ├── network.cue                # #NetworkDefaults, #TraefikDefaults
│   ├── security.cue               # #SSHHardening, #FirewallPolicy
│   ├── identity.cue               # #LLDAPConfig, #StepCAConfig
│   ├── observability.cue          # #ObservabilityConfig
│   ├── validation.cue             # Reusable validators
│   └── layers.cue                 # 3-layer validation
│
├── addons/                         # Add-On modules (NEW)
│   ├── monitoring/addon.cue
│   ├── backup/addon.cue
│   ├── vpn-overlay/addon.cue
│   └── ...
│
├── contexts/                       # Context defaults (NEW)
│   ├── local.cue                  # Local hardware defaults
│   ├── cloud.cue                  # Cloud provider defaults
│   └── pi.cue                     # Raspberry Pi defaults
│
├── base-homelab/                   # Base Kit
│   ├── stackfile.cue
│   ├── services.cue
│   └── defaults.cue
│
├── modern-homelab/                 # Modern Homelab Kit
│   ├── stackfile.cue
│   ├── services.cue
│   └── defaults.cue
│
└── ha-homelab/                     # High Availability Kit
    ├── stackfile.cue
    ├── services.cue
    └── defaults.cue
```

### Schema Derivation Chain

```
L3 (User Intent) + StackKit Pattern
    → L2 (Platform decision: Docker/Swarm/K8s, PAAS, networking)

L2 (Platform) + Node-Context (local/cloud/pi)
    → L1 (Foundation: packages, security, identity config)

L1 (Foundation) + Add-Ons
    → Resolved Configuration (fully validated, ready for IaC generation)
```

### 3-Layer Architecture (Preserved)

The proven 3-layer architecture remains the structural backbone:

| Layer | Name | Responsibility | Managed By |
|-------|------|---------------|------------|
| **L1** | Foundation | System, security, packages, core identity (LLDAP, Step-CA) | OpenTofu |
| **L2** | Platform | Container runtime, PAAS, ingress, platform identity | OpenTofu |
| **L3** | Applications | User services deployed by PAAS | PAAS (Dokploy/Coolify) |

---

## 6. StackKit Redefinitions

### Base Kit (Single-Environment Pattern)

**Philosophy:** Everything runs in one logical environment. Simple, predictable, easy to reason about. Works identically on a home server or cloud VPS.

| Aspect | Definition |
|--------|-----------|
| **Pattern** | All services co-located in a single deployment target |
| **Container Runtime** | Docker Compose |
| **PAAS** | Dokploy (local) or Coolify (cloud) — context-driven |
| **Networking** | Single Docker network, Traefik ingress |
| **Identity** | LLDAP + Step-CA (L1), TinyAuth (L2) |
| **Node Count** | Typically 1, but supports N (all running same stack) |
| **Best For** | First homelab, single VPS, learning, solo server |

### Modern Homelab Kit (Hybrid Infrastructure Pattern)

**Philosophy:** Bridge multiple environments. Always includes a local component ("homelab") bridged with cloud resources via overlay network.

| Aspect | Definition |
|--------|-----------|
| **Pattern** | Distributed services across heterogeneous environments |
| **Container Runtime** | Docker Compose per node, coordinated by Coolify |
| **PAAS** | Coolify (required for multi-node) |
| **Networking** | VPN overlay (Headscale/Tailscale), split DNS |
| **Identity** | LLDAP + Step-CA (L1), Authelia/Authentik (L2) |
| **Node Count** | 2+ (at least one local, one remote) |
| **Best For** | Hybrid setups, public-facing services, growing homelabs |

### High Availability Kit (HA Cluster Pattern)

**Philosophy:** No single point of failure. Services survive node failures. Data is replicated.

| Aspect | Definition |
|--------|-----------|
| **Pattern** | Clustered services with quorum, failover, and replication |
| **Container Runtime** | Docker Swarm (or Kubernetes at scale) |
| **PAAS** | Coolify (cluster-aware) |
| **Networking** | Swarm overlay + Keepalived VIP |
| **Identity** | LLDAP cluster + Step-CA HA (L1), Authentik (L2) |
| **Node Count** | 3+ (odd number for quorum) recommended |
| **Best For** | Production workloads, critical services, uptime SLAs, startups |

---

## 7. Add-On Taxonomy

### Core Add-Ons (maintained by kombify team)

| Add-On | Category | Compatible StackKits | Compatible Contexts | Description |
|--------|----------|---------------------|--------------------|----|
| `monitoring` | Observability | base, modern, ha | local, cloud | Prometheus + Grafana + Alertmanager |
| `backup` | Data | base, modern, ha | local, cloud, pi | Restic + configurable targets |
| `vpn-overlay` | Networking | modern, ha | local, cloud | Headscale/Tailscale mesh |
| `gpu-workloads` | Compute | base, modern | local, cloud | NVIDIA/AMD GPU passthrough |
| `ci-cd` | Development | base, modern, ha | local, cloud | Gitea + Drone CI |
| `media` | Applications | base, modern | local, cloud, pi | Jellyfin + *arr stack |
| `smart-home` | IoT | base | local, pi | Home Assistant + MQTT + Zigbee2MQTT |
| `cloud-integration` | Hybrid | modern | cloud | Cloud provider API integration |

### Auto-Detected Add-Ons

Some add-ons are automatically activated based on Node-Context or StackKit pattern:

| Condition | Auto-Activated Add-On |
|-----------|-----------------------|
| Any node has `context: cloud` | `cloud-integration` |
| Any node is ARM architecture | `arm-support` |
| Any node has < 2GB RAM | `low-memory` |
| StackKit pattern is `modern` | `vpn-overlay` |
| Node reports GPU capability | `gpu-workloads` |
| Node count > 1 | `multi-node` |

### Community Add-Ons

Third-party add-ons follow the same schema and can be published to the Add-On registry (Level 1+). At Level 0, community add-ons are installed from Git repositories:

```bash
stackkit addon add https://github.com/user/my-addon.git
```

---

## 8. kombination.yaml Spec (Updated)

```yaml
# kombination.yaml — the single source of user intent
version: "2.0"

# 1. StackKit selection (architecture pattern)
stackkit: base                          # base | modern | ha

# 2. Context (auto-detected at Level 2+, manual at Level 0)
context: local                          # local | cloud | pi (optional, auto-detected)

# 3. Basic configuration
domain: homelab.example.com
timezone: Europe/Berlin

# 4. Node topology (Level 0: manual, Level 2+: from agent registration)
nodes:
  - name: homeserver
    host: 192.168.1.100
    role: primary                       # primary | worker | storage
    # context: auto-detected or manually specified

# 5. Add-Ons (explicit selection + auto-detection)
addons:
  - monitoring                          # Prometheus + Grafana
  - backup                             # Restic backups

# 6. Service overrides (optional, everything has smart defaults)
services:
  traefik:
    dashboard: true
  monitoring:                           # From monitoring add-on
    retention: 30d
```

---

## 9. Migration from v3 to v4

### What Changes

| v3 Concept | v4 Replacement | Migration |
|------------|---------------|-----------|
| Variants (`coolify.cue`, `minimal-compute.cue`) | Add-Ons (`addons/`) | Extract variant logic into composable add-on modules |
| Node-count-based StackKits | Pattern-based StackKits | Rename/restructure: logic stays, framing changes |
| `simple` / `advanced` mode | Progressive Capability (Levels 0–4) | Mode is auto-determined by access method |
| Manual compute tier selection | Context auto-detection | Context replaces tier; detected from hardware |
| Monolithic `defaults.cue` per StackKit | `defaults.cue` + `contexts/*.cue` | Split context-specific defaults into context modules |
| `platforms/` directory | Merged into `base/` schemas | Platform config is part of Layer 2, not separate |

### What Stays

- **3-Layer Architecture** (L1 Foundation, L2 Platform, L3 Applications)
- **CUE as validation engine** and constraint-based configuration
- **OpenTofu as IaC execution engine**
- **Terramate for orchestration** (Day-2 operations)
- **Service classification** (L2 = Terraform-managed, L3 = PAAS-managed)
- **Settings classification** (Perma vs Flexible)
- **kombination.yaml** as user intent specification

---

## 10. Implementation Priority

### P0: Foundation (Weeks 1–4)

1. Create `addons/` directory structure with CUE schema
2. Create `contexts/` directory with local/cloud/pi defaults
3. Refactor `base-homelab/` variants into add-ons (Base Kit)
4. Fix CUE package declaration bugs (`base/platform/*.cue`, `base/schema/*.cue`)
5. Align Go↔CUE naming (compute tiers, platform types)
6. Complete Base Kit E2E testing

### P1: StackKit Alignment (Weeks 5–8)

7. Redefine `modern-homelab` as Modern Homelab Kit (hybrid infrastructure pattern)
8. Redefine `ha-homelab` as High Availability Kit (HA cluster pattern)
9. Implement context-driven defaults resolution in CUE
10. Update `stackkit` CLI for Add-On support (`stackkit addon add/list/remove`)
11. Align CUE module path with kombify Stack (`github.com/kombihq/stackkits`)

### P2: Integration (Weeks 9–12)

12. Update kombify Stack Unifier for v4 StackKit format
13. Update kombify Stack resolver for pattern-based selection
14. Implement Add-On detection in Unifier pipeline
15. Update kombify Stack web wizard for 3-concept model
16. Add Context auto-detection via agent hardware reports

### P3: Operations (Weeks 13–16)

17. Implement Day-2 drift detection for Add-On configurations
18. Add Add-On marketplace in kombify Sphere
19. Community Add-On contribution workflow
20. Documentation and migration guides

---

## Related Documents

- [Evaluation Report 2026-02-07](./EVALUATION_REPORT_2026-02-07.md) — Current state assessment
- [Architecture v3.0](./architecture.md) — Previous architecture (superseded)
- [ROADMAP.md](./ROADMAP.md) — Implementation roadmap
- [ADR-0003: PAAS Strategy](./ADR/ADR-0003-paas-strategy.md) — PAAS selection rationale
- kombify Stack: [kombify Stack-Core.md](https://github.com/kombify/kombify Stack/docs/concepts/kombify Stack-Core.md) — Unifier and control plane architecture
