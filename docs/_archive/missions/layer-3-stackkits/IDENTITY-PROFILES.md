# Layer 3: StackKit Identity Profiles

**Scope:** Default identity configurations per StackKit. All settings can be adjusted by users.

---

## 1. Profile Overview

| StackKit | Identity | Auth Default | External Access |
|----------|----------|--------------|-----------------|
| dev-homelab | minimal | password OK | local-only |
| base-homelab | standard | passkey | local-only |
| modern-homelab | full | passkey + mTLS | tunnel/vpn |
| ha-homelab | full + audit | passkey + mTLS | tunnel + vpn |

---

## 2. Profiles

### 2.1 dev-homelab

Minimal setup for development:

```yaml
identity:
  providers:
    - type: "lldap"
      authMethods: ["password"]  # Simple for dev
  
  zeroTrust:
    enabled: false
  
  rbac:
    enabled: false
  
  externalAccess:
    profile: "local-only"
```

---

### 2.2 base-homelab

Standard homelab with passkeys:

```yaml
identity:
  providers:
    - type: "pocketid"
      primary: true
    - type: "lldap"
  
  zeroTrust:
    enabled: true
    deviceTrust:
      enabled: false
    identityTrust:
      requirePasskey: true
      allowPasswordFallback: false  # Set true if you prefer password
  
  rbac:
    enabled: true
    roleSource: "lldap"
  
  externalAccess:
    profile: "local-only"
```

**Want password login instead?**

```yaml
identity:
  zeroTrust:
    identityTrust:
      requirePasskey: false
      allowPasswordFallback: true
```

---

### 2.3 modern-homelab

Production with mTLS and external access:

```yaml
identity:
  providers:
    - type: "pocketid"
      primary: true
    - type: "lldap"
  
  zeroTrust:
    enabled: true
    deviceTrust:
      enabled: true
      requireCert: true
    identityTrust:
      requirePasskey: true
  
  pki:
    backend: "step-ca"
    internalMTLS: true
  
  rbac:
    enabled: true
    roleSource: "lldap"
  
  externalAccess:
    profile: "tunnel-only"
    tunnel:
      enabled: true
```

---

### 2.4 ha-homelab

High availability with full features:

```yaml
identity:
  providers:
    - type: "pocketid"
      primary: true
    - type: "lldap"
  
  zeroTrust:
    enabled: true
    deviceTrust:
      enabled: true
    identityTrust:
      requirePasskey: true
    networkSegmentation:
      enabled: true
  
  pki:
    backend: "step-ca"
    internalMTLS: true
    spiffe:
      enabled: true
  
  rbac:
    enabled: true
    roleSource: "lldap"
  
  externalAccess:
    profile: "vpn-plus-tunnel"
  
  audit:
    enabled: true
```

---

## 3. Components per StackKit

| Component | dev | base | modern | ha |
|-----------|-----|------|--------|-----|
| pocketid | - | ✓ | ✓ | ✓ |
| lldap | ✓ | ✓ | ✓ | ✓ |
| tinyauth | - | - | ✓ | ✓ |
| step-ca | - | ✓ | ✓ | ✓ |

---

## 4. Customization Examples

### Use any external OIDC provider

```yaml
identity:
  providers:
    - type: "external"
      name: "my-keycloak"
      oidcEndpoint: "https://keycloak.example.com/realms/homelab"
      primary: true
```

### Disable all security (not recommended)

```yaml
identity:
  zeroTrust:
    enabled: false
  rbac:
    enabled: false
```

### Password-only setup

```yaml
identity:
  providers:
    - type: "lldap"
      authMethods: ["password"]
  zeroTrust:
    enabled: false
```

---

## References

- [Layer 1 Identity](../../layer-1-foundation/base/IDENTITY.md)
- [base/security.cue](../../../base/security.cue)
