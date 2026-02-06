# Dev Homelab - VM-Based Deployment

A production-ready homelab StackKit with Dokploy PAAS, Traefik reverse proxy, and Zero-Trust security architecture.

**IMPORTANT:** All services run INSIDE the Ubuntu VM, not directly on the Windows host.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WINDOWS HOST                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Ubuntu VM (Docker-in-Docker)                     │    │
│  │  ┌───────────────────────────────────────────────────────────────┐  │    │
│  │  │ LAYER 3: APPLICATIONS (Managed by Dokploy)                   │  │    │
│  │  │ ┌──────────────┐  ┌──────────────┐                            │  │    │
│  │  │ │    Kuma      │  │    Whoami    │ ← Deployed via Dokploy UI  │  │    │
│  │  │ │ (Monitoring) │  │  (Test API)  │                            │  │    │
│  │  │ └──────┬───────┘  └──────┬───────┘                            │  │    │
│  │  │        │                 │                                     │  │    │
│  │  │        └────────┬────────┘                                     │  │    │
│  │  │                 ▼                                              │  │    │
│  │  │  ┌──────────────────────────────────────┐                     │  │    │
│  │  │  │           Dokploy PAAS               │                     │  │    │
│  │  │  └──────────────────────────────────────┘                     │  │    │
│  │  │                    │                                           │  │    │
│  │  │  LAYER 2: PLATFORM  ▼                                           │  │    │
│  │  │  ┌──────────────────────────────────────┐                     │  │    │
│  │  │  │        Traefik Reverse Proxy         │                     │  │    │
│  │  │  └──────────────────────────────────────┘                     │  │    │
│  │  │                    │                                           │  │    │
│  │  │  LAYER 1: FOUNDATION ▼                                          │  │    │
│  │  │  ┌──────────────────────────────────────┐                     │  │    │
│  │  │  │        TinyAuth (OIDC/SSO)           │                     │  │    │
│  │  │  └──────────────────────────────────────┘                     │  │    │
│  │  └───────────────────────────────────────────────────────────────┘  │    │
│  │                                                                     │    │
│  │  Docker Daemon: tcp://vm:2375 (accessible from host CLI container) │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  Port Forwarding:                                                            │
│    Host:80  → VM:80    (HTTP)                                                │
│    Host:443 → VM:443   (HTTPS)                                               │
│    Host:8080 → VM:8080 (Traefik Dashboard)                                   │
│    Host:2222 → VM:22   (SSH)                                                 │
│    Host:2375 → VM:2375 (Docker Daemon)                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- OpenTofu/Terraform (inside CLI container)
- StackKit CLI (built from source)

### Deployment Steps

**STEP 1: Build StackKit CLI**

```bash
cd /workspace
go build -o stackkit.exe ./cmd/stackkit
```

**STEP 2: Start ONLY the VM**

```bash
# Start only the Ubuntu VM - NO services yet
docker compose up -d vm

# Verify VM is running
docker ps
# Should show ONLY: stackkits-vm
```

**STEP 3: Verify VM Docker Daemon**

```bash
# Check Docker daemon is accessible on port 2375
docker compose exec vm docker ps
# Should show empty (no containers yet in VM)

# Or from host (if docker client available)
$env:DOCKER_HOST="tcp://localhost:2375"
docker ps
```

**STEP 4: Deploy Services INTO the VM**

```bash
# Initialize the StackKit INSIDE the VM (not on host!)
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli stackkit init dev-homelab --non-interactive

# Apply the configuration to the VM's Docker daemon
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli stackkit apply --auto-approve
```

**STEP 5: Verify Services Are IN the VM**

```bash
# On Windows host - should ONLY show the VM container
docker ps
# CONTAINER ID   IMAGE          COMMAND   STATUS          NAMES
# xxxxxxxx       stackkits-vm   "/entry…"   Up 2 minutes    stackkits-vm

# Inside the VM - should show ALL services
docker compose exec vm docker ps
# CONTAINER ID   IMAGE                    NAMES
# xxxxxxxx       traefik:v3.1             traefik
# xxxxxxxx       ghcr.io/steveiliop56/…   tinyauth
# xxxxxxxx       dokploy/dokploy:latest   dokploy
# xxxxxxxx       postgres:16-alpine       dokploy-postgres
```

**STEP 6: Deploy Managed Services via Dokploy**

After Dokploy is running inside the VM, deploy Kuma and Whoami THROUGH Dokploy:

```bash
# Get the admin password from terraform output
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli stackkit output dokploy_admin_password

# Deploy managed services (runs inside VM)
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli \
  bash -c "cd dev-homelab/templates/simple && ./deploy-managed-services.sh"
```

Or deploy via Dokploy UI:
1. Open http://dokploy.stack.local
2. Login with admin credentials (see below)
3. Create new project → Docker Compose
4. Upload the compose files

## First Login & Default Credentials

### 🔐 TinyAuth (Identity Provider)

**URL:** http://auth.stack.local

**Default Credentials:**
- **Username:** `admin`
- **Password:** `admin123`

These credentials are set in the Terraform configuration:
```hcl
env = [
  "USERS=admin:$2a$10$N9qo8uLOickgx2ZMRZoMy.MqrI0N3p9zqNVvB6fCNCkKeTLQ9b1Vy",
  # bcrypt hash of "admin123"
]
```

**First Login Steps:**
1. Navigate to http://auth.stack.local
2. Login with admin/admin123
3. **IMMEDIATELY change the password** (security best practice)
4. Configure additional users or OIDC provider if needed

### 🔐 Dokploy (PAAS Controller)

**URL:** http://dokploy.stack.local

**Default Credentials:**
- **Email:** `admin@stack.local`
- **Password:** Auto-generated on first run

**Get the password:**
```bash
docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli stackkit output dokploy_admin_password
```

**First Login Steps:**
1. Navigate to http://dokploy.stack.local
2. You'll be redirected to TinyAuth for authentication
3. Login with TinyAuth credentials (admin/admin123)
4. Dokploy will prompt you to complete setup

### 🔐 Uptime Kuma (Monitoring)

**URL:** http://kuma.stack.local

**Initial Setup:**
1. Navigate to http://kuma.stack.local
2. Create your admin account on first visit
3. Kuma is protected by TinyAuth - you'll login via auth.stack.local first

## Service Access Summary

| Service | URL | Protected | Default Credentials |
|---------|-----|-----------|---------------------|
| TinyAuth Login | http://auth.stack.local | No (login page) | admin / admin123 |
| Dokploy UI | http://dokploy.stack.local | Yes (TinyAuth) | Via TinyAuth SSO |
| Traefik Dashboard | http://traefik.stack.local | Yes (TinyAuth) | Via TinyAuth SSO |
| Uptime Kuma | http://kuma.stack.local | Yes (TinyAuth) | Set on first visit |
| Whoami Test | http://whoami.stack.local | Yes (TinyAuth) | Via TinyAuth SSO |

## Security Features

### Zero-Trust Architecture

1. **No Anonymous Admin Access**: All admin interfaces require TinyAuth authentication
2. **Passkey-First**: TinyAuth ready for passkey/WebAuthn authentication
3. **OIDC Integration**: Configure external IdP (Zitadel, Keycloak, etc.)
4. **mTLS Ready**: Infrastructure prepared for mutual TLS
5. **Network Segmentation**: Database on isolated internal network

### Container Security Hardening

All containers implement:
- Non-root users (where possible)
- Read-only root filesystems
- Dropped capabilities (ALL except required)
- No new privileges
- Resource limits

## Troubleshooting

### Verify VM-Only Deployment

```bash
# This should show ONLY the VM container
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# This should show ALL services (inside VM)
docker compose exec vm docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

### Services Not Accessible

1. Check Traefik is running IN the VM:
   ```bash
   docker compose exec vm docker logs traefik
   ```

2. Verify DNS resolution:
   ```bash
   nslookup dokploy.stack.local
   ```

3. Check Traefik dashboard: http://traefik.stack.local

### Cannot Deploy to VM

1. Verify Docker daemon is accessible:
   ```bash
   docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli docker info
   ```

2. Check VM is healthy:
   ```bash
   docker compose ps vm
   ```

### Authentication Issues

1. Check TinyAuth logs IN the VM:
   ```bash
   docker compose exec vm docker logs tinyauth
   ```

2. Verify middleware in Traefik: http://traefik.stack.local/dashboard/

3. Test auth directly:
   ```bash
   curl -v http://auth.stack.local/api/health
   ```

## Persistent Storage

All data persists across restarts (stored INSIDE the VM):

| Volume | Purpose | Backup |
|--------|---------|--------|
| dokploy-data | Dokploy configuration | Required |
| dokploy-postgres-data | Database | Required |
| kuma-data | Uptime Kuma monitoring data | Required |
| tinyauth-data | Authentication data | Required |
| traefik-certs | TLS certificates | Required |
| traefik-data | Traefik configuration | Optional |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAIN` | stack.local | Base domain for services |
| `DOCKER_HOST` | tcp://vm:2375 | Target Docker daemon (VM) |

### Custom Domains

Edit `dev-homelab/defaults.cue`:
```cue
domain: "mydomain.local"
services: {
    dokploy: domain: "paas.mydomain.local"
    kuma: domain: "monitor.mydomain.local"
}
```

## Architecture Compliance

This StackKit implements the 3-layer architecture:

- **Layer 1 (Foundation)**: Docker, networking, TinyAuth identity
- **Layer 2 (Platform)**: Traefik, Dokploy PAAS, network segmentation
- **Layer 3 (Applications)**: Kuma, Whoami (managed by Dokploy)

All services run INSIDE the Ubuntu VM for proper isolation and deployment testing.
