# Dev Homelab - Production Ready

A production-ready homelab StackKit with Dokploy PAAS, Traefik reverse proxy, and Zero-Trust security architecture.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DEV HOMELAB ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LAYER 3: APPLICATIONS (Managed by Dokploy)                                │
│  ┌──────────────┐  ┌──────────────┐                                         │
│  │    Kuma      │  │    Whoami    │  ← Deployed THROUGH Dokploy UI/API     │
│  │ (Monitoring) │  │  (Test API)  │                                         │
│  └──────┬───────┘  └──────┬───────┘                                         │
│         │                 │                                                 │
│         └────────┬────────┘                                                 │
│                  ▼                                                          │
│  ┌──────────────────────────────────────┐                                   │
│  │           Dokploy PAAS               │  ← Manages Kuma & Whoami          │
│  │  ┌─────────────────────────────┐     │                                   │
│  │  │   PostgreSQL Database       │     │                                   │
│  │  │   (Internal Network Only)   │     │                                   │
│  │  └─────────────────────────────┘     │                                   │
│  └──────────────────────────────────────┘                                   │
│                         │                                                   │
│  LAYER 2: PLATFORM       ▼                                                  │
│  ┌──────────────────────────────────────┐                                   │
│  │        Traefik Reverse Proxy         │  ← Automatic HTTPS & Routing      │
│  │  • Routes: dokploy.stack.local       │                                   │
│  │  • Routes: kuma.stack.local          │                                   │
│  │  • Routes: whoami.stack.local        │                                   │
│  │  • Routes: auth.stack.local          │                                   │
│  └──────────────────────────────────────┘                                   │
│                         │                                                   │
│  LAYER 1: FOUNDATION     ▼                                                  │
│  ┌──────────────────────────────────────┐                                   │
│  │        TinyAuth (OIDC/SSO)           │  ← No Anonymous Admin Access      │
│  │  • Passkey-first authentication      │                                   │
│  │  • Protects all admin interfaces     │                                   │
│  └──────────────────────────────────────┘                                   │
│                                                                             │
│  Docker Networks:                                                           │
│  • dev_net (172.21.0.0/16)     - Main application network                  │
│  • dev_net_db (172.21.1.0/24)  - Internal database network (isolated)      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- OpenTofu/Terraform
- StackKit CLI (built from source)

### 1. Build StackKit CLI

```bash
cd /workspace
go build -o stackkit.exe ./cmd/stackkit
```

### 2. Initialize the StackKit

```bash
./stackkit.exe init dev-homelab --non-interactive
```

### 3. Deploy Infrastructure

```bash
./stackkit.exe apply --auto-approve
```

This deploys:
- Traefik reverse proxy (ports 80, 443, 8080)
- TinyAuth SSO proxy (auth.stack.local)
- Dokploy PAAS (dokploy.stack.local)
- Dokploy PostgreSQL (internal network only)

### 4. Deploy Managed Services

After Dokploy is running, deploy Kuma and Whoami THROUGH Dokploy:

```bash
# Get the admin password from terraform output
./stackkit.exe output dokploy_admin_password

# Deploy managed services
cd dev-homelab/templates/simple
chmod +x deploy-managed-services.sh
./deploy-managed-services.sh
```

Or deploy via Dokploy UI:
1. Open http://dokploy.stack.local
2. Login with admin credentials
3. Create new project → Docker Compose
4. Upload the compose files from `/tmp/kuma-compose.yaml` and `/tmp/whoami-compose.yaml`

### 5. Access Services

| Service | URL | Protected |
|---------|-----|-----------|
| Dokploy UI | http://dokploy.stack.local | Yes (TinyAuth) |
| Traefik Dashboard | http://traefik.stack.local | Yes (TinyAuth) |
| Uptime Kuma | http://kuma.stack.local | Yes (TinyAuth) |
| Whoami Test | http://whoami.stack.local | Yes (TinyAuth) |
| TinyAuth Login | http://auth.stack.local | No (login page) |

## Security Features

### Zero-Trust Architecture

1. **No Anonymous Admin Access**: All admin interfaces require authentication
2. **Passkey-First**: Ready for passkey/WebAuthn authentication
3. **OIDC Integration**: TinyAuth configured for external IdP (Zitadel, etc.)
4. **mTLS Ready**: Infrastructure prepared for mutual TLS (disabled for dev)
5. **Network Segmentation**: Database on isolated internal network

### Container Security Hardening

All containers implement:
- Non-root users (where possible)
- Read-only root filesystems
- Dropped capabilities (ALL except required)
- No new privileges
- Resource limits

### Authentication

Default credentials (change immediately):
- **TinyAuth**: admin / [auto-generated]
- **Dokploy**: admin@stack.local / [auto-generated]

Get passwords:
```bash
./stackkit.exe output tinyauth_admin_password
./stackkit.exe output dokploy_admin_password
```

## Persistent Storage

All data persists across restarts:

| Volume | Purpose | Backup |
|--------|---------|--------|
| dokploy-data | Dokploy configuration | Required |
| dokploy-postgres-data | Database | Required |
| kuma-data | Uptime Kuma monitoring data | Required |
| tinyauth-data | Authentication data | Required |
| traefik-certs | TLS certificates | Required |
| traefik-data | Traefik configuration | Optional |

## Testing

### Run E2E Tests

```bash
docker compose --profile e2e run --rm e2e
```

### Production Readiness Tests

```bash
# Enable all tests
export TEST_PERSISTENCE=true
export TEST_SECURITY=true
export TEST_DOKPLOY_INTEGRATION=true
./dev-homelab/tests/e2e_test.sh
```

### Manual Verification

1. **Persistence Test**: Restart containers, verify data remains
2. **Security Test**: Verify all admin UIs require auth
3. **Dokploy Integration**: Confirm Kuma/Whoami visible in Dokploy UI

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOMAIN` | stack.local | Base domain for services |
| `DOKPLOY_URL` | http://dokploy.stack.local | Dokploy access URL |
| `ENABLE_SECURITY_HARDENING` | true | Enable container security |
| `ACME_EMAIL` | admin@stack.local | Let's Encrypt email |

### Custom Domains

Edit `dev-homelab/defaults.cue`:
```cue
domain: "mydomain.local"
services: {
    dokploy: domain: "paas.mydomain.local"
    kuma: domain: "monitor.mydomain.local"
}
```

## Troubleshooting

### Services Not Accessible

1. Check Traefik is running: `docker logs traefik`
2. Verify DNS resolution: `nslookup dokploy.stack.local`
3. Check Traefik dashboard: http://traefik.stack.local

### Dokploy Not Managing Services

1. Ensure services have `dokploy.managed=true` label
2. Check Dokploy logs: `docker logs dokploy`
3. Verify Docker socket mount: `docker inspect dokploy | grep -A5 Mounts`

### Authentication Issues

1. Check TinyAuth logs: `docker logs tinyauth`
2. Verify middleware in Traefik: http://traefik.stack.local/dashboard/
3. Test auth directly: `curl -v http://auth.stack.local/api/health`

## Production Deployment

### Enable mTLS

Edit `dev-homelab/defaults.cue`:
```cue
security: mtls: {
    enabled: true
    provider: "step-ca"
    required: true
}
```

### Enable HTTPS Redirect

Edit `dev-homelab/templates/simple/main.tf`:
```hcl
command = [
    # ... other options ...
    "--entrypoints.web.http.redirections.entryPoint.to=websecure",
    "--entrypoints.web.http.redirections.entryPoint.scheme=https",
]
```

### External OIDC Provider

Configure TinyAuth for external IdP:
```bash
docker run ... \
    -e "OIDC_ISSUER=https://your-idp.com" \
    -e "OIDC_CLIENT_ID=your-client-id" \
    -e "OIDC_CLIENT_SECRET=your-client-secret" \
    ghcr.io/steveiliop56/tinyauth:v3
```

## File Structure

```
dev-homelab/
├── templates/
│   └── simple/
│       ├── main.tf                      # Main OpenTofu configuration
│       ├── deploy-managed-services.sh   # Deploy Kuma/Whoami via Dokploy
│       └── terraform.tfvars.example     # Example variables
├── tests/
│   └── e2e_test.sh                      # E2E test suite
├── defaults.cue                         # Default configuration
├── services.cue                         # Service definitions
├── stackfile.cue                        # Complete stack definition
└── README.md                            # This file
```

## Architecture Compliance

This StackKit implements the 3-layer architecture:

- **Layer 1 (Foundation)**: Docker, networking, security hardening
- **Layer 2 (Platform)**: Traefik, TinyAuth, network segmentation
- **Layer 3 (Applications)**: Dokploy PAAS, Kuma, Whoami

Security aligns with [Kombify Identity Plan](../missions/concepts/Kombify%20Identitätsplan_%20Zero-Trust%20Architektur%20für%20Homelab%20und%20SaaS.md):
- Passkey-first authentication ready
- No anonymous admin access
- mTLS infrastructure ready
- Network segmentation
- Secret-free for agents (SPIFFE-ready)