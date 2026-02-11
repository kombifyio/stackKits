# Base Homelab StackKit - Validation Document

> **Last Updated:** 2026-01-29  
> **Status:** Source of Truth for Validation Logic  
> **Purpose:** Define all validation requirements, rules, and decision logic  
> **Scope:** CLI prep/init, CUE schemas, Kombify Unifier integration

---

## 1. Validation Architecture Overview

### 1.1 Validation Layers

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 4: Runtime Validation (Health Checks)                │
│  └─ Container health, service connectivity                  │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: Infrastructure Validation (OpenTofu)              │
│  └─ tofu validate, resource constraints                     │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Schema Validation (CUE)                           │
│  └─ Type checking, constraints, decision trees              │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: Input Validation (CLI/API)                        │
│  └─ YAML parsing, required fields, format checks            │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Validation Stages

| Stage | When | What | Tool |
|-------|------|------|------|
| **Pre-Parse** | Input received | File exists, readable, valid YAML | CLI |
| **Schema Validation** | After parsing | Type constraints, field validation | CUE |
| **Semantic Validation** | After schema | Business rules, dependencies | CUE + Go |
| **Infrastructure Validation** | Before apply | TF validation, resource checks | OpenTofu |
| **Runtime Validation** | After deploy | Health checks, connectivity | Docker |

---

## 2. Input Validation (Layer 1)

### 2.1 File Validation

| Check | Rule | Error Message |
|-------|------|---------------|
| File exists | `os.Stat(path) != nil` | "Spec file not found: {path}" |
| File readable | `os.Open(path)` succeeds | "Cannot read spec file: {error}" |
| Valid YAML | `yaml.Unmarshal()` succeeds | "Invalid YAML syntax: {error}" |
| Valid encoding | UTF-8 without BOM | "File must be UTF-8 encoded" |

### 2.2 Required Fields (stack-spec.yaml)

| Field | Type | Required | Default |
|-------|------|----------|---------|
| `name` | string | ✅ Yes | - |
| `stackKit` | string | ✅ Yes | - |
| `variant` | string | ⚪ No | `default` |
| `mode` | string | ⚪ No | `simple` |
| `network` | object | ⚪ No | (defaults) |
| `compute` | object | ⚪ No | (defaults) |
| `ssh` | object | ⚪ No | (defaults) |

### 2.3 Field Format Validation

| Field | Pattern | Example | Invalid |
|-------|---------|---------|---------|
| `name` | `/^[a-z][a-z0-9-]{2,62}$/` | `my-homelab` | `My_Lab`, `1abc` |
| `network.subnet` | CIDR notation | `172.20.0.0/16` | `172.20.0.0` |
| `network.domain` | FQDN or empty | `lab.example.com` | `lab..com` |
| `ssh.port` | 1-65535 | `22` | `0`, `70000` |
| `ssh.user` | `/^[a-z_][a-z0-9_-]*$/` | `ubuntu` | `Root`, `123` |

---

## 3. Schema Validation (Layer 2 - CUE)

### 3.1 Type Validators

**Location:** `base/validation.cue`

```cue
#Validators: {
    // IPv4 address
    ipv4: =~"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}..."
    
    // CIDR notation
    cidr: =~"^((25[0-5]|...))/([0-9]|[12][0-9]|3[0-2])$"
    
    // FQDN
    fqdn: =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]...)+"
    
    // Email
    email: =~"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    
    // Semantic version
    semver: =~"^v?[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?$"
    
    // Memory size
    memorySize: =~"^[0-9]+(m|g|k|M|G|K|Mi|Gi|Ki)$"
    
    // Duration
    duration: =~"^[0-9]+(s|m|h|d)$"
    
    // Cron expression
    cron: =~"^[0-9*,/\\-]+ [0-9*,/\\-]+ ..."
}
```

### 3.2 Constraint Types

| Type | Constraint | Example |
|------|------------|---------|
| `#PortRange` | `uint16 & >0 & <=65535` | Valid port number |
| `#MemoryMB` | `int & >=64` | Memory >= 64MB |
| `#DiskGB` | `int & >=1` | Disk >= 1GB |
| `#CPUCores` | `int & >=1 & <=256` | CPU core count |
| `#ReplicaCount` | `int & >=1 & <=99` | Replica limit |

### 3.3 Enum Validations

| Field | Valid Values | Error if Invalid |
|-------|--------------|------------------|
| `variant` | `default`, `coolify`, `beszel`, `minimal` | "Invalid variant" |
| `mode` | `simple`, `advanced` | "Invalid deployment mode" |
| `compute.tier` | `auto`, `low`, `standard`, `high` | "Invalid compute tier" |
| `network.mode` | `local`, `cloud` | "Invalid network mode" |
| `service.type` | See #ServiceType | "Unknown service type" |

---

## 4. Semantic Validation (Business Rules)

### 4.1 Cross-Field Dependencies

| Rule | Condition | Validation |
|------|-----------|------------|
| **Coolify requires domain** | `variant == "coolify"` | `domain != ""` |
| **Let's Encrypt requires email** | `tls.mode == "acme"` | `acmeEmail != ""` |
| **Advanced mode requires Terramate** | `mode == "advanced"` | Terramate installed |
| **Proxy mode requires domain** | `access_mode == "proxy"` | `domain != ""` |
| **High tier requires resources** | `tier == "high"` | `cpu >= 8 && memory >= 16` |

### 4.2 Service Dependency Validation

| Service | Depends On | Validation |
|---------|------------|------------|
| Dokploy | Traefik | Traefik enabled |
| Coolify | Traefik | Traefik enabled |
| Uptime Kuma | Traefik | Traefik enabled |
| All services | Docker | Docker installed |

### 4.3 Port Conflict Detection

```go
func validatePortConflicts(services []Service) []Error {
    usedPorts := make(map[int]string)
    var errors []Error
    
    for _, svc := range services {
        for _, port := range svc.Ports {
            if existing, ok := usedPorts[port.Host]; ok {
                errors = append(errors, Error{
                    Field:   fmt.Sprintf("services.%s.ports", svc.Name),
                    Message: fmt.Sprintf("Port %d already used by %s", port.Host, existing),
                })
            }
            usedPorts[port.Host] = svc.Name
        }
    }
    return errors
}
```

### 4.4 Resource Validation

| Check | Rule | Error |
|-------|------|-------|
| Memory per container | `<= node.memory * 0.8` | "Container memory exceeds node capacity" |
| Total containers | `<= tier.maxContainers` | "Too many containers for tier" |
| Disk space | `>= sum(volume.sizes) * 1.5` | "Insufficient disk space" |

---

## 5. Decision Trees

### 5.1 TLS Decision Tree

**Location:** `base/validation.cue` - `#TLSDecision`

```
START
  │
  ├─ Has domain?
  │   ├─ No  → mode: "none" (ports mode)
  │   └─ Yes ─┬─ Is .local/.lan/.internal?
  │           │   └─ Yes → mode: "self-signed"
  │           └─ No (public domain)
  │               ├─ Has ACME email?
  │               │   └─ Yes → mode: "acme"
  │               └─ No → mode: "self-signed" + warning
```

**CUE Implementation:**

```cue
#TLSDecision: {
    mode: "acme" | "self-signed" | "custom" | "none"
    
    // Inputs
    domain: string | *""
    acmeEmail: string | *""
    
    // Decision logic
    if domain == "" {
        mode: "none"
    }
    if domain =~ "\\.(local|lan|home|internal|test)$" {
        mode: "self-signed"
    }
    if domain != "" && acmeEmail != "" && !(domain =~ "\\.(local|...)$") {
        mode: "acme"
    }
}
```

### 5.2 Variant Selection Decision Tree

```
START
  │
  ├─ User specified variant?
  │   └─ Yes → Use specified variant
  │
  ├─ No → Auto-select based on:
  │   │
  │   ├─ Has domain?
  │   │   ├─ No → default (Dokploy)
  │   │   └─ Yes ─┬─ Is local domain?
  │   │           │   └─ Yes → default (Dokploy)
  │   │           └─ Public domain → coolify (Coolify)
  │   │
  │   └─ Explicit "no PaaS" → minimal
```

### 5.3 Compute Tier Decision Tree

```
START
  │
  ├─ tier == "auto"?
  │   └─ Yes → Detect from hardware:
  │       │
  │       ├─ cpu >= 8 AND memory >= 16 → high
  │       ├─ cpu < 4 OR memory < 8 → low
  │       └─ else → standard
  │
  └─ tier specified → Validate against hardware:
      │
      ├─ tier == "high" AND (cpu < 8 OR memory < 16) → warning
      ├─ tier == "standard" AND (cpu < 4 OR memory < 8) → warning
      └─ tier == "low" → always valid
```

### 5.4 Backup Decision Tree

```
START
  │
  ├─ backup.enabled == false → Skip backup config
  │
  └─ backup.enabled == true
      │
      ├─ Validate backend: restic | borgbackup | rclone
      ├─ Validate schedule: cron expression
      ├─ Validate retention: daily >= 1
      │
      └─ Validate destination:
          ├─ type: local → path required
          ├─ type: s3 → bucket, region required
          ├─ type: sftp → host, user, path required
          └─ type: b2 → bucket required
```

---

## 6. CLI Validation Commands

### 6.1 `stackkit validate`

**Purpose:** Run all validations on spec file

**Exit Codes:**
| Code | Meaning |
|------|---------|
| 0 | All validations passed |
| 1 | Validation errors found |
| 2 | File not found or unreadable |
| 3 | Invalid YAML syntax |

**Output Format:**

```
✓ Spec file syntax valid
✓ Schema validation passed
✓ Service dependencies valid
⚠ Port 8080 conflicts with Traefik dashboard (warning)
✗ Coolify variant requires domain to be set

Errors: 1, Warnings: 1
```

### 6.2 `stackkit prepare`

**Pre-Deployment Validation:**

| Check | Command | Requirement |
|-------|---------|-------------|
| SSH connectivity | `ssh -o BatchMode=yes` | Connection succeeds |
| Docker installed | `docker --version` | Docker >= 20.10 |
| Docker running | `docker info` | Daemon responsive |
| OpenTofu installed | `tofu version` | OpenTofu >= 1.6 |
| Disk space | `df -h` | >= 20GB free |
| Memory | `free -g` | >= 2GB available |

**Auto-Fix Options:**

| Issue | Auto-Fix |
|-------|----------|
| Docker not installed | Install Docker |
| OpenTofu not installed | Install OpenTofu |
| Firewall blocks ports | Open required ports |
| SSH key not authorized | Copy SSH key |

---

## 7. CUE Validation Test Cases

### 7.1 Required Test Scenarios

**Location:** `base-homelab/tests/`

| Test | Description | Expected |
|------|-------------|----------|
| `_validDefaultVariant` | Minimal valid default config | Pass |
| `_validCoolifyVariant` | Coolify with domain | Pass |
| `_validBeszelVariant` | Beszel monitoring | Pass |
| `_validMinimalVariant` | Minimal variant | Pass |
| `_invalidCoolifyNoDomain` | Coolify without domain | Fail |
| `_invalidPortConflict` | Duplicate ports | Fail |
| `_invalidLowTierHighMem` | Low tier with 4GB container | Fail |
| `_invalidACMENoEmail` | ACME without email | Fail |

### 7.2 Test Template

```cue
// Test: Description
_testName: #BaseHomelabStack & {
    meta: {
        name:    "test-case"
        version: "3.0.0"
    }
    variant: "default"
    nodes: [{
        id:   "node-1"
        name: "test-node"
        host: "192.168.1.100"
        compute: {
            cpuCores:  4
            ramGB:     8
            storageGB: 100
        }
    }]
    network: {
        domain:    "test.local"
        acmeEmail: "test@example.com"
    }
    services: {
        traefik: enabled: true
        // ... service toggles
    }
}
```

---

## 8. Kombify Unifier Integration

### 8.1 Unifier Validation Flow

```
User Input (kombination.yaml)
       │
       ▼
┌──────────────────┐
│  Parse YAML      │
│  (basic syntax)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Resolve StackKit│
│  Load schemas    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  CUE Validation  │
│  (unified spec)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Generate Output │
│  (stack-spec.yaml)│
└──────────────────┘
```

### 8.2 Unifier Validation Rules

| Rule | When Applied | Action |
|------|--------------|--------|
| Missing StackKit | No stackKit field | Error: "stackKit required" |
| Unknown StackKit | StackKit not found | Error: "Unknown stackKit: {name}" |
| Invalid variant | Variant not in StackKit | Error: "Invalid variant for {stackKit}" |
| Missing required | Required field empty | Error: "{field} is required" |
| Type mismatch | Wrong type | Error: "{field} must be {type}" |

### 8.3 Validation API (Go)

```go
type ValidationResult struct {
    Valid    bool
    Errors   []ValidationError
    Warnings []ValidationWarning
}

type ValidationError struct {
    Path    string // e.g., "network.domain"
    Message string
    Code    string // e.g., "REQUIRED_FIELD"
}

type ValidationWarning struct {
    Path    string
    Message string
    Code    string
}

func ValidateSpec(spec *StackSpec) (*ValidationResult, error) {
    result := &ValidationResult{Valid: true}
    
    // Layer 1: Input validation
    if err := validateInput(spec); err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, err...)
    }
    
    // Layer 2: CUE schema validation
    if err := validateSchema(spec); err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, err...)
    }
    
    // Layer 3: Semantic validation
    if err := validateSemantics(spec); err != nil {
        result.Valid = false
        result.Errors = append(result.Errors, err...)
    }
    
    return result, nil
}
```

---

## 9. Error Catalog

### 9.1 Error Codes

| Code | Category | Description |
|------|----------|-------------|
| `E001` | Input | File not found |
| `E002` | Input | Invalid YAML syntax |
| `E003` | Input | Required field missing |
| `E010` | Schema | Type mismatch |
| `E011` | Schema | Invalid enum value |
| `E012` | Schema | Constraint violation |
| `E020` | Semantic | Dependency not satisfied |
| `E021` | Semantic | Port conflict |
| `E022` | Semantic | Resource exceeded |
| `E030` | Infra | OpenTofu validation failed |
| `E031` | Infra | Provider error |
| `E040` | Runtime | Health check failed |
| `E041` | Runtime | Container not running |

### 9.2 Error Message Templates

```go
var errorTemplates = map[string]string{
    "E001": "Spec file not found: %s",
    "E002": "Invalid YAML at line %d: %s",
    "E003": "Required field '%s' is missing",
    "E010": "Field '%s' must be %s, got %s",
    "E011": "Invalid value '%s' for '%s'. Valid options: %s",
    "E020": "Service '%s' depends on '%s' which is not enabled",
    "E021": "Port %d is already used by '%s'",
    "E022": "Container memory %s exceeds node capacity %s",
}
```

---

## 10. Validation Checklist

### 10.1 Before Release

- [ ] All CUE tests pass (`cue vet ./...`)
- [ ] All Go tests pass (`go test ./...`)
- [ ] All variants validated in CI
- [ ] Error messages reviewed for clarity
- [ ] Documentation updated for new validations

### 10.2 Per-Commit

- [ ] New fields have type constraints
- [ ] New services have dependency definitions
- [ ] New ports checked for conflicts
- [ ] Decision trees updated if logic changes

---

## Appendix A: Validation Regex Patterns

```cue
// Full patterns for reference
patterns: {
    hostname: "^[a-z][a-z0-9-]{0,62}[a-z0-9]?$"
    ipv4: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    cidr: "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/([0-9]|[12][0-9]|3[0-2])$"
    fqdn: "^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$"
    email: "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    semver: "^v?[0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9.]+)?(\\+[a-zA-Z0-9.]+)?$"
    memorySize: "^[0-9]+(m|g|k|M|G|K|Mi|Gi|Ki)$"
    duration: "^[0-9]+(s|m|h|d)$"
    cron: "^(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|((\\*|[0-9,\\-\\/]+)\\s){4}(\\*|[0-9,\\-\\/]+)$"
    dockerImage: "^[a-z0-9]([a-z0-9._\\/-]*[a-z0-9])?(:[a-zA-Z0-9._-]+)?(@sha256:[a-f0-9]{64})?$"
}
```

---

## Appendix B: OpenTofu Validation Variables

```hcl
# Variables with validation blocks
variable "access_mode" {
  type    = string
  default = "ports"
  validation {
    condition     = contains(["ports", "proxy"], var.access_mode)
    error_message = "access_mode must be 'ports' or 'proxy'"
  }
}

variable "variant" {
  type    = string
  default = "default"
  validation {
    condition     = contains(["default", "coolify", "beszel", "minimal"], var.variant)
    error_message = "variant must be 'default', 'coolify', 'beszel', or 'minimal'"
  }
}

variable "compute_tier" {
  type    = string
  default = "standard"
  validation {
    condition     = contains(["high", "standard", "low"], var.compute_tier)
    error_message = "compute_tier must be 'high', 'standard', or 'low'"
  }
}
```
