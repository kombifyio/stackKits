# StackKits

Pre-configured infrastructure stacks for homelabs. One command to deploy a full homelab with reverse proxy, PaaS, monitoring, and authentication — all wired together and ready to use.

## Quick Start

Run this on any machine with Docker installed:

```bash
curl -sSL https://raw.githubusercontent.com/kombifyio/stackKits/main/install.sh | sh
```

This downloads the Base Kit and starts all services. After ~30 seconds:

```
Dashboard:   http://dash.stack.local:7880
TinyAuth:    http://auth.stack.local:7880
PocketID:    http://id.stack.local:7880
Dokploy:     http://dokploy.stack.local:7880
Uptime Kuma: http://kuma.stack.local:7880
Traefik:     http://proxy.stack.local:7880
```

**Credentials:** `admin` / `admin123`

> **LAN access:** The installer detects your server IP and prints sslip.io URLs (e.g. `http://dash.192.168.1.50.sslip.io:7880`) so you can access services from any device on your network.

## Base Kit

The **Base Kit** is a single-node homelab stack with everything you need to get started:

| Service | Purpose |
|---------|---------|
| **Traefik** | Reverse proxy with domain-based routing |
| **TinyAuth** | Forward auth (protects all services) |
| **PocketID** | OpenID Connect identity provider |
| **Dokploy** | PaaS platform for app deployment |
| **Uptime Kuma** | Monitoring & status pages |
| **Whoami** | Proxy verification test service |
| **Dashboard** | Service overview with direct links |

## Requirements

- Docker 24.0+ with the Compose plugin
- 2+ CPU cores, 4+ GB RAM

## Managing Services

```bash
cd kombify-base-kit

# Stop all services
docker compose down

# Restart
docker compose up -d

# View logs
docker compose logs -f

# Update (re-run the installer)
curl -sSL https://raw.githubusercontent.com/kombifyio/stackKits/main/install.sh | sh
```

## DNS Setup

Services use `.stack.local` domains. Add these to your `/etc/hosts` (or use dnsmasq):

```
127.0.0.1  dash.stack.local auth.stack.local id.stack.local
127.0.0.1  dokploy.stack.local kuma.stack.local proxy.stack.local
```

Or use the **sslip.io URLs** printed by the installer for zero-config LAN access.

## License

Apache 2.0 — see [LICENSE](LICENSE).
