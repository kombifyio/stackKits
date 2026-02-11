# kombify Platform Infrastructure Reference

> Shared reference for all kombify repositories.
> Single source of truth for subdomains, routing, and secrets.

## Subdomain Registry

| Subdomain | Zweck | Azure Resource | Typ |
|---|---|---|---|
| `kombify.io` | Marketing/Portal | Appwrite Sites | Marketing |
| `app.kombify.io` | kombify Cloud Cloud SaaS | `ca-kombify-portal-prod` | App |
| `api.kombify.io` | Kong API Gateway | `ca-kombify-gateway-prod` | API |
| `techstack.kombify.io` | kombify Stack App | `ca-kombify-stack-prod` | App |
| `stack.kombify.io` | kombify Stack Marketing | `ca-stack-web-prod` | Marketing |
| `simulate.kombify.io` | kombify Sim App | `ca-sim-app-prod` | App |
| `sim.kombify.io` | kombify Sim Marketing | `ca-sim-web-prod` | Marketing |
| `stackkits.kombify.io` | StackKits Docs | `ca-stackkits-web-prod` | Docs |
| `admin.kombify.io` | Administration | `ca-kombify-admin-prod` | App |
| `blog.kombify.io` | Blog | Azure Static Web App | Content |
| `docs.kombify.io` | Mintlify Docs | External (Mintlify) | Docs |

**IMPORTANT:** Sub-subdomains (e.g. `app.sim.kombify.io`) do NOT resolve.
The `*.kombify.io` wildcard only covers first-level subdomains.

## DNS + Azure Front Door Routing

```
DNS (Spaceship)  -->  Azure Front Door (afd-kombify-prod)  -->  Azure Container Apps
```

### How it works

1. **Spaceship DNS**: CNAME records per subdomain pointing to AFD endpoint
   - `simulate.kombify.io` CNAME → `afd-kombify-prod-XXXXX.z01.azurefd.net`
   - TXT `_dnsauth.simulate.kombify.io` → AFD domain validation token
2. **Azure Front Door**: Custom Domain with Managed TLS Certificate
   - Origin Group → Origin (ACA internal FQDN)
   - Route Rule: maps subdomain to the correct origin group
3. **Azure Container Apps**: Internal FQDN (not directly accessible from internet)
   - e.g. `ca-sim-app-prod.niceisland-XXXXX.westeurope.azurecontainerapps.io`

### Key rules

- DNS is NOT in Azure. Changes to DNS records happen at Spaceship separately.
- Each new subdomain requires ALL of these steps:
  1. Spaceship: Add CNAME record
  2. Spaceship: Add TXT record for domain validation (`_dnsauth.`)
  3. AFD: Add Custom Domain + wait for TLS cert provisioning
  4. AFD: Create/update Origin Group with ACA origin
  5. AFD: Create Route mapping subdomain → origin group
  6. ACA: Configure ingress for the container app
- AFD Managed Certificates require DNS validation (TXT record at Spaceship).
- Certificate provisioning can take up to 15 minutes after DNS validation.

## Azure Infrastructure

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | `rg-kombify-prod` | All production resources |
| Container Registry | `acrkombifyprod` | Docker images |
| Key Vault | `kv-kombify-prod` | Runtime secrets |
| PostgreSQL | `psql-kombify-db.postgres.database.azure.com` | Databases |
| Container Apps Env | `cae-kombify-prod` | All Container Apps |
| Front Door | `afd-kombify-prod` | CDN + WAF + TLS + Routing |
| Log Analytics | `log-kombify-prod` | Centralized logging |

## Secrets Management

**Primary source: Doppler** (project `kombify-platform`)

Sync flow: Doppler → GitHub Environment Secrets → GitHub Actions → ACA → Key Vault (runtime)

| Doppler Project | Purpose |
|---|---|
| `kombify-platform` | Shared URLs, infrastructure secrets |
| `kombify Cloud-cloud` | Cloud-specific (Stripe, Zitadel client IDs) |

## Docker Networking (Local Development)

All repos use the shared Docker network `kombify-shared`.

```bash
# Start database first (creates the network)
cd ../kombify-DB && docker compose up -d

# Then start any other service
docker compose up -d
```

Services discover each other by container name on the `kombify-shared` network.
