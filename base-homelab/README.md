# Base Homelab StackKit

> **Single-server homelab with Docker and essential services - Ready in 5 minutes!**

## 🎯 Overview

The **Base Homelab** StackKit provides everything you need to run a modern homelab on a single server. Choose from four **preconfigured variants** that work out-of-the-box:

| Variant | Best For | PaaS | Services |
|---------|----------|------|----------|
| **default** | No domain, local network | Dokploy | Dokploy + Uptime Kuma |
| **coolify** | Own domain, Git deploys | Coolify | Coolify + Uptime Kuma |
| **beszel** | Server metrics focus | Dokploy | Dokploy + Beszel |
| **minimal** | Classic Docker | None | Dockge + Portainer + Netdata |

### PaaS Selection Guide

| Your Situation | Recommended Variant |
|----------------|---------------------|
| No domain, just local access | `default` (Dokploy) |
| Have own domain, want Git deploys | `coolify` (Coolify) |
| Want detailed server metrics | `beszel` |
| Prefer manual Docker management | `minimal` |

## 🚀 Quick Start (5 Minutes)

### Step 1: Copy and Edit Configuration

```bash
cd base-homelab/templates/simple
cp terraform.tfvars.example terraform.tfvars

# Optionally tweak variant/compute/access settings
nano terraform.tfvars
```

### Step 2: Deploy

```bash
tofu init
tofu plan
tofu apply
```

### Step 3: Access Your Services! 🎉

By default, this StackKit works **without any domain/DNS**.

Default naming fallback is mDNS: `HOSTNAME.local` (example: `homelab.local`). If your LAN clients don’t resolve `.local`, set `advertise_host` to your server IP/hostname.

**Default Variant (ports mode):**
| Service | URL | Description |
|---------|-----|-------------|
| Traefik Dashboard | `http://HOSTNAME.local:8080` | Reverse proxy dashboard |
| Dokploy | `http://HOSTNAME.local:3000` | Deploy apps like Vercel |
| Uptime Kuma | `http://HOSTNAME.local:3001` | Monitor your services |
| Dozzle | `http://HOSTNAME.local:8888` | View container logs |
| Whoami | `http://HOSTNAME.local:9080` | Test service |

If you prefer clean hostnames + optional HTTPS, set `access_mode = "proxy"` and configure `domain` (and optionally `acme_email`).

**Proxy Mode (example):**
| Service | URL |
|---------|-----|
| Traefik | `https://traefik.yourdomain.com` |
| Dokploy | `https://deploy.yourdomain.com` |
| Uptime Kuma | `https://status.yourdomain.com` |
| Dozzle | `https://logs.yourdomain.com` |
| Whoami | `https://whoami.yourdomain.com` |

## 📦 Variant Comparison

### 🟢 Default (Recommended for Quick Start)

Perfect for deploying web applications with built-in PaaS functionality.

```
┌──────────────────────────────────────────────────────────────┐
│  Dokploy (deploy.{domain})                                   │
│  • Deploy from GitHub, Docker Hub, or Git                    │
│  • Automatic SSL certificates                                │
│  • Environment variables management                          │
│  • Database deployments (PostgreSQL, MySQL, Redis, MongoDB)  │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│  Uptime Kuma (status.{domain})                               │
│  • Monitor HTTP, TCP, DNS, and more                          │
│  • Beautiful status pages                                     │
│  • Notifications (Telegram, Discord, Email)                  │
└──────────────────────────────────────────────────────────────┘
```

### 🔵 Beszel (Advanced Monitoring)

Same as default but with powerful server-side monitoring.

```
┌──────────────────────────────────────────────────────────────┐
│  Beszel (monitor.{domain})                                   │
│  • Real-time server metrics (CPU, RAM, Disk, Network)        │
│  • Historical data with graphs                               │
│  • Alerting based on thresholds                              │
│  • Multi-server support with agents                          │
└──────────────────────────────────────────────────────────────┘
```

### 🟡 Minimal (Classic Docker)

Traditional Docker management without the PaaS overhead.

```
┌──────────────────────────────────────────────────────────────┐
│  Dockge (dockge.{domain})                                    │
│  • Visual docker-compose editor                              │
│  • One-click start/stop/restart                              │
│  • Manage compose files in /opt/stacks                       │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│  Portainer (portainer.{domain})                              │
│  • Full container management                                  │
│  • Image management and updates                              │
│  • Network and volume management                             │
└──────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────┐
│  Netdata (monitor.{domain})                                  │
│  • Real-time system metrics                                  │
│  • Per-container resource usage                              │
│  • 1000+ built-in metrics                                    │
└──────────────────────────────────────────────────────────────┘
```

## 📋 Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 50 GB | 100+ GB |
| **OS** | Ubuntu 22.04+ | Ubuntu 24.04 LTS |
| **Domain** | Not required | Optional (proxy mode) |

## 🔧 Deployment Modes

### Simple Mode (OpenTofu Only)
Best for getting started quickly.

```bash
cd templates/simple
tofu init && tofu plan && tofu apply
```

### Advanced Mode (Terramate + OpenTofu)
Best for ongoing operations with drift detection.

```bash
cd templates/advanced
terramate run tofu init
terramate run tofu plan
terramate run tofu apply

# Detect drift from desired state
terramate run tofu plan -detailed-exitcode
```

## 🔒 All Services Include

- ✅ **Ports-first access** (zero config)
- ✅ **Optional HTTPS** via Let's Encrypt (proxy mode)
- ✅ **Optional Traefik routing** with clean hostnames (proxy mode)
- ✅ **Health Checks** for container monitoring
- ✅ **Restart Policies** for reliability
- ✅ **Memory Limits** based on compute tier
- ✅ **Dozzle Logs** for all containers

## 📁 File Structure

```
base-homelab/
├── stackkit.yaml       # Metadata & manifest
├── stackfile.cue       # Main CUE schema
├── services.cue        # Service definitions
├── defaults.cue        # Smart defaults & compute tiers
├── default-spec.yaml   # CLI user template
├── variants/
│   ├── os/             # Ubuntu 22/24, Debian 12
│   └── compute/        # High/Standard/Low tiers
├── templates/
│   ├── simple/
│   │   ├── main.tf                    # Complete OpenTofu config (790 lines)
│   │   └── terraform.tfvars.example   # Documented example config
│   └── advanced/
│       ├── terramate.tm.hcl           # Terramate root config
│       └── stacks/                    # Individual service stacks
└── tests/
    ├── schema_test.cue               # CUE validation tests
    └── run_tests.sh                  # Test runner
```

## 🎯 Next Steps After Deployment

1. **Access services** via `http://localhost:<port>` (default)
2. **Deploy your first app** in Dokploy or add a compose stack in Dockge
3. **Set up monitoring alerts** in Uptime Kuma / Beszel / Netdata
4. **Check logs** in Dozzle if anything seems wrong

## 🆘 Troubleshooting

### SSL certificates not working?
- This only applies in `access_mode = "proxy"` with Let's Encrypt enabled
- Ensure your domain points to your server's IP and ports 80/443 are reachable
- Wait up to 5 minutes for certificates to issue

### Services not accessible?
```bash
# Check container status
docker ps

# Check Traefik logs
docker logs traefik

# Verify network
docker network ls
```
- Non-root container execution

## 📖 Documentation

- [Service Configuration](docs/services.md)
- [Networking](docs/networking.md)
- [Customization](docs/customization.md)
