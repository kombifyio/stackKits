# StackKits Business Plan Draft

> **Version:** 1.0  
> **Date:** February 2026  
> **Status:** Draft

---

## Executive Summary

**StackKits** provides declarative infrastructure blueprints for homelab and self-hosted deployments. Built on **CUE** for validation, **OpenTofu** for provisioning, and **Terramate** for orchestration, StackKits delivers pre-validated, reproducible infrastructure configurations that eliminate common deployment failures.

### The Problem

- Most homelab setups fail on the first attempt due to configuration errors
- YAML-based configurations lack validation – errors surface only at runtime
- No standardization – every setup is a fragile, undocumented custom build
- Self-hosting requires deep DevOps knowledge that most users lack
- Debugging misconfigurations consumes hours or days

### The Solution

StackKits addresses these problems through:

- **Pre-validated Blueprints** – CUE-based schema validation catches errors before deployment
- **3-Layer Architecture** – Clear separation of Foundation, Platform, and Application concerns
- **IaC-First Approach** – OpenTofu as the execution engine with Terramate for orchestration
- **Reproducible Deployments** – From intent to running infrastructure in minutes

---

## Market Analysis

### Target Market

| Segment | Description |
|---------|-------------|
| **Primary** | Homelab enthusiasts and self-hosters seeking reliable infrastructure |
| **Secondary** | Small businesses requiring cost-effective self-hosted solutions |
| **Tertiary** | Developers learning infrastructure-as-code practices |

### Market Drivers

1. **Privacy Awareness** – Post-GDPR consciousness driving data sovereignty
2. **Cloud Cost Escalation** – Public cloud pricing increases pushing workloads on-premise
3. **AI Workloads** – Local LLM deployments requiring self-hosted infrastructure
4. **Remote Work** – Home office setups demanding reliable local services

### Competitive Landscape

StackKits occupies a unique position. It is not a deployment tool competing with Ansible, Portainer, or Coolify. Rather, it provides **validated infrastructure blueprints** that may include such tools as components.

| Category | Examples | StackKits Relationship |
|----------|----------|----------------------|
| Configuration Management | Ansible, Puppet | StackKits validates configs before these tools execute |
| Container Platforms | Docker, Podman | Used within StackKits blueprints as runtime |
| PaaS Solutions | Dokploy, Coolify | Included as Layer 2 components in blueprints |
| Reverse Proxies | Traefik, Caddy | Included as Layer 2 components in blueprints |

**StackKits' differentiation:** Pre-deployment validation through CUE schemas – no other homelab solution validates configurations before execution.

---

## Product and Technology

### Core Technology Stack

| Technology | Role | Version |
|------------|------|---------|
| **CUE** | Schema definition and validation | v0.9+ |
| **OpenTofu** | Infrastructure provisioning engine | v1.6+ |
| **Terramate** | Multi-stack orchestration and drift detection | v0.6+ |

These three technologies form the core of StackKits. Everything else (Docker, Traefik, Dokploy, etc.) are tools configured within the blueprints.

### Product Portfolio

| StackKit | Description | Status |
|----------|-------------|--------|
| **base-homelab** | Single-server deployment with Docker platform | Available |
| **modern-homelab** | Multi-node hybrid topology | Planned (v1.1) |
| **ha-homelab** | High-availability Docker Swarm cluster | Planned (v1.1) |

### Unique Value Propositions

1. **Validate Before Deploy** – CUE schemas catch configuration errors before any infrastructure is provisioned
2. **3-Layer Architecture** – Reusable, modular blueprints with clear separation of concerns
3. **Open Source Foundation** – Apache 2.0 licensed, community-driven development
4. **Day-2 Operations** – Built-in drift detection and lifecycle management via Terramate

---

## Business Model

### Revenue Streams

| Stream | Description |
|--------|-------------|
| **Open Source Core** | base-homelab and CLI tools remain free (Apache 2.0) |
| **Professional Services** | Consulting, custom blueprint development, training |
| **Enterprise Support** | SLA-backed support for organizations |

### Go-to-Market Strategy

**Phase 1: Community Building**
- Open source release on GitHub
- Community engagement via Reddit (r/selfhosted, r/homelab)
- Technical content marketing: tutorials, documentation, blog posts
- Discord community for support and feedback

**Phase 2: Adoption Growth**
- Integration partnerships with hosting providers
- Contribution program for community blueprints
- Workshop and training offerings

---

## Financial Projections

### 5-Year Outlook (Conservative)

| Year | Focus | Key Milestone |
|------|-------|---------------|
| 2026 | Foundation | Production-ready base-homelab, community building |
| 2027 | Growth | Multi-node StackKits, initial consulting revenue |
| 2028 | Expansion | Enterprise features, professional services scaling |
| 2029 | Maturity | Sustainable revenue, market leadership in homelab IaC |
| 2030 | Scale | International expansion, ecosystem development |

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Technology shift (e.g., Kubernetes dominance) | Medium | High | Architecture designed for platform abstraction |
| Slow community adoption | Medium | High | Strong content marketing, developer advocacy |
| Competing solutions emerge | High | Medium | Rapid iteration, community moat through contributions |

---

## Milestones and Timeline

| Quarter | Milestone |
|---------|-----------|
| Q1 2026 | base-homelab v1.0 release |
| Q2 2026 | Community growth, documentation completion |
| Q3 2026 | modern-homelab development |
| Q4 2026 | Multi-node support, initial professional services |
| 2027+ | Enterprise features, ecosystem expansion |

---

## Conclusion

StackKits addresses a growing market need with a technically differentiated approach. The combination of CUE-based validation, OpenTofu execution, and Terramate orchestration creates a unique value proposition in the homelab and self-hosting space. By focusing on infrastructure blueprints rather than competing as another deployment tool, StackKits establishes a sustainable competitive position.

---

*This document is a working draft and will be updated as the project evolves.*
