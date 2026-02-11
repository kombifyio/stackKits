# base-homelab Testing Reference

**Purpose:** Stackkit-specific test configuration for base-homelab variants.

---

## Service Test Matrix by Variant

### Default Variant

| Service | Port | Endpoint | Expected |
|---------|------|----------|----------|
| Traefik | 80/443/8080 | /dashboard/ | Dashboard UI |
| Dokploy | 3000 | / | Deploy UI |
| Uptime Kuma | 3001 | / | Status dashboard |
| Dozzle | 3004 | / | Log viewer |
| Whoami | 9080 | / | Hostname response |

### Beszel Variant

| Service | Port | Endpoint | Expected |
|---------|------|----------|----------|
| Traefik | 80/443/8080 | /dashboard/ | Dashboard UI |
| Dokploy | 3000 | / | Deploy UI |
| Beszel | 3003 | / | Metrics dashboard |
| Dozzle | 3004 | / | Log viewer |
| Whoami | 9080 | / | Hostname response |

### Minimal Variant

| Service | Port | Endpoint | Expected |
|---------|------|----------|----------|
| Traefik | 80/443/8080 | /dashboard/ | Dashboard UI |
| Dockge | 3005 | / | Stack management |
| Portainer | 9000 | / | Container management |
| Netdata | 19999 | / | Real-time metrics |
| Whoami | 9080 | / | Hostname response |

---

## Access Mode Testing

### Ports Mode (Local-Only)

- Services accessible on their designated ports
- No TLS required
- `advertise_host` determines access hostname

### Proxy Mode (Domain-Configured)

- Services accessible via subdomains: `{service}.{domain}`
- TLS via Let's Encrypt (requires `acme_email`)
- Domain must be configured

---

## Variant-Specific Validation

```cue
// Valid ports mode
_valid: #BaseHomelabStack & {
    variant:     "default"
    access_mode: "ports"
    network: advertise_host: "homelab.local"
}

// Valid proxy mode
_valid: #BaseHomelabStack & {
    variant:     "default"
    access_mode: "proxy"
    network: {
        domain:     "example.com"
        acme_email: "admin@example.com"
    }
}
```

---

## Cross-References

- [TESTING-STANDARDS.md](../../TESTING-STANDARDS.md) - Framework testing standards
- [../../../base-homelab/tests/](../../../base-homelab/tests/) - CUE test implementations
