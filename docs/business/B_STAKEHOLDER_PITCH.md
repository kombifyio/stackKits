# StackKits – Stakeholder Pitch

> **Investment and Partnership Overview**  
> **February 2026**

---

## The One-Liner

**StackKits delivers pre-validated infrastructure blueprints for homelabs – making Infrastructure-as-Code accessible to everyone.**

---

## The Problem

Self-hosting and homelab infrastructure suffers from a fundamental issue: **configurations are never validated before deployment**.

Users write YAML files, run `docker-compose up`, encounter errors, search for solutions, modify configurations, and repeat. This trial-and-error cycle consumes significant time and discourages adoption.

The root causes:

- **No validation layer** – YAML and Docker Compose have no schema enforcement
- **Fragmented knowledge** – Solutions scattered across forums, outdated tutorials, and Reddit threads
- **Complex interdependencies** – Operating system, networking, containers, and applications must work together
- **No standards** – Every homelab is a unique, undocumented configuration

---

## The Solution

StackKits introduces a validation layer between user intent and infrastructure deployment.

### Core Technology

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Validation** | CUE | Schema definition and constraint enforcement |
| **Provisioning** | OpenTofu | Infrastructure-as-Code execution |
| **Orchestration** | Terramate | Multi-stack management and drift detection |

### The Workflow

1. User defines intent in a simple specification file
2. CUE validates the configuration against comprehensive schemas
3. Errors are reported with actionable fixes **before** any deployment
4. OpenTofu provisions the validated infrastructure
5. Terramate enables ongoing management and drift detection

### Key Differentiator

**Validation happens before deployment.** Unlike every other homelab solution, StackKits catches misconfigurations, type errors, and constraint violations before any infrastructure is touched.

---

## What StackKits Is (and Is Not)

### StackKits IS:

- A collection of validated infrastructure blueprints
- A schema library defining homelab best practices
- An IaC-first approach to self-hosted infrastructure
- Open source (Apache 2.0 for core components)

### StackKits IS NOT:

- Another deployment tool (not competing with Ansible, Portainer, etc.)
- A PaaS platform (not competing with Dokploy, Coolify, etc.)
- A container orchestrator (not competing with Docker Swarm, Kubernetes)

**StackKits blueprints may include tools like Dokploy, Traefik, or Docker as components**, but these are implementation details, not the product itself.

---

## Market Opportunity

### Target Segments

| Segment | Size | Need |
|---------|------|------|
| Homelab Enthusiasts | Growing community | Reliable, documented setups |
| Self-hosters | Privacy-conscious users | Data sovereignty solutions |
| Small Businesses | Cost-sensitive organizations | Affordable infrastructure |
| Developers | Learning IaC | Practical, working examples |

### Market Drivers

- **Privacy regulations** driving data localization
- **Cloud cost increases** pushing workloads on-premise
- **AI democratization** requiring local compute infrastructure
- **Remote work** normalizing home-based technical setups

---

## Product Status

### Currently Available

- **base-homelab** – Single-server Docker deployment blueprint
- **CUE Schema Library** – Comprehensive validation schemas for:
  - Security (SSH hardening, firewall, container security)
  - Networking (DNS, proxy, VPN configurations)
  - Identity (LDAP, PKI, authentication)
  - Observability (logging, monitoring, health checks)
- **3-Layer Architecture** – Documented separation of Foundation, Platform, and Application layers

### In Development

- **dev-homelab** – Development and testing environment
- **CLI tooling** – User-friendly command-line interface

### Planned

- **modern-homelab** – Multi-node hybrid deployments
- **ha-homelab** – High-availability cluster configurations

---

## Business Model

### Open Source Core

The foundational StackKits and tooling remain open source under Apache 2.0. This approach:

- Builds community trust and adoption
- Enables contributions and improvements
- Establishes StackKits as the standard for homelab IaC

### Revenue Opportunities

| Stream | Description |
|--------|-------------|
| Professional Services | Custom blueprint development, consulting |
| Training | Workshops, certification programs |
| Enterprise Support | SLA-backed support for organizations |
| Partnerships | Hosting provider integrations |

---

## Why Now

Several factors create favorable timing:

1. **CUE maturity** – The language has reached production stability (v0.9+)
2. **OpenTofu momentum** – Community fork of Terraform with strong adoption
3. **Self-hosting growth** – Privacy concerns and cloud costs driving the trend
4. **No existing solution** – No one else addresses validation-first infrastructure for homelabs

---

## Team Requirements

To execute on this vision, key roles include:

| Role | Focus |
|------|-------|
| Technical Lead | CUE, Go, infrastructure engineering |
| Developer Relations | Community building, content creation |
| Product Management | Roadmap, user research |

---

## Call to Action

### For Potential Partners

Hosting providers, infrastructure vendors, and technology companies benefit from easier customer onboarding. StackKits makes your platforms more accessible.

### For Contributors

StackKits welcomes contributions to schemas, blueprints, documentation, and tooling. Join the community at github.com/kombihq/stackkits.

### For Advisors

We seek guidance from those experienced in developer tools, open source business models, and infrastructure technology.

---

**StackKits: Validated infrastructure blueprints for the self-hosting community.**
