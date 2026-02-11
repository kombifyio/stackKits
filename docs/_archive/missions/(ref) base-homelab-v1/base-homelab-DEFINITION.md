# Base Homelab StackKit - Definition Document

> **Last Updated:** 2026-01-29  
> **Status:** 🔒 GOLDEN TEMPLATE - Source of Truth  
> **Version:** 2.0.0  
> **Purpose:** Canonical definition for all base-homelab development

---

## ⚠️ Document Authority

This document is the **single source of truth** for the base-homelab StackKit. All code changes, schema modifications, and feature additions MUST align with the definitions in this document.

**Update Protocol:**
1. Proposed changes must be discussed in `base-homelab-PLAN.md`
2. Approved changes are reflected here first
3. Code implementation follows this document

---

## 1. StackKit Identity

### 1.1 Core Metadata

| Field | Value |
|-------|-------|
| **Name** | `base-homelab` |
| **Display Name** | Base Homelab |
| **Version** | 2.0.0 |
| **Status** | Beta (targeting v1.0 release) |
| **License** | MIT |
| **Category** | Homelab / Self-Hosted |
| **Complexity** | Beginner |

### 1.2 One-Line Description

> Single-server homelab with Docker, PaaS platform, and monitoring - ready in 5 minutes.

### 1.3 Extended Description

The Base Homelab StackKit provides a complete, pre-validated infrastructure blueprint for deploying a modern homelab on a single server. It includes a reverse proxy with automatic HTTPS, a self-hosted PaaS for deploying applications, and built-in monitoring. Users can choose from four variants optimized for different use cases.

---

## 2. Target Audience

### 2.1 Primary Users

| Persona | Description | Key Needs |
|---------|-------------|-----------|
| **Homelab Beginner** | First self-hosted setup | Simplicity, good defaults, clear docs |
| **Developer** | Personal dev/staging environment | Fast deployment, app hosting |
| **Self-Hoster** | Runs personal services | Reliability, monitoring |

### 2.2 Prerequisites

| Requirement | Specification |
|-------------|---------------|
| **Server** | Physical or VPS with root access |
| **OS** | Ubuntu 22.04+, Ubuntu 24.04 (recommended), Debian 12 |
| **Network** | Static IP (local) or public IP (VPS) |
| **Knowledge** | Basic terminal/SSH usage |

### 2.3 Out of Scope

| What | Why |
|------|-----|
| Windows Server | Docker support limited |
| Multi-node HA | Use `ha-homelab` instead |
| Kubernetes | Use `modern-homelab` or wait for v2.0 |
| Cloud provisioning | v1.1+ feature |

---

## 3. Hardware Requirements

### 3.1 Compute Tiers

| Tier | CPU | RAM | Disk | Use Case |
|------|-----|-----|------|----------|
| **low** | 2 cores | 4 GB | 50 GB | Minimal services, testing |
| **standard** | 4 cores | 8 GB | 100 GB | Typical homelab (recommended) |
| **high** | 8+ cores | 16+ GB | 200+ GB | Many services, AI workloads |

### 3.2 Auto-Detection Logic

```
if cpu >= 8 AND memory >= 16:
    tier = "high"
elif cpu < 4 OR memory < 8:
    tier = "low"
else:
    tier = "standard"
```

### 3.3 Tier-Based Defaults

| Setting | Low | Standard | High |
|---------|-----|----------|------|
| Max containers | 10 | 20 | 50 |
| Default memory limit | 512m | 1g | 4g |
| Default CPU limit | 0.5 | 1.0 | 4.0 |
| Log max size | 20m | 50m | 100m |
| Backup frequency | Weekly | Daily | Every 6h |

---

## 4. Network Configuration

### 4.1 Network Defaults

| Setting | Value | Notes |
|---------|-------|-------|
| Docker network | `kombi_net` | Shared network for all services |
| Subnet | `172.20.0.0/16` | RFC1918 private range |
| Gateway | `172.20.0.1` | Auto-assigned |
| DNS | `1.1.1.1`, `8.8.8.8` | Configurable |

### 4.2 Access Modes

| Mode | Description | SSL | Domain Required |
|------|-------------|-----|-----------------|
| **ports** | Direct port access (`:3000`, `:8080`) | No | No |
| **proxy** | Subdomain routing via Traefik | Optional | Yes |

### 4.3 Domain Strategy

| User Has | Recommended Mode | SSL Config |
|----------|------------------|------------|
| No domain | `ports` | None |
| Local domain (`.local`) | `proxy` | Self-signed |
| Public domain | `proxy` | Let's Encrypt |

---

## 5. Variant Definitions

### 5.1 Variant Overview

| ID | Name | PaaS | Monitoring | Best For |
|----|------|------|------------|----------|
| `default` | Standard | Dokploy | Uptime Kuma | No domain, beginners |
| `coolify` | Cloud-Native | Coolify | Uptime Kuma | Own domain, Git deploys |
| `beszel` | Metrics-Focused | Dokploy | Beszel | Server metrics |
| `minimal` | Classic Docker | None (Dockge) | Netdata | Manual Docker management |

### 5.2 Variant: `default` (Recommended)

**Description:** Full-featured PaaS with uptime monitoring. No domain required.

**Services:**
| Service | Role | Port | Required |
|---------|------|------|----------|
| Traefik | Reverse Proxy | 80, 443, 8080 | ✅ Yes |
| Dokploy | PaaS Platform | 3000 | ✅ Yes |
| Uptime Kuma | Uptime Monitoring | 3001 | ✅ Yes |
| Dozzle | Log Viewer | 8888 | ✅ Yes |
| Whoami | Test Service | 9080 | ⚪ Optional |

**Selection Rule:** Default when no domain OR domain is `.local`

### 5.3 Variant: `coolify`

**Description:** Git-integrated PaaS with advanced deployment features. Requires own domain.

**Services:**
| Service | Role | Port | Required |
|---------|------|------|----------|
| Traefik | Reverse Proxy | 80, 443, 8080 | ✅ Yes |
| Coolify | PaaS Platform | 8000 | ✅ Yes |
| Uptime Kuma | Uptime Monitoring | 3001 | ✅ Yes |
| Dozzle | Log Viewer | 8888 | ✅ Yes |

**Selection Rule:** Recommended when user has public domain

### 5.4 Variant: `beszel`

**Description:** Like default but with detailed server metrics instead of uptime monitoring.

**Services:**
| Service | Role | Port | Required |
|---------|------|------|----------|
| Traefik | Reverse Proxy | 80, 443, 8080 | ✅ Yes |
| Dokploy | PaaS Platform | 3000 | ✅ Yes |
| Beszel | Server Metrics | 8090 | ✅ Yes |
| Dozzle | Log Viewer | 8888 | ✅ Yes |

**Selection Rule:** User explicitly wants server metrics focus

### 5.5 Variant: `minimal`

**Description:** Traditional Docker management without PaaS. For power users.

**Services:**
| Service | Role | Port | Required |
|---------|------|------|----------|
| Traefik | Reverse Proxy | 80, 443, 8080 | ✅ Yes |
| Dockge | Compose Manager | 5001 | ✅ Yes |
| Portainer | Container Manager | 9000 | ✅ Yes |
| Netdata | System Metrics | 19999 | ✅ Yes |
| Dozzle | Log Viewer | 8888 | ✅ Yes |

**Selection Rule:** User explicitly chooses minimal / prefers manual control

---

## 6. Service Definitions

### 6.1 Core Services (All Variants)

#### 6.1.1 Traefik (Reverse Proxy)

| Property | Value |
|----------|-------|
| Image | `traefik:v3.1` |
| Category | `core` |
| Type | `reverse-proxy` |
| Required | ✅ Always |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 80 | 80 | TCP | HTTP |
| 443 | 443 | TCP | HTTPS |
| 8080 | 8080 | TCP | Dashboard |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |
| `traefik-certs` | `/certs` | volume | Yes |
| `traefik-config` | `/etc/traefik` | volume | Yes |

**Health Check:**
- Path: `/ping`
- Port: 8080
- Interval: 10s
- Timeout: 5s

#### 6.1.2 Dozzle (Log Viewer)

| Property | Value |
|----------|-------|
| Image | `amir20/dozzle:latest` |
| Category | `observability` |
| Type | `logs` |
| Required | ✅ All variants |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 8888 | 8080 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |

### 6.2 Platform Services

#### 6.2.1 Dokploy (Default PaaS)

| Property | Value |
|----------|-------|
| Image | `dokploy/dokploy:latest` |
| Category | `platform` |
| Type | `paas` |
| Variants | `default`, `beszel` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 3000 | 3000 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |
| `dokploy-data` | `/app/data` | volume | Yes |

**Resources:**
| Setting | Value |
|---------|-------|
| Memory | 512m (min), 1g (max) |
| CPU | 1.0 |

#### 6.2.2 Coolify (Alternative PaaS)

| Property | Value |
|----------|-------|
| Image | `ghcr.io/coollabsio/coolify:latest` |
| Category | `platform` |
| Type | `paas` |
| Variants | `coolify` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 8000 | 8000 | TCP | Web UI |
| 6001 | 6001 | TCP | Websockets |
| 6002 | 6002 | TCP | Terminal |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |
| `/data/coolify` | `/data/coolify` | bind | Yes |

**Resources:**
| Setting | Value |
|---------|-------|
| Memory | 1g (min), 2g (max) |
| CPU | 2.0 |

### 6.3 Monitoring Services

#### 6.3.1 Uptime Kuma (Uptime Monitoring)

| Property | Value |
|----------|-------|
| Image | `louislam/uptime-kuma:1` |
| Category | `monitoring` |
| Type | `uptime` |
| Variants | `default`, `coolify` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 3001 | 3001 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `uptime-kuma-data` | `/app/data` | volume | Yes |

#### 6.3.2 Beszel (Server Metrics)

| Property | Value |
|----------|-------|
| Image | `henrygd/beszel:latest` |
| Category | `monitoring` |
| Type | `metrics` |
| Variants | `beszel` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 8090 | 8090 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `beszel-data` | `/beszel_data` | volume | Yes |

### 6.4 Management Services (Minimal Variant)

#### 6.4.1 Dockge (Compose Manager)

| Property | Value |
|----------|-------|
| Image | `louislam/dockge:1` |
| Category | `management` |
| Type | `compose-manager` |
| Variants | `minimal` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 5001 | 5001 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |
| `/opt/stacks` | `/opt/stacks` | bind | Yes |
| `dockge-data` | `/app/data` | volume | Yes |

#### 6.4.2 Portainer (Container Manager)

| Property | Value |
|----------|-------|
| Image | `portainer/portainer-ce:2.19.4` |
| Category | `management` |
| Type | `container-manager` |
| Variants | `minimal` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 9000 | 9000 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/var/run/docker.sock` | `/var/run/docker.sock` | bind | No |
| `portainer-data` | `/data` | volume | Yes |

#### 6.4.3 Netdata (System Metrics)

| Property | Value |
|----------|-------|
| Image | `netdata/netdata:stable` |
| Category | `monitoring` |
| Type | `metrics` |
| Variants | `minimal` |

**Ports:**
| Host | Container | Protocol | Description |
|------|-----------|----------|-------------|
| 19999 | 19999 | TCP | Web UI |

**Volumes:**
| Source | Target | Type | Backup |
|--------|--------|------|--------|
| `/proc` | `/host/proc` | bind | No |
| `/sys` | `/host/sys` | bind | No |
| `netdata-config` | `/etc/netdata` | volume | Yes |

---

## 7. Deployment Modes

### 7.1 Simple Mode

| Property | Value |
|----------|-------|
| Engine | OpenTofu |
| State | Local (`.terraform/`) |
| Day-2 Ops | Manual |
| Best For | Quick deployments, testing |

**Workflow:**
```
stackkit init → stackkit prepare → stackkit plan → stackkit apply
```

### 7.2 Advanced Mode

| Property | Value |
|----------|-------|
| Engine | OpenTofu + Terramate |
| State | Local or Remote |
| Day-2 Ops | Drift detection, orchestration |
| Best For | Production, compliance |

**Workflow:**
```
stackkit init → stackkit prepare → stackkit plan --advanced → stackkit apply --advanced
```

**Features:**
- Drift detection on schedule
- Change set management
- Multi-stack ordering
- Gradual rollouts

---

## 8. File Structure

### 8.1 StackKit Directory

```
base-homelab/
├── stackkit.yaml           # StackKit metadata
├── stackfile.cue           # Main CUE schema
├── services.cue            # Service definitions
├── defaults.cue            # Smart defaults
├── default-spec.yaml       # Example user spec
├── README.md               # User documentation
├── templates/
│   ├── simple/
│   │   └── main.tf         # OpenTofu template
│   └── advanced/
│       └── (terramate)     # Terramate stacks
├── variants/               # Variant overrides
└── tests/
    ├── schema_test.cue     # CUE tests
    └── run_tests.sh        # Test runner
```

### 8.2 Generated Output

```
deploy/                     # Generated by stackkit generate
├── main.tf                 # OpenTofu configuration
├── terraform.tfvars        # Variables from spec
├── .terraform/             # OpenTofu state
└── terraform.tfstate       # Infrastructure state
```

---

## 9. Configuration Schema

### 9.1 User-Provided Configuration (`stack-spec.yaml`)

```yaml
name: my-homelab                    # Deployment name
stackKit: base-homelab              # StackKit to use
variant: default                    # Service variant
mode: simple                        # Deployment mode

network:
  mode: local                       # Network mode (local/cloud)
  subnet: 172.20.0.0/16            # Docker network CIDR
  domain: ""                        # Optional domain

compute:
  tier: auto                        # Compute tier (auto/low/standard/high)

ssh:
  user: root                        # SSH user
  port: 22                          # SSH port
  keyPath: ~/.ssh/id_ed25519       # Path to SSH key
```

### 9.2 CUE Schema Constraints

| Field | Type | Constraints | Default |
|-------|------|-------------|---------|
| `name` | string | `/^[a-z][a-z0-9-]*$/` | (required) |
| `variant` | enum | `default\|coolify\|beszel\|minimal` | `default` |
| `mode` | enum | `simple\|advanced` | `simple` |
| `network.subnet` | CIDR | RFC1918 private | `172.20.0.0/16` |
| `compute.tier` | enum | `auto\|low\|standard\|high` | `auto` |

---

## 10. Security Defaults

### 10.1 SSH Hardening

| Setting | Value |
|---------|-------|
| PasswordAuthentication | No |
| PermitRootLogin | prohibit-password |
| MaxAuthTries | 3 |

### 10.2 Firewall (UFW)

| Rule | Action |
|------|--------|
| SSH (22) | Allow |
| HTTP (80) | Allow |
| HTTPS (443) | Allow |
| Default Incoming | Deny |
| Default Outgoing | Allow |

### 10.3 Container Security

| Setting | Value |
|---------|-------|
| Privileged | false (default) |
| Read-only root | Recommended |
| User namespace | Default (root) |
| Capabilities | Minimal required |

---

## 11. Output URLs

### 11.1 Ports Mode

| Service | URL Pattern |
|---------|-------------|
| Traefik Dashboard | `http://{host}:8080` |
| Dokploy | `http://{host}:3000` |
| Uptime Kuma | `http://{host}:3001` |
| Dozzle | `http://{host}:8888` |

### 11.2 Proxy Mode

| Service | URL Pattern |
|---------|-------------|
| Traefik Dashboard | `https://traefik.{domain}` |
| Dokploy | `https://deploy.{domain}` |
| Uptime Kuma | `https://status.{domain}` |
| Dozzle | `https://logs.{domain}` |

---

## 12. Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | 2026-01 | Major refactor, PaaS strategy, variant system |
| 1.0.0 | 2025-12 | Initial release |

---

## Appendix A: Service Image Versions

| Service | Image | Tag | Update Policy |
|---------|-------|-----|---------------|
| Traefik | `traefik` | `v3.1` | Pin major.minor |
| Dokploy | `dokploy/dokploy` | `latest` | Follow latest |
| Coolify | `ghcr.io/coollabsio/coolify` | `latest` | Follow latest |
| Uptime Kuma | `louislam/uptime-kuma` | `1` | Pin major |
| Beszel | `henrygd/beszel` | `latest` | Follow latest |
| Dozzle | `amir20/dozzle` | `latest` | Follow latest |
| Dockge | `louislam/dockge` | `1` | Pin major |
| Portainer | `portainer/portainer-ce` | `2.19.4` | Pin patch |
| Netdata | `netdata/netdata` | `stable` | Stable channel |

---

## Appendix B: Environment Variables

### B.1 Traefik

| Variable | Description | Default |
|----------|-------------|---------|
| `TRAEFIK_API_DASHBOARD` | Enable dashboard | `true` |
| `TRAEFIK_API_INSECURE` | Dashboard without auth | `true` (dev) |
| `TRAEFIK_PROVIDERS_DOCKER` | Docker provider | `true` |

### B.2 Dokploy

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment | `production` |
| `NEXTAUTH_SECRET` | Auth secret | (generate) |

### B.3 Coolify

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ID` | Application ID | (generate) |
| `APP_KEY` | Application key | (generate) |
| `APP_URL` | Public URL | `https://coolify.{domain}` |

---

## Appendix C: Volume Backup Strategy

| Volume | Backup | Retention | Notes |
|--------|--------|-----------|-------|
| `traefik-certs` | Yes | 30 days | SSL certificates |
| `traefik-config` | Yes | 30 days | Traefik config |
| `dokploy-data` | Yes | 30 days | App deployments |
| `uptime-kuma-data` | Yes | 30 days | Monitoring data |
| `portainer-data` | Yes | 7 days | Container config |
| Docker socket | No | N/A | System resource |
