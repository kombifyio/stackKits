# PRODUKT-PLAN

# TARGET_STATE: StackKits Product Plan

## 1. Vision Statement

StackKits is the standardization system for homelab and self-hosted infrastructure, built from declarative, pre-validated infrastructure blueprints. It enables technically minded users to reliably deploy modern homelab environments – from simple single-server setups to highly available multi-node architectures – without needing to master every detail of Terraform/OpenTofu, Docker, or Swarm. StackKits forms the technical foundation of the kombify Stack / Kombify product family and integrates into a broader multi-repo ecosystem.

## 2. Core Value Proposition

1. **Error-free configuration before deployment**

   CUE-based validation ensures that configurations are logically and technically consistent _before_ any infrastructure is provisioned. This dramatically reduces the risk of misconfigurations and rollbacks.

2. **Standardized homelab blueprints for common scenarios**

   Three initial homelab templates (Base, Modern, High Availability) provide well-defined, reusable architecture patterns for typical use cases such as self-hosted services, AI workloads, media storage, and personal PaaS.

3. **Multi-layer infrastructure abstraction**

   The three-layer architecture (OS → Platform → Application) clearly separates base operating system, orchestration platform (Docker, Docker Swarm), and service layer. This improves reuse, extensibility, and maintainability.

4. **Flexible deployment modes (Simple vs. Advanced)**
   - **Simple Mode:** Straightforward OpenTofu/Terraform execution for smaller or simpler setups.
   - **Advanced Mode:** Terramate-driven orchestration, change detection, and drift detection for more complex, multi-stack and multi-node deployments.
5. **Intention- and template-driven user experience**

   Users describe their intent (for example, “AI-first homelab”, “photo cloud & backup”, “self-hosted PaaS”), and StackKits selects suitable templates, tools, and system requirements automatically.

## 3. Functional Requirements (Target State)

### 3.1 Homelab Blueprints and Scenarios

**FR1 – Base Homelab Template**

- Single-server deployment (local server or cloud VPS).
- Ubuntu (or supported OS variants) with pre-configured Docker installation.
- Baseline monitoring (for example Uptime Kuma / Netdata / Glances) and security hardening out of the box.
- At least one primary service, chosen based on user intent (for example Immich, Nextcloud, cloud storage, AI service).
- Validated networking and storage base configuration.

**FR2 – Modern Homelab Template**

- At least two nodes: one local server and one cloud server.
- Clear separation between:
  - local, private data (for example smart home, local file storage)
  - externally reachable services (for example personal AI assistant, websites, APIs).
- Flexible assignment of components to nodes (for example UI in the cloud, compute-heavy models on local hardware).
- Extended network and access configuration for different user groups (private, family/friends, public).

**FR3 – High Availability Homelab Template**

- At least three nodes using Docker Swarm for cluster orchestration.
- High availability mechanisms (manager quorum, replicated services).
- Multiple storage strategies (self-storage, central storage, distributed/decentralized storage).
- Built-in load balancing, ingress/proxy configuration (for example via Traefik).
- Enhanced backup and recovery strategies (snapshots, offsite backups, disaster-recovery flows).

### 3.2 Three-Layer Architecture (OS / Platform / Application)

**FR4 – OS Layer (Layer 1)**

- Support for Ubuntu (extendable to other distributions such as Debian).
- Unified base configuration:
  - Network basics (interfaces, firewall rules, SSH access).
  - Storage configuration (mounts, filesystems, base paths).
  - Compute tier profiles (high / standard / low) with predefined resource limits.
- Installation of standard tools (wget, curl, htop and similar).
- Automatic security updates and package management.
- SSH hardening, firewall (UFW), and Fail2ban integration.

**FR5 – Platform Layer (Layer 2)**

- Docker as the primary platform for the first three StackKits.
- Standardized Docker networks, volumes, and security defaults.
- Optional PaaS layer:
  - Supported Docker-based PaaS options such as Dokploy and Coolify, with room for additional alternatives.
- Abstracted platform interfaces to support future orchestration backends without rewriting core service logic.

**FR6 – Application Layer (Layer 3)**

- Services defined as modular building blocks:
  - Self-hosted tools (for example photo services, file storage, AI stacks, monitoring, logging, etc.).
- Clear dependency modeling to Layer 2 (for example Docker resources, Swarm services).
- Configuration profiles:
  - **Standard profile** per service.
  - Optional **alternative profiles** per category (for example “photo service: Immich OR alternative X”).

### 3.3 Tooling, Interfaces and User Experience

**FR7 – StackKits CLI Tool**

- Core commands (examples):
  - `stackkit init`: Initialize workspace/repo and generate base layout.
  - `stackkit validate`: Run CUE validation against unified/stack specification.
  - `stackkit plan`: Generate OpenTofu/Terraform plans.
  - `stackkit apply`: Apply infrastructure changes.
  - `stackkit drift`: Perform drift detection based on detailed exit codes.
  - `stackkit list`: List available StackKits, templates, and add-ons.
- Support for:
  - **Simple Mode:** Direct OpenTofu execution in a single stack context.
  - **Advanced Mode:** Terramate-based orchestration of multiple stacks, including change-based execution, parallelism, and dependency ordering.

**FR8 – API Module**

- Remote API (optionally fronted by Kong or a similar gateway) that:
  - Exposes a subset of CLI capabilities for remote execution.
  - Enables integration with web UIs, automation tools, and external systems.
- Authentication and authorization model for safe remote operations.

**FR9 – UI / Wizard Integration (for example Kombify / Compify)**

- Intent-driven wizard interface:
  - Users describe their goal (“AI-first homelab”, “self-hosted PaaS”, “photo cloud + backup”).
  - The UI generates a unified specification or stack specification based on decision rules.
- Display of chosen standard tools and available alternatives.
- Ability to attach add-ons and, where technically safe, replace tools within defined compatibility rules.

### 3.4 Standardization, Alternatives and Add-Ons

**FR10 – Standards and Alternatives**

- For each category (photo service, PaaS, monitoring, backup, etc.):
  - Exactly one **standard option** (default when the user does not choose explicitly).
  - Optional **alternative options**, where technically compatible and meaningful.
- Configuration rules must define:
  - Which tools can be combined in one stack.
  - Which tools are mutually exclusive.
  - What the fallback behavior is when a chosen alternative is not compatible with other decisions.

**FR11 – Add-On Concept**

- Add-ons extend an existing StackKit rather than defining a completely new one.
- Example add-on types:
  - Additional server roles (for example an extra node in Modern Homelab).
  - Additional service bundles (logging stack, extended monitoring, AI toolchains, multi-region backup, etc.).
- Clear boundary between:
  - **Base StackKit:** Stable, curated default configuration.
  - **Add-Ons:** Optional, versioned extensions using well-defined interfaces.
- Selected tools may be swappable through add-ons (tool replacement) where the abstraction allows it, for example alternative monitoring stack.

### 3.5 Domain, DNS and Access Management

**FR12 – Domain and DNS Management**

- Support for the following access patterns:
  - Own domain per user or homelab.
  - Local-only setups (LAN) with no public exposure.
  - Hybrid setups with both external and private endpoints.
- Evaluation and potential integration of tools such as MagicDNS or similar to simplify name resolution.
- Central configuration surface (admin/config module) for domains, DNS, and certificate handling.

### 3.6 Open Source, Repository Structure and Automation

**FR13 – Open-Source-First Repository Strategy**

- StackKits provided as open-source repositories (for example on GitHub).
- Clear repository layout, for example:
  - `/core` – CUE schemas, core validation logic, shared types.
  - `/platforms` – Docker and Docker Swarm platform definitions.
  - `/stacks` – base-homelab, modern-homelab, ha-homelab, add-ons.
  - `/docs` – STATUS*[QUO.md](http://QUO.md), TARGET*[STATE.md](http://STATE.md), how-tos, architecture docs.
- Conventions for contributions, versioning, and compatibility guarantees.

**FR14 – Automated StackKit Updates**

- Versioning of StackKits and individual services.
- Upgrade paths that avoid breaking changes for existing installations wherever possible.
- Commands or workflows such as `stackkit update` to:
  - Fetch new versions.
  - Run compatibility checks.
  - Apply upgrades in a controlled manner.

## 4. Technical Constraints

1. **Technology stack**
   - CUE as the central validation and configuration modeling language.
   - OpenTofu/Terraform as the infrastructure-as-code engine.
   - Docker and Docker Swarm as the orchestration platforms (per ADR-0002).
   - Terramate for advanced orchestration, change detection, parallel execution, and drift detection.
2. **Scalability and performance**
   - Support from single-node setups to multi-node clusters (3+ nodes).
   - Configurable compute tiers (high / standard / low) that scale resource usage based on hardware.
   - Terramate-based parallel execution where safe, while preserving strict dependency ordering between stacks.
3. **Security**
   - SSH key-only access by default (password logins disabled).
   - Secure defaults enabled from the start (firewall, TLS where applicable, no secrets in plain text within repos).
   - TLS support:
     - **Public mode:** ACME/Let’s Encrypt via Traefik.
     - **Local mode:** Self-signed certificates with clear documentation and automated provisioning.
4. **Maintainability and extensibility**
   - Strict separation of layers enforces reuse and minimizes duplication.
   - Add-on model allows growth of the ecosystem without destabilizing the core.
   - New templates must plug into existing validation and deployment pipelines instead of inventing new ad-hoc flows.

## 5. Integration Map (Multi-Repo Ecosystem)

1. **kombify Stack / Unifier / StackKits Core**
   - StackKits consume unified specifications produced by the Unifier or wizard tooling.
   - The Unifier merges specifications, defaults, and user decisions into validated stack specifications that drive StackKits.
2. **Kombify / Compify UI**
   - Frontend wizards use the API to:
     - Propose appropriate StackKits and templates.
     - Show tool combinations and available alternatives.
   - The primary user experience is driven from the UI, while the CLI remains the power-user interface.
3. **Admin / Configuration Center**
   - Central management of:
     - Tool evaluations (which tools are standard, which are experimental).
     - Domain and DNS configurations.
     - Global defaults for specific user segments or tenants.
4. **Documentation, Website and Communication Repos**
   - Dedicated documentation repositories for:
     - Technical guides (STATUS_QUO, TARGET_STATE, runbooks).
     - Public website that explains StackKits, templates, add-ons, and upgrade paths.

## 6. Future Components (Planned)

1. **Additional Platform Layers**
   - Potential support for additional orchestration platforms beyond Docker/Swarm.
   - Dedicated homelab templates for specialized AI and service workloads.
2. **Add-On Library / Marketplace**
   - Curated collection of add-ons (monitoring packages, logging stacks, security hardening, AI bundles, etc.).
   - Potential for community-contributed add-ons with quality and compatibility checks.
3. **Advanced Admin Center**
   - UI to manage tool lifecycles (experimental → beta → stable).
   - Version rollout and upgrades across multiple homelabs or environments.
4. **Interactive Terminal UI / Dashboard**
   - Visualization of:
     - Stack dependencies.
     - Deployment progress and history.
     - Drift reports.
     - Health status and log aggregation.
