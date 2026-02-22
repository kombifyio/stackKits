# StackKits – User Guide and Introduction

> **For Homelab Enthusiasts and Self-Hosters**  
> **Your infrastructure, validated before deployment**

---

## What is StackKits?

StackKits provides **pre-validated infrastructure blueprints** for homelab and self-hosted deployments. Instead of assembling configurations through trial and error, you start with a tested, documented blueprint that validates your settings before any deployment occurs.

### The Core Concept

Traditional homelab setup:

1. Write configuration files
2. Attempt deployment
3. Encounter errors
4. Search for solutions
5. Modify and retry
6. Repeat until it works (or give up)

StackKits approach:

1. Select a blueprint matching your needs
2. Customize your settings
3. **Validate** – errors reported with specific fixes
4. Deploy with confidence
5. Working infrastructure

The key difference: **validation happens before deployment**, not after.

---

## How It Works

### The Technology Foundation

StackKits builds on three proven technologies:

| Technology | Role |
|------------|------|
| **CUE** | Configuration language with built-in validation. Developed by Google, CUE enforces types, constraints, and relationships in your configuration. |
| **OpenTofu** | Open-source infrastructure provisioning. The community fork of Terraform, OpenTofu executes the validated configuration to create your infrastructure. |
| **Terramate** | Stack orchestration and management. Handles multi-stack deployments, change detection, and drift monitoring. |

### The Validation Difference

When you define a configuration, CUE schemas check it against comprehensive rules:

```
Your configuration:               Validation result:
─────────────────                ──────────────────

security:                        Error: ssh.port out of range
  ssh:                              Expected: 1-65535
    port: 70000                     Got: 70000
                                    
                                 Error: passwordAuth requires
                                    maxAuthTries <= 3 when enabled
```

Errors are reported with context, expected values, and suggested fixes – before any infrastructure is touched.

---

## Available StackKits

### base-homelab

A single-server deployment providing:

- Docker container platform
- Reverse proxy with automatic TLS
- PaaS interface for application deployment
- Foundation security (SSH hardening, firewall)
- Observability (logging, health monitoring)

**Requirements:**
- One server (physical, VM, or VPS)
- Ubuntu 24.04 LTS recommended
- Minimum 4GB RAM, 50GB storage

**Status:** Available

### modern-homelab (Planned)

Multi-node deployment for hybrid topologies (local + cloud servers).

**Status:** Planned for v1.1

### ha-homelab (Planned)

High-availability configuration with Docker Swarm clustering.

**Status:** Planned for v1.1

---

## The 3-Layer Architecture

StackKits organizes infrastructure into three distinct layers:

```
┌─────────────────────────────────────────────────────────────┐
│  LAYER 3: Applications                                       │
│  User services deployed through the PaaS platform           │
│  (Managed via Dokploy/Coolify UI, not directly by Terraform)│
├─────────────────────────────────────────────────────────────┤
│  LAYER 2: Platform                                           │
│  Container runtime, reverse proxy, PaaS, platform identity  │
│  (Docker, Traefik, Dokploy, TinyAuth)                       │
├─────────────────────────────────────────────────────────────┤
│  LAYER 1: Foundation                                         │
│  Operating system, security, networking, core identity      │
│  (SSH, firewall, LLDAP, Step-CA)                            │
└─────────────────────────────────────────────────────────────┘
```

### Why This Matters

- **Modularity** – Change Layer 3 applications without affecting Layer 1 or 2
- **Security** – Foundation security is built-in, not an afterthought
- **Maintainability** – Clear boundaries make updates predictable
- **Reusability** – Layer 1 and 2 remain stable across different application sets

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24.0+ | Container runtime |
| OpenTofu | 1.6+ | Infrastructure provisioning |
| CUE (optional) | 0.9+ | For development and customization |
| Terramate (optional) | 0.6+ | For advanced orchestration |

### Quick Start

```bash
# Clone the repository
git clone https://github.com/kombihq/stackkits
cd stackkits

# Initialize a StackKit
stackkit init base-homelab

# Review and customize the specification
# Edit stack-spec.yaml with your settings

# Validate your configuration
stackkit validate

# Deploy
stackkit apply
```

### Development Environment

For testing without affecting production infrastructure:

```bash
# Start the development VM
docker compose up -d vm

# Deploy inside the VM
docker compose run --rm cli ./stackkit init base-homelab
docker compose run --rm cli ./stackkit apply
```

---

## Configuration Concepts

### The Specification File

Your intent is defined in `stack-spec.yaml`:

```yaml
name: my-homelab
stackkit: base-homelab
variant: default
mode: simple

network:
  mode: local
  subnet: 172.20.0.0/16

compute:
  tier: standard

ssh:
  user: admin
  port: 22
```

### Variants

Each StackKit offers variants for different use cases:

| Variant | Description |
|---------|-------------|
| default | Standard configuration for most users |
| minimal | Reduced resource footprint |
| secure | Enhanced security with authentication proxy |

### Deployment Modes

| Mode | Description |
|------|-------------|
| simple | Standard OpenTofu workflow (init → plan → apply) |
| advanced | Terramate orchestration with drift detection |

---

## Day-2 Operations

StackKits includes support for ongoing infrastructure management.

### Drift Detection

Check if running infrastructure matches your configuration:

```bash
stackkit drift
```

This reports any differences between your defined state and the actual infrastructure.

### Updates

Apply configuration changes safely:

```bash
# Review changes
stackkit plan

# Apply changes
stackkit apply
```

---

## Common Questions

**Do I need programming experience?**

No. Basic familiarity with configuration files (YAML) is sufficient. The validation system guides you through any errors.

**What happens if validation fails?**

Deployment is blocked. You receive specific error messages with expected values and suggested fixes. No infrastructure is modified until validation passes.

**Can I migrate existing setups?**

Yes, though a fresh start is often simpler. Documentation includes migration guidance for common configurations.

**Is this production-ready?**

base-homelab is designed for homelab use. It follows security best practices but is not hardened for enterprise production environments.

---

## Resources

| Resource | Location |
|----------|----------|
| Documentation | docs.stackkits.dev |
| Source Code | github.com/kombihq/stackkits |
| Community | Discord (see repository for invite) |

---

**StackKits: Infrastructure blueprints that work the first time.**
