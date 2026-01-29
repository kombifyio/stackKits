# Foundation Layer: Identity & Zero-Trust Architecture

**Scope:** This document defines the identity patterns and authentication flows for self-hosted StackKits.

---

## 1. Philosophy

StackKits ship with **secure defaults**. Users can adjust **any setting** to match their needs.

| Default | Why | How to Change |
|---------|-----|---------------|
| Passkeys | Phishing-resistant | `identityTrust.allowPasswordFallback: true` |
| mTLS | Device verification | `deviceTrust.enabled: false` |
| Certificate auth for agents | No static secrets | `serviceIdentity.type: "oauth-client"` |

**Your homelab, your rules.** Want username+password? Enable it. Want no auth? Your choice.

---

## 2. Identity Architecture (Self-Hosted)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    HOMELAB LAYER (self-hosted)                               │
│                                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐          │
│  │  tinyauth   │  │  pocketid   │  │    lldap    │  │  step-ca   │          │
│  │  (Broker)   │  │  (Passkey)  │  │  (Directory)│  │   (PKI)    │          │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘          │
│                                                                              │
│  Optional: Connect any external OIDC provider you choose                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Components

| Component | Role | Technology |
|-----------|------|------------|
| tinyauth | Identity Broker & Proxy | OIDC Federation, mTLS |
| pocketid | Local Passkey IdP | WebAuthn / Passkeys |
| lldap | Directory Service | LDAP (groups, users) |
| step-ca | PKI & Certificate Authority | SCEP, ACME, x509 |
| (your choice) | External OIDC | Any OIDC provider |

---

## 3. Authentication Options

### 3.1 Default: Passkeys

```
User ──▶ tinyauth ──▶ pocketid ──▶ Passkey ──▶ OIDC Token
```

### 3.2 Alternative: Username + Password

```yaml
identity:
  zeroTrust:
    identityTrust:
      requirePasskey: false
      allowPasswordFallback: true
```

```
User ──▶ tinyauth ──▶ lldap ──▶ Username/Password ──▶ OIDC Token
```

### 3.3 Alternative: External OIDC Provider

Connect any OIDC provider (Keycloak, Authentik, Authelia, etc.):

```yaml
identity:
  providers:
    - type: "external"
      name: "my-keycloak"
      oidcEndpoint: "https://keycloak.example.com/realms/homelab"
      primary: true
```

---

## 4. Security Model

### 4.1 Device Trust (mTLS) - Optional

```yaml
zeroTrust:
  deviceTrust:
    enabled: true      # set to false to disable
    requireCert: true
    certAuthority: "step-ca"
```

### 4.2 Identity Trust (OIDC)

```yaml
zeroTrust:
  identityTrust:
    enabled: true
    requirePasskey: true           # false = allow password
    allowPasswordFallback: false   # true = enable password login
```

### 4.3 Simple Mode (No Zero-Trust)

For users who want traditional auth:

```yaml
zeroTrust:
  enabled: false

identity:
  providers:
    - type: "lldap"
      authMethods: ["password"]
```

---

## 5. RBAC (Optional)

### Standard Roles

| Role | Permissions | Use Case |
|------|-------------|----------|
| `owner` | `*` (all) | Full access |
| `operator` | deploy, update, monitor, backup | Operations |
| `developer` | deploy, logs, exec | Development |
| `viewer` | read, logs | Read-only |

### Configuration

```yaml
rbac:
  enabled: true          # set to false to disable RBAC
  roleSource: "lldap"    # or "local" for simple setups
  groupMappings:
    - externalGroup: "admins"
      internalRole: "owner"
```

---

## 6. PKI (Optional)

For mTLS and workload identity:

```yaml
pki:
  backend: "step-ca"
  internalMTLS: true
  spiffe:
    enabled: true
    trustDomain: "homelab.local"
```

---

## 7. External Access (Optional)

| Profile | Description |
|---------|-------------|
| `local-only` | No external access (default) |
| `tunnel-only` | Cloudflare Tunnel |
| `vpn-only` | WireGuard/OpenVPN |
| `vpn-plus-tunnel` | Combined |

```yaml
externalAccess:
  profile: "local-only"  # or any profile above
```

---

## 8. Emergency Access

```yaml
emergencyAccess:
  enabled: true
  username: "admin"
  offlineFallback: true  # Use lldap when primary IdP unreachable
```

---

## 9. Example Configurations

### Minimal (Username + Password)

```yaml
identity:
  providers:
    - type: "lldap"
      primary: true
      authMethods: ["password"]
  
  zeroTrust:
    enabled: false
  
  rbac:
    enabled: false
```

### Standard (Passkeys + lldap)

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
  
  rbac:
    enabled: true
    roleSource: "lldap"
```

### Full (mTLS + Passkeys + RBAC)

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
```

---

## References

- [base/security.cue](../../../base/security.cue) - CUE schema definitions
