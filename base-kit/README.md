# Base Kit

> **Single-server homelab with Docker — production-ready, secure, identity-aware.**

## Overview

The **Base Kit** deploys a complete, self-hosted infrastructure stack on a single server. It implements the [3-layer architecture](../docs/ARCHITECTURE_V4.md):

| Layer | Services | Managed By |
|-------|----------|-----------|
| **L1 Foundation** | TinyAuth (identity proxy) | OpenTofu |
| **L2 Platform** | Traefik, Dokploy, PostgreSQL | OpenTofu |
| **L3 Applications** | Uptime Kuma, your apps | Dokploy |

All services are accessed via domain routing (`service.stack.local`) through Traefik. TinyAuth provides zero-trust ForwardAuth for all protected services. No external ports except Traefik's 80/443/8080.

## Requirements

| | Minimum | Recommended |
|--|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 2 GB | 4+ GB |
| Disk | 10 GB | 20+ GB |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| Domain | Not required | Optional (use `stack.local`) |

## Quick Start

### 1. Initialize

```bash
stackkit init base-kit
# Edit my-homelab-spec.yaml: set IP, SSH user, SSH key path
```

### 2. Validate

```bash
stackkit validate my-homelab-spec.yaml
```

### 3. Deploy

```bash
stackkit apply my-homelab-spec.yaml
```

### 4. Access your services

Add to `/etc/hosts` on your client (or configure a wildcard in your DNS/dnsmasq):

```
192.168.1.100  auth.stack.local
192.168.1.100  traefik.stack.local
192.168.1.100  dokploy.stack.local
192.168.1.100  kuma.stack.local
```

Or use a wildcard entry: `*.stack.local → 192.168.1.100`

| Service | URL | Purpose |
|---------|-----|---------|
| TinyAuth | `http://auth.stack.local` | Login (admin / admin123) |
| Traefik | `http://traefik.stack.local` | Reverse proxy dashboard |
| Dokploy | `http://dokploy.stack.local` | Deploy and manage apps |
| Uptime Kuma | `http://kuma.stack.local` | Service monitoring |
| Traefik direct | `http://server-ip:8080` | Dashboard (no DNS needed) |

## First Login

1. Open `http://auth.stack.local` — TinyAuth login
   - Username: `admin`, Password: `admin123`
   - **Change the password immediately**
2. Open `http://dokploy.stack.local` — redirects through TinyAuth
3. In Dokploy, deploy Layer 3 apps (Uptime Kuma, your own services)

## Architecture

```
Internet / LAN client
        │
        ▼
  Traefik :80/:443        (L2 Platform — reverse proxy)
        │
        ├─► TinyAuth      (L1 Foundation — ForwardAuth identity)
        │
        ├─► Dokploy       (L2 Platform — PaaS, protected by TinyAuth)
        │    │
        │    └─► dokploy-postgres (L2 — internal DB network, no host ports)
        │
        └─► Uptime Kuma   (L3 Application — managed by Dokploy)
```

**Security by default:**
- PostgreSQL on isolated internal Docker network (no host ports)
- All services: `security_opts: [no-new-privileges:true]`, dropped capabilities
- All containers: health checks and restart policies
- Secrets generated at deploy time via OpenTofu `random_password`

## Configuration Variables

Edit `terraform.tfvars` in `templates/simple/` to override defaults:

| Variable | Default | Description |
|----------|---------|-------------|
| `domain` | `stack.local` | Base domain for all services |
| `network_name` | `base_net` | Docker network name |
| `network_subnet` | `172.20.0.0/16` | Docker network subnet |
| `enable_tinyauth` | `true` | Enable TinyAuth identity proxy |
| `enable_dokploy` | `true` | Enable Dokploy PaaS |
| `enable_dokploy_apps` | `true` | Create Dokploy compose configs |
| `tinyauth_users` | `admin:$2a$10$...` | Bcrypt-hashed user list |
| `tinyauth_app_url` | `http://auth.stack.local` | TinyAuth URL |

## DNS Options

**Option A — /etc/hosts (simplest):**
```
# Add on each client machine
192.168.1.100  auth.stack.local traefik.stack.local dokploy.stack.local kuma.stack.local
```

**Option B — dnsmasq wildcard (recommended):**
```
# /etc/dnsmasq.conf
address=/.stack.local/192.168.1.100
```

**Option C — Real domain:**
```hcl
# terraform.tfvars
domain = "yourdomain.com"
# Add DNS A records: *.yourdomain.com → server-ip
```

## Add-Ons

The Base Kit is the foundation. Extend it with add-ons from `addons/`:

| Add-On | Adds |
|--------|------|
| `monitoring` | VictoriaMetrics + Grafana + Loki |
| `backup` | Restic with scheduled backups |
| `vpn-overlay` | Headscale/Tailscale mesh |
| `tunnel` | Cloudflare Tunnel / Pangolin |
| `media` | Jellyfin + Sonarr + Radarr |
| `smart-home` | Home Assistant + MQTT |
| `ai-workloads` | Ollama + Open WebUI |

Add-ons replace the old variant system (Beszel, Dockge, Portainer, Netdata). Enable them in your spec under `addons:`.

## File Structure

```
base-kit/
├── stackkit.yaml         # StackKit metadata
├── stackfile.cue         # CUE schema definition
├── services.cue          # Service definitions
├── defaults.cue          # Smart defaults
├── default-spec.yaml     # User-facing spec template
├── templates/
│   ├── simple/
│   │   └── main.tf       # OpenTofu configuration (v4)
│   └── advanced/         # Terramate multi-stack (advanced)
└── tests/
    ├── schema_test.cue   # CUE schema tests
    ├── e2e_test.sh       # End-to-end SSH test
    └── run_tests.sh      # CUE test runner
```

## Troubleshooting

**Services not reachable:**
```bash
# Check container status on server
ssh user@server docker ps

# Check Traefik logs
ssh user@server docker logs traefik

# Test Traefik is running (no DNS needed)
curl http://server-ip:8080/ping
```

**TinyAuth redirect loop:**
- Ensure `APP_URL` in TinyAuth matches the URL you're accessing
- Verify `auth.stack.local` resolves to your server

**Dokploy cannot reach PostgreSQL:**
```bash
# Check internal DB network
ssh user@server docker network inspect base_net_db
ssh user@server docker exec dokploy-postgres pg_isready -U dokploy
```

**CUE validation fails:**
```bash
cue vet ./base-kit/...
```
