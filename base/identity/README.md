# Identity Module (Layer 1 Foundation)

This module provides identity and PKI services for StackKits as part of Layer 1 (Foundation).

## Services

### LLDAP (Lightweight LDAP)

A simplified LDAP server for user and group management.

**Features:**
- LDAP/LDAPS ports for service authentication
- Web UI for administration
- Lightweight and easy to configure
- Compatible with most LDAP-aware applications

**Default Configuration:**
- Web UI: `http://lldap.stack.local:17170`
- LDAP: `ldap://localhost:3890`
- LDAPS: `ldaps://localhost:6360`
- Admin user: `admin`

**Ports:**
| Port | Service |
|------|---------|
| 17170 | Web UI (HTTP) |
| 3890 | LDAP |
| 6360 | LDAPS (TLS) |

### Step-CA (Certificate Authority)

An internal Certificate Authority based on Smallstep.

**Features:**
- ACME protocol support for automated certificates
- SCEP support for device enrollment
- JWK provisioner for service-to-service mTLS
- Certificate lifecycle management

**Default Configuration:**
- API: `https://ca.stack.local:8443`
- Health: `https://localhost:8080/health`
- Provisioner: `stackkits`

**Ports:**
| Port | Service |
|------|---------|
| 8443 | CA API (HTTPS) |
| 8080 | Health endpoint |

## Integration with StackKits

Both services are automatically available to all StackKits through Layer 1 inheritance:

```cue
// In your StackKit, identity services are already configured
stackkit: {
    // LLDAP configuration (optional overrides)
    identity: lldap: {
        enabled: true
        domain: base: "dc=myorg,dc=com"
    }

    // Step-CA configuration (optional overrides)
    identity: stepCA: {
        enabled: true
        pki: rootCommonName: "MyOrg Root CA"
    }
}
```

## Network

Both services run on the `identity_net` Docker network:
- Subnet: `172.28.0.0/16`
- Other services can reach LLDAP and Step-CA via container names

## Security Notes

1. **Default Passwords**: Change default passwords in production using proper secret management
2. **LDAPS**: Always use LDAPS (port 6360) for production deployments
3. **Root CA**: Store the root CA certificate securely; it's the trust anchor for your infrastructure
4. **mTLS**: Enable mTLS for internal service communication using Step-CA provisioned certificates

## Files

| File | Purpose |
|------|---------|
| `lldap.cue` | LLDAP schema and service definition |
| `step-ca.cue` | Step-CA schema and service definition |
| `_lldap.tf.tmpl` | Terraform template for LLDAP deployment |
| `_step-ca.tf.tmpl` | Terraform template for Step-CA deployment |
