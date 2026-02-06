# StackKits – Technical Architecture

> **For Developers, DevOps Engineers, and Technical Architects**  
> **Version:** 1.0 | February 2026

---

## Architecture Overview

StackKits implements a validation-first infrastructure-as-code approach using three core technologies:

| Component | Technology | Responsibility |
|-----------|------------|----------------|
| **Schema & Validation** | CUE | Type checking, constraint enforcement, configuration unification |
| **Provisioning** | OpenTofu | Infrastructure resource creation and management |
| **Orchestration** | Terramate | Multi-stack coordination, drift detection, change management |

Everything else (Docker, Traefik, Dokploy, etc.) are tools configured within blueprints – implementation details, not architectural components.

---

## System Design

### Data Flow

```
User Input (stack-spec.yaml)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    CUE VALIDATION                            │
│                                                              │
│  base/*.cue          StackKit schemas and defaults          │
│  platforms/*.cue     Platform-specific configurations        │
│  stackkit/*.cue      StackKit-specific services and variants │
│                                                              │
│  $ cue vet ./base/... ./stackkit/... stack-spec.yaml        │
│                                                              │
│  Output: Validated, unified configuration OR error report    │
└─────────────────────────────────────────────────────────────┘
         │
         ▼ (if validation passes)
┌─────────────────────────────────────────────────────────────┐
│                  OPENTOFU GENERATION                         │
│                                                              │
│  Validated config → main.tf, providers.tf, variables.tf     │
│                                                              │
│  Simple mode:   tofu init → tofu plan → tofu apply          │
│  Advanced mode: terramate run -- tofu [command]             │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    INFRASTRUCTURE                            │
│                                                              │
│  Layer 1: Foundation (SSH, firewall, identity)              │
│  Layer 2: Platform (containers, proxy, PaaS)                │
│  Layer 3: Applications (user services via PaaS)             │
└─────────────────────────────────────────────────────────────┘
```

---

## CUE Schema System

### Why CUE

CUE provides capabilities unavailable in JSON Schema or YAML validation:

| Feature | CUE | JSON Schema | YAML Lint |
|---------|-----|-------------|-----------|
| Unified types and values | Yes | No | No |
| Native constraints | Yes | Verbose | No |
| Composition via unification | Yes | Limited ($ref) | No |
| Default values | Native | Verbose | No |
| Built-in templating | Yes | No | No |
| Module system | Yes | Limited | No |

### Schema Structure

```
base/
├── stackkit.cue      # Core StackKit composition schema
├── system.cue        # Host configuration schemas
├── security.cue      # Security-related schemas
├── network.cue       # Network configuration schemas
├── identity.cue      # Identity and authentication schemas
├── observability.cue # Logging, metrics, alerting schemas
└── validation.cue    # Cross-cutting validation rules
```

### Example Schema Definition

```cue
// base/security.cue

#SSHHardening: {
    // Port with range constraint and default
    port: uint16 & >0 & <=65535 | *22

    // Enumerated value with secure default
    permitRootLogin: "yes" | "no" | "prohibit-password" | *"no"

    // Boolean with secure default
    passwordAuth: bool | *false
    pubkeyAuth: bool | *true

    // Constrained integer
    maxAuthTries: int & >=1 & <=10 | *3

    // Optional list
    allowUsers: [...string] | *[]
}
```

### Validation Process

```
Input:                          Schema:                        Result:
───────                        ────────                       ────────

security:                      #SSHHardening: {               Error: port 70000
  ssh:                           port: uint16 & <=65535         out of bound (>65535)
    port: 70000          →       ...                     →    
    passwordAuth: "yes"        }                              Error: "yes" != bool
                                                                Expected: bool
                                                                Got: string
```

---

## 3-Layer Architecture

### Layer 1: Foundation

**Location:** `/base/`

The foundation layer provides immutable infrastructure base configuration.

| Component | Schema | Description |
|-----------|--------|-------------|
| system | #SystemConfig | Hostname, timezone, locale |
| packages | #BasePackages | System package installation |
| security.ssh | #SSHHardening | SSH server configuration |
| security.firewall | #FirewallPolicy | Firewall rules |
| identity.lldap | #LLDAPConfig | LDAP directory service |
| identity.stepCA | #StepCAConfig | PKI certificate authority |

**Settings Classification:**

| Setting | Type | Rationale |
|---------|------|-----------|
| security.ssh.port | Permanent | Changing requires firewall and client reconfiguration |
| identity.lldap.domain.base | Permanent | Changing invalidates all identity references |
| system.timezone | Flexible | Can be updated via standard apply |

### Layer 2: Platform

**Location:** `/base/platform/`, `/platforms/`

The platform layer manages container runtime and orchestration.

| Component | Schema | Description |
|-----------|--------|-------------|
| platform | #PlatformType | docker, docker-swarm, kubernetes, bare-metal |
| container | #ContainerRuntime | Docker/Podman configuration |
| network.defaults | #NetworkDefaults | Network mode, subnets, driver |
| paas | #PAASConfig | Dokploy, Coolify, or similar |
| identity | #PlatformIdentityConfig | TinyAuth, PocketID, Authelia |

### Layer 3: Applications

**Location:** `/<stackkit-name>/services.cue`

Applications are managed by the Layer 2 PaaS, not directly by Terraform.

**Design Principle:**

> Layer 2 services (Traefik, Dokploy) are deployed via Terraform.  
> Layer 3 services (user applications) are deployed via the PaaS UI.

This separation enables:
- User control over applications without IaC knowledge
- Application updates without Terraform runs
- Clear responsibility boundaries

---

## Deployment Modes

### Simple Mode

Standard OpenTofu workflow for single-stack deployments:

```bash
stackkit generate
cd deploy
tofu init
tofu plan
tofu apply
```

### Advanced Mode

Terramate-orchestrated workflow for multi-stack and Day-2 operations:

```bash
stackkit generate --mode advanced

# Initial deployment
terramate run -- tofu init
terramate run -- tofu plan
terramate run -- tofu apply

# Change detection
terramate list --changed

# Drift detection
terramate run -- tofu plan -detailed-exitcode
# Exit 0 = in sync, Exit 2 = drift detected

# Selective apply
terramate run --changed -- tofu apply
```

---

## Security Architecture

### Defense Layers

| Layer | Components |
|-------|------------|
| SSH | Key-only auth, root disabled, max attempts limited |
| Firewall | UFW with default deny, explicit allow rules |
| Containers | Drop all capabilities, no privileged mode, seccomp |
| Network | Internal Docker networks, Traefik as single entry |
| TLS | Automatic certificates via Let's Encrypt |
| Identity | LLDAP for directory, Step-CA for PKI |

### Container Security Defaults

```cue
#ContainerSecurityContext: {
    runAsNonRoot: bool | *true
    privileged: bool | *false
    capabilitiesDrop: [...string] | *["ALL"]
    capabilitiesAdd: [...string] | *[]
    noNewPrivileges: bool | *true
    seccompProfile: "RuntimeDefault" | "Unconfined" | *"RuntimeDefault"
}
```

These defaults enforce security even if users don't explicitly configure it.

---

## Service Definition Schema

```cue
#ServiceDefinition: {
    name: =~"^[a-z][a-z0-9-]+$"
    displayName: string
    category: "core" | "platform" | "observability" | "application"
    type: string
    required: bool | *false
    
    image: string
    tag: string | *"latest"
    
    network: {
        ports: [...#PortMapping]
        mode: "bridge" | "host" | "none" | *"bridge"
    }
    
    volumes: [...#VolumeMount]
    healthCheck: #HealthCheck
    resources?: #ContainerResourceLimits
    config: {...}
}
```

---

## CLI Architecture

### Commands

| Command | Description |
|---------|-------------|
| `stackkit init <stackkit>` | Initialize workspace with selected StackKit |
| `stackkit validate` | Run CUE validation |
| `stackkit prepare` | Check prerequisites |
| `stackkit generate` | Generate OpenTofu files |
| `stackkit plan` | Preview infrastructure changes |
| `stackkit apply` | Deploy infrastructure |
| `stackkit drift` | Detect configuration drift |
| `stackkit destroy` | Remove infrastructure |
| `stackkit list` | Show available StackKits |

### Internal Flow

```go
// Simplified validation flow

func (c *CLI) Validate(specPath string) error {
    // Load user specification
    spec := loadSpec(specPath)
    
    // Resolve StackKit schemas
    stackkit := resolveStackKit(spec.StackKit)
    
    // CUE unification
    ctx := cue.NewContext()
    unified := ctx.Unify(stackkit.Schema, spec)
    
    // Validate and report errors
    if err := unified.Validate(); err != nil {
        return formatValidationErrors(err)
    }
    
    return nil
}
```

---

## Extensibility

### Creating Custom StackKits

```
my-stackkit/
├── stackkit.yaml      # Metadata
├── stackkit.cue       # Main schema (imports base)
├── services.cue       # Service definitions
├── defaults.cue       # Default values
├── variants/
│   ├── default.cue
│   └── minimal.cue
└── templates/
    └── main.tf.tmpl
```

```cue
// my-stackkit/stackkit.cue
package my_stackkit

import "github.com/kombihq/stackkits/base"

#StackKitDefinition: base.#BaseStackKit & {
    metadata: {
        name: "my-stackkit"
        version: "1.0.0"
    }
    
    services: [
        base_homelab.#TraefikService,
        #MyCustomService,
    ]
}
```

---

## Testing

### Validation Testing

```bash
# Run CUE validation on all schemas
cue vet ./base/... ./base-homelab/...

# Test specific configurations
cue vet -c schema.cue test-config.yaml
```

### Integration Testing

```bash
# Full deployment test
docker compose up -d vm
docker compose run --rm cli ./stackkit apply
# Verify services
docker compose exec vm docker ps
```

---

## References

- [CUE Language Specification](https://cuelang.org/docs/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terramate Documentation](https://terramate.io/docs/)

---

*StackKits: Validated infrastructure blueprints built on CUE, OpenTofu, and Terramate.*
