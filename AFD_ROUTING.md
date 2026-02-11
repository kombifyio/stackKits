# AFD Routing: kombify StackKits (IaC Library)

> Project-specific Azure Front Door routing configuration.

## This Project's Route

| Subdomain | AFD Route | Origin Group | Container App |
|-----------|-----------|--------------|---------------|
| `stackkits.kombify.io` | `route-stackkits-prod` | `og-stackkits-prod` | `ca-stackkits-web-prod` |

## Critical: DNS is at Spaceship, NOT Azure

- **Wildcard CNAME** `*.kombify.io` → AFD endpoint (already configured at Spaceship)
- NO per-project DNS changes needed for first-level subdomains
- Only AFD routing rules need to be added/modified in Azure
- The wildcard covers all `*.kombify.io` subdomains automatically

## How Traffic Reaches This Service

```
User → stackkits.kombify.io → Spaceship DNS (wildcard CNAME)
     → Azure Front Door (afd-kombify-prod)
     → Origin Group (og-stackkits-prod)
     → Container App (ca-stackkits-web-prod)
     → Port 80 (ingress)
```

## Azure CLI Quick Reference

```bash
# Check if this route exists in AFD
az afd route list \
  --profile-name afd-kombify-prod \
  --endpoint-name ep-kombify-prod \
  --resource-group rg-kombify-prod \
  -o table

# Check origin health
az afd origin show \
  --profile-name afd-kombify-prod \
  --origin-group-name og-stackkits-prod \
  --origin-name origin-stackkits-prod \
  --resource-group rg-kombify-prod

# Check Container App ingress
az containerapp show \
  --name ca-stackkits-web-prod \
  --resource-group rg-kombify-prod \
  --query "properties.configuration.ingress" -o yaml
```

## Troubleshooting

### Route not working?
1. Verify AFD custom domain exists for `stackkits.kombify.io`
2. Check origin group health probe is passing
3. Verify Container App ingress is enabled and targeting correct port
4. Check AFD managed certificate status (may take up to 15 min)

### Certificate issues?
- AFD uses managed certificates validated via DNS TXT records at Spaceship
- TXT record: `_dnsauth.stackkits.kombify.io` → AFD validation token
- Allow up to 15 minutes for certificate provisioning after DNS validation
