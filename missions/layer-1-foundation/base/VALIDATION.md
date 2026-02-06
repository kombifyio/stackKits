# Foundation Layer: Base Validation Architecture

**Scope:** This document defines the universal validation patterns, CUE type system, decision trees, and error catalog used by ALL StackKits. Platform-specific validation (Docker, Kubernetes) extends these patterns in Layer 2.

---

## 1. Multi-Stage Validation Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VALIDATION FLOW                                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [User Input]                                                            │
│       │                                                                  │
│       ▼                                                                  │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐      │
│  │ Stage 1:        │───▶│ Stage 2:        │───▶│ Stage 3:        │      │
│  │ Input           │    │ CUE Schema      │    │ Semantic        │      │
│  │ Validation      │    │ Validation      │    │ Validation      │      │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘      │
│       │                       │                       │                  │
│       ▼                       ▼                       ▼                  │
│  [Format & Type]        [Structure &          [Cross-field &            │
│                          Constraints]          Business Rules]           │
│                                                       │                  │
│                                                       ▼                  │
│                                ┌─────────────────────────────────────┐  │
│                                │ Stage 4: Platform Validation         │  │
│                                │ (Delegated to Layer 2)               │  │
│                                └─────────────────────────────────────┘  │
│                                                       │                  │
│                                                       ▼                  │
│                                              [Validated Config]          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Stage 1: Input Validation

### 2.1 Required Fields

All StackKits MUST validate these required fields at input stage:

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | ✓ | RFC 1123 hostname format |
| `version` | string | ✓ | Semantic versioning (x.y.z) |
| `services` | map | ✓ | At least one service defined |
| `network.domain` | string | ✓ | Valid domain format |

### 2.2 Input Validation Regex Patterns

```cue
// DNS hostname (RFC 1123)
#HostnamePattern: =~"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$"

// Domain name
#DomainPattern: =~"^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$"

// Semantic version
#SemVerPattern: =~"^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(-[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*)?(\\+[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)*)?$"

// IPv4 address
#IPv4Pattern: =~"^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$"

// IPv4 CIDR notation
#CIDRPattern: =~"^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}/(3[0-2]|[12]?\\d)$"

// Port number (1-65535)
#PortPattern: =~"^([1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5])$"

// Port range
#PortRangePattern: =~"^([1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]):([1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5])$"

// Duration format (e.g., "30s", "5m", "1h")
#DurationPattern: =~"^\\d+[smhd]$"

// Memory size (e.g., "512M", "2G")
#MemorySizePattern: =~"^\\d+[KMGT]$"

// Email address
#EmailPattern: =~"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"

// URL with http(s)
#URLPattern: =~"^https?://[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*(/[a-zA-Z0-9._~:/?#\\[\\]@!$&'()*+,;=-]*)?$"

// Environment variable name
#EnvVarPattern: =~"^[A-Z][A-Z0-9_]*$"

// File path (absolute)
#FilePathPattern: =~"^/[a-zA-Z0-9._/-]+$"
```

---

## 3. Stage 2: CUE Type Validators

### 3.1 Core Type Definitions

```cue
package validation

// Hardware resource tier
#ResourceTier: "micro" | "small" | "medium" | "large" | "xlarge"

// Service criticality level
#CriticalityLevel: "critical" | "important" | "normal" | "optional"

// Restart policy
#RestartPolicy: "no" | "always" | "on-failure" | "unless-stopped"

// Network mode
#NetworkMode: "bridge" | "host" | "none" | "container"

// Log driver
#LogDriver: "json-file" | "syslog" | "journald" | "fluentd" | "none"

// Health check configuration
#HealthCheck: {
    test:          [...string] | string
    interval?:     #Duration
    timeout?:      #Duration
    retries?:      int & >=1 & <=10
    start_period?: #Duration
}

// Duration with constraint
#Duration: =~"^[1-9][0-9]*[smh]$"

// Memory limit
#MemoryLimit: =~"^[1-9][0-9]*[KMG]$"

// CPU limit
#CPULimit: float & >=0.1 & <=128.0
```

### 3.2 Service Definition Validator

```cue
#ServiceBase: {
    // Identity
    name:        #HostnamePattern
    description: string & strings.MinRunes(10)
    version:     #SemVerPattern
    
    // Classification
    category:    "core" | "management" | "monitoring" | "utility" | "application"
    criticality: #CriticalityLevel
    
    // Container settings (validated in Layer 2)
    image:     string & =~"^[a-z0-9][a-z0-9._/-]*:[a-zA-Z0-9._-]+$"
    restart:   #RestartPolicy
    
    // Resource constraints
    resources?: #ResourceConstraints
    
    // Health check
    healthcheck?: #HealthCheck
    
    // Dependencies
    depends_on?: [...#HostnamePattern]
}

#ResourceConstraints: {
    memory?: {
        min: #MemoryLimit
        max: #MemoryLimit
    }
    cpu?: {
        min: #CPULimit
        max: #CPULimit
    }
}
```

### 3.3 Constraint Types

```cue
// Numeric range constraint
#Range: {
    min: number
    max: number & >=min
}

// String length constraint
#StringLength: {
    min: int & >=0
    max: int & >=min
}

// List size constraint
#ListSize: {
    min: int & >=0
    max: int & >=min
}

// Enum constraint (closed set)
#Enum: {
    values: [...string]
    default?: string & or(values)
}

// Conditional constraint
#Conditional: {
    if:   {...}
    then: {...}
    else?: {...}
}
```

---

## 4. Stage 3: Semantic Validation

### 4.1 Port Conflict Detection

```cue
package validation

import "list"

// Extract all ports from services for conflict detection
#ExtractPorts: {
    services: {...}
    _ports: [
        for svcName, svc in services
        if svc.ports != _|_
        for port in svc.ports {
            service: svcName
            port:    port
            host:    strings.Split(port, ":")[0]
            container: strings.Split(port, ":")[1]
        }
    ]
    
    // Group by host port for conflict detection
    _hostPorts: {
        for p in _ports {
            (p.host): {
                services: [...string] | *[]
                services: _ + [p.service]
            }
        }
    }
    
    // Find conflicts
    conflicts: [
        for hostPort, data in _hostPorts
        if len(data.services) > 1 {
            port: hostPort
            services: data.services
            error: "Port \(hostPort) is used by multiple services: \(strings.Join(data.services, ", "))"
        }
    ]
    
    valid: len(conflicts) == 0
}
```

### 4.2 Resource Validation

```cue
package validation

// Validate total resource allocation does not exceed host capacity
#ValidateResources: {
    services: {...}
    host: {
        memory_mb: int
        cpu_cores: int
    }
    
    // Calculate totals
    _totalMemory: list.Sum([
        for _, svc in services
        if svc.resources.memory.max != _|_ {
            _parseMemory(svc.resources.memory.max)
        }
    ])
    
    _totalCPU: list.Sum([
        for _, svc in services
        if svc.resources.cpu.max != _|_ {
            svc.resources.cpu.max
        }
    ])
    
    // Validation results
    memoryOk: _totalMemory <= host.memory_mb
    cpuOk:    _totalCPU <= float64(host.cpu_cores)
    
    errors: [
        if !memoryOk {
            "Total memory allocation (\(_totalMemory)MB) exceeds host capacity (\(host.memory_mb)MB)"
        },
        if !cpuOk {
            "Total CPU allocation (\(_totalCPU)) exceeds host cores (\(host.cpu_cores))"
        },
    ]
    
    valid: memoryOk && cpuOk
}
```

### 4.3 Dependency Graph Validation

```cue
package validation

// Validate no circular dependencies exist
#ValidateDependencies: {
    services: {...}
    
    // Build adjacency list
    _graph: {
        for name, svc in services {
            (name): svc.depends_on | *[]
        }
    }
    
    // Detect cycles using DFS (simplified representation)
    _hasCycle: bool | *false
    
    // All services must exist
    _missingDeps: [
        for name, deps in _graph
        for dep in deps
        if services[dep] == _|_ {
            {
                service: name
                missing: dep
                error: "Service '\(name)' depends on undefined service '\(dep)'"
            }
        }
    ]
    
    errors: _missingDeps
    valid: len(_missingDeps) == 0 && !_hasCycle
}
```

---

## 5. Decision Trees

### 5.1 TLS Certificate Decision Tree

```
TLS Certificate Selection
│
├─► Is this production environment?
│   ├─► YES: Use Let's Encrypt (ACME)
│   │   ├─► Domain publicly accessible?
│   │   │   ├─► YES: HTTP-01 challenge
│   │   │   └─► NO: DNS-01 challenge
│   │   └─► Configure auto-renewal (< 30 days)
│   │
│   └─► NO (Dev/Test): 
│       └─► Use self-signed certificates
│           ├─► Generate with mkcert (local dev)
│           └─► Generate with OpenSSL (CI/CD)
│
└─► Wildcard required?
    ├─► YES: DNS-01 challenge mandatory
    └─► NO: HTTP-01 preferred
```

**CUE Implementation:**

```cue
#TLSConfig: {
    environment: "production" | "staging" | "development"
    domain:      #DomainPattern
    wildcard:    bool | *false
    public:      bool | *true
    
    // Decision output
    _provider: {
        if environment == "production" || environment == "staging" {
            "letsencrypt"
        }
        if environment == "development" {
            "selfsigned"
        }
    }
    
    _challenge: {
        if wildcard || !public {
            "dns-01"
        }
        if !wildcard && public {
            "http-01"
        }
    }
    
    result: {
        provider:  _provider
        challenge: _challenge
        renewal:   "30d"
        domains: [
            domain,
            if wildcard { "*.\(domain)" },
        ]
    }
}
```

### 5.2 Compute Tier Decision Tree

```
Resource Tier Selection
│
├─► Evaluate RAM Requirements
│   ├─► < 512MB: micro
│   ├─► 512MB - 2GB: small
│   ├─► 2GB - 8GB: medium
│   ├─► 8GB - 32GB: large
│   └─► > 32GB: xlarge
│
├─► Evaluate CPU Requirements
│   ├─► < 0.5 cores: micro
│   ├─► 0.5 - 2 cores: small
│   ├─► 2 - 4 cores: medium
│   ├─► 4 - 8 cores: large
│   └─► > 8 cores: xlarge
│
└─► Final Tier = MAX(RAM tier, CPU tier)
```

**CUE Implementation:**

```cue
#ComputeTierSelector: {
    memory_mb: int
    cpu_cores: float
    
    _memoryTier: {
        if memory_mb < 512        { "micro" }
        if memory_mb >= 512 && memory_mb < 2048   { "small" }
        if memory_mb >= 2048 && memory_mb < 8192  { "medium" }
        if memory_mb >= 8192 && memory_mb < 32768 { "large" }
        if memory_mb >= 32768     { "xlarge" }
    }
    
    _cpuTier: {
        if cpu_cores < 0.5        { "micro" }
        if cpu_cores >= 0.5 && cpu_cores < 2  { "small" }
        if cpu_cores >= 2 && cpu_cores < 4    { "medium" }
        if cpu_cores >= 4 && cpu_cores < 8    { "large" }
        if cpu_cores >= 8         { "xlarge" }
    }
    
    _tierOrder: {
        micro:  0
        small:  1
        medium: 2
        large:  3
        xlarge: 4
    }
    
    tier: [
        if _tierOrder[_memoryTier] >= _tierOrder[_cpuTier] { _memoryTier },
        if _tierOrder[_cpuTier] > _tierOrder[_memoryTier] { _cpuTier },
    ][0]
}
```

### 5.3 Backup Strategy Decision Tree

```
Backup Strategy Selection
│
├─► Service Category
│   ├─► Database
│   │   ├─► Size < 1GB: Full daily backup
│   │   ├─► Size 1-100GB: Incremental + weekly full
│   │   └─► Size > 100GB: Continuous replication + snapshots
│   │
│   ├─► Stateful Application
│   │   ├─► Config only: Git-backed config
│   │   └─► Data volumes: Volume snapshots
│   │
│   └─► Stateless Service
│       └─► No backup needed (can be recreated)
│
├─► Retention Policy
│   ├─► Critical: 90 days
│   ├─► Important: 30 days
│   ├─► Normal: 14 days
│   └─► Optional: 7 days
│
└─► Backup Location
    ├─► Primary: Local storage
    ├─► Secondary: NAS/Network storage
    └─► Tertiary: Cloud (S3-compatible)
```

**CUE Implementation:**

```cue
#BackupConfig: {
    service: {
        category:    "database" | "stateful" | "stateless"
        criticality: #CriticalityLevel
        data_size:   string  // e.g., "500M", "10G", "500G"
    }
    
    _dataSizeGB: _parseSize(service.data_size)
    
    _retentionDays: {
        if service.criticality == "critical"  { 90 }
        if service.criticality == "important" { 30 }
        if service.criticality == "normal"    { 14 }
        if service.criticality == "optional"  { 7 }
    }
    
    result: {
        if service.category == "stateless" {
            enabled: false
            reason:  "Stateless service can be recreated"
        }
        
        if service.category == "database" {
            enabled:   true
            type:      [
                if _dataSizeGB < 1   { "full-daily" },
                if _dataSizeGB >= 1 && _dataSizeGB < 100 { "incremental-daily" },
                if _dataSizeGB >= 100 { "continuous-replication" },
            ][0]
            retention: "\(_retentionDays)d"
            schedule:  "0 2 * * *"
        }
        
        if service.category == "stateful" {
            enabled:   true
            type:      "volume-snapshot"
            retention: "\(_retentionDays)d"
            schedule:  "0 3 * * *"
        }
    }
}
```

---

## 6. CLI Validation Commands

### 6.1 Command Interface

```bash
# Validate all aspects
stackkit validate [STACKKIT_PATH]

# Validate specific stage
stackkit validate --stage input|schema|semantic|platform [STACKKIT_PATH]

# Validate with verbose output
stackkit validate --verbose [STACKKIT_PATH]

# Validate and show decision tree results
stackkit validate --show-decisions [STACKKIT_PATH]

# Validate against specific variant
stackkit validate --variant minimal|standard|full [STACKKIT_PATH]

# Validate and generate report
stackkit validate --report json|yaml|markdown [STACKKIT_PATH]
```

### 6.2 CLI Implementation Guidance

```go
package validation

import (
    "github.com/spf13/cobra"
)

// ValidateCmd represents the validate command
var ValidateCmd = &cobra.Command{
    Use:   "validate [path]",
    Short: "Validate a StackKit configuration",
    Long: `Validates StackKit configuration through multiple stages:
  - Stage 1: Input validation (formats, types)
  - Stage 2: CUE schema validation (structure, constraints)
  - Stage 3: Semantic validation (cross-field rules)
  - Stage 4: Platform validation (delegated to platform layer)`,
    RunE: runValidate,
}

// Validation stages
type ValidationStage string

const (
    StageInput    ValidationStage = "input"
    StageSchema   ValidationStage = "schema"
    StageSemantic ValidationStage = "semantic"
    StagePlatform ValidationStage = "platform"
)

// ValidationResult contains results from all stages
type ValidationResult struct {
    Stage    ValidationStage `json:"stage"`
    Valid    bool            `json:"valid"`
    Errors   []ValidationError `json:"errors,omitempty"`
    Warnings []string        `json:"warnings,omitempty"`
    Duration time.Duration   `json:"duration"`
}

// ValidationError represents a single validation error
type ValidationError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Field   string `json:"field,omitempty"`
    Value   any    `json:"value,omitempty"`
    Hint    string `json:"hint,omitempty"`
}
```

---

## 7. Unifier Integration

The Unifier module combines validation outputs into a complete, validated configuration:

```cue
package unifier

import (
    "stackkits.io/validation"
    "stackkits.io/defaults"
)

#Unifier: {
    // Inputs
    input:    {...}
    defaults: defaults.#Defaults
    variant:  "minimal" | "standard" | "full"
    
    // Stage 1: Input validation
    _inputValidation: validation.#ValidateInput & {
        data: input
    }
    
    // Stage 2: Apply defaults
    _withDefaults: defaults & input
    
    // Stage 3: Schema validation
    _schemaValidation: validation.#ValidateSchema & {
        data: _withDefaults
    }
    
    // Stage 4: Semantic validation
    _semanticValidation: validation.#ValidateSemantic & {
        data: _withDefaults
    }
    
    // Combine all errors
    errors: _inputValidation.errors + 
            _schemaValidation.errors + 
            _semanticValidation.errors
    
    valid: len(errors) == 0
    
    // Output unified configuration
    config: {
        if valid {
            _withDefaults
        }
    }
}
```

---

## 8. Error Catalog

All validation errors use structured error codes for consistency:

| Code | Category | Description | Example Message |
|------|----------|-------------|-----------------|
| `VAL-INP-001` | Input | Missing required field | "Required field 'name' is missing" |
| `VAL-INP-002` | Input | Invalid format | "Field 'version' must match semantic versioning (x.y.z)" |
| `VAL-INP-003` | Input | Invalid type | "Field 'ports' must be an array, got string" |
| `VAL-INP-004` | Input | Value out of range | "Port must be between 1 and 65535" |
| `VAL-INP-005` | Input | Invalid pattern | "Field 'domain' is not a valid domain name" |
| `VAL-SCH-001` | Schema | Unknown field | "Unknown field 'foobar' in service definition" |
| `VAL-SCH-002` | Schema | Constraint violation | "Memory limit must be at least 64M" |
| `VAL-SCH-003` | Schema | Type mismatch | "Expected string, got integer for field 'image'" |
| `VAL-SCH-004` | Schema | Missing nested field | "Service 'traefik' missing required field 'ports'" |
| `VAL-SEM-001` | Semantic | Port conflict | "Port 8080 used by both 'traefik' and 'nginx'" |
| `VAL-SEM-002` | Semantic | Circular dependency | "Circular dependency: a → b → c → a" |
| `VAL-SEM-003` | Semantic | Missing dependency | "Service 'app' depends on undefined 'redis'" |
| `VAL-SEM-004` | Semantic | Resource exceeded | "Total memory exceeds host capacity" |
| `VAL-SEM-005` | Semantic | Incompatible settings | "Network mode 'host' incompatible with port mappings" |
| `VAL-PLT-001` | Platform | Container error | "Image not found: myapp:latest" |
| `VAL-PLT-002` | Platform | Network error | "Network 'frontend' does not exist" |
| `VAL-PLT-003` | Platform | Volume error | "Volume mount path is not absolute" |
| `VAL-PLT-004` | Platform | Provider error | "Tofu provider not configured" |

### 8.1 Error Response Format

```json
{
  "valid": false,
  "errors": [
    {
      "code": "VAL-SEM-001",
      "stage": "semantic",
      "severity": "error",
      "message": "Port 8080 is used by multiple services",
      "field": "services.traefik.ports[0]",
      "context": {
        "port": 8080,
        "services": ["traefik", "nginx"]
      },
      "hint": "Change the host port for one of the conflicting services",
      "docs": "https://docs.stackkits.io/validation/port-conflicts"
    }
  ],
  "warnings": [
    {
      "code": "VAL-WRN-001",
      "message": "Service 'redis' has no health check defined",
      "hint": "Consider adding a health check for better reliability"
    }
  ]
}
```

---

## 9. Custom Validator Extension

StackKits can extend the base validation with custom rules:

```cue
package myvalidation

import "stackkits.io/validation"

// Custom validator that extends base
#MyValidator: validation.#BaseValidator & {
    // Add custom rules
    rules: validation.#BaseRules + {
        // My custom rule
        "custom-memory-ratio": {
            description: "Memory max must be at least 2x memory min"
            check: {
                for name, svc in services
                if svc.resources.memory != _|_ {
                    _ratio: _parseMemory(svc.resources.memory.max) / _parseMemory(svc.resources.memory.min)
                    valid: _ratio >= 2
                    error: "Service '\(name)' memory ratio is \(_ratio), must be >= 2"
                }
            }
        }
    }
}
```

---

## References

- **Layer 2 Extension:** See [Docker Validation](../layer-2-platform/docker/VALIDATION.md) for Docker-specific rules
- **Layer 3 Usage:** See individual StackKit validation documents for service-specific rules
- **CUE Documentation:** https://cuelang.org/docs/
- **OpenTofu Variables:** Validated in Layer 2 platform documents
