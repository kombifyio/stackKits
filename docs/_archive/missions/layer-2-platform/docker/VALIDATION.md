# Platform Layer: Docker Validation

**Scope:** This document defines Docker-specific validation rules that extend the Foundation Layer. These rules apply to all StackKits using Docker as their container runtime.

---

## 1. Docker Validation Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DOCKER VALIDATION FLOW                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [Layer 1: Foundation Validation]                                        │
│       │                                                                  │
│       ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    DOCKER VALIDATION STAGES                      │    │
│  ├─────────────────────────────────────────────────────────────────┤    │
│  │                                                                  │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │    │
│  │  │ Container   │  │ Network     │  │ Volume                  │  │    │
│  │  │ Validation  │  │ Validation  │  │ Validation              │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │    │
│  │        │                │                     │                  │    │
│  │        ▼                ▼                     ▼                  │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │    │
│  │  │ Image       │  │ Port        │  │ Mount                   │  │    │
│  │  │ Validation  │  │ Validation  │  │ Validation              │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │    │
│  │                                                                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│       │                                                                  │
│       ▼                                                                  │
│  [OpenTofu Variable Validation]                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Container Validation

### 2.1 Image Reference Validation

```cue
package docker

// Docker image reference pattern
#ImageReference: =~"^([a-z0-9][a-z0-9._-]*/)?[a-z0-9][a-z0-9._/-]*:[a-zA-Z0-9._-]+(@sha256:[a-f0-9]{64})?$"

// Image validation
#ValidateImage: {
    image:   string
    tag:     string | *"latest"
    digest?: string
    
    // Full reference
    _fullRef: {
        if digest != _|_ {
            "\(image):\(tag)@\(digest)"
        }
        if digest == _|_ {
            "\(image):\(tag)"
        }
    }
    
    // Validation rules
    _rules: {
        // No latest in production
        noLatestInProd: {
            if tag == "latest" {
                warning: "Using 'latest' tag is not recommended for production"
            }
        }
        
        // Prefer digest for immutability
        preferDigest: {
            if digest == _|_ {
                info: "Consider using image digest for immutable deployments"
            }
        }
        
        // Valid registry
        validRegistry: {
            _parts: strings.Split(image, "/")
            _hasRegistry: len(_parts) >= 2 && strings.Contains(_parts[0], ".")
        }
    }
    
    reference: _fullRef
}

// Common registries
#Registry: {
    dockerhub:  "docker.io"
    ghcr:       "ghcr.io"
    gcr:        "gcr.io"
    ecr:        "*.dkr.ecr.*.amazonaws.com"
    acr:        "*.azurecr.io"
    quay:       "quay.io"
    lscr:       "lscr.io"
}
```

### 2.2 Container Name Validation

```cue
// Container name (RFC 1123 + Docker specific)
#ContainerName: =~"^[a-zA-Z0-9][a-zA-Z0-9_.-]*$" & strings.MinRunes(1) & strings.MaxRunes(64)

// Validate container doesn't conflict with existing
#ValidateContainerName: {
    name:     #ContainerName
    existing: [...string]
    
    _conflict: list.Contains(existing, name)
    
    valid: !_conflict
    error: {
        if _conflict {
            "Container name '\(name)' already exists"
        }
    }
}
```

### 2.3 Restart Policy Validation

```cue
#RestartPolicy: "no" | "always" | "on-failure" | "unless-stopped"

#ValidateRestartPolicy: {
    policy:      #RestartPolicy
    criticality: #CriticalityLevel
    
    // Critical services should auto-restart
    _recommendation: {
        if criticality == "critical" && policy == "no" {
            error: "Critical services MUST have restart policy 'always' or 'unless-stopped'"
        }
        if criticality == "critical" && policy == "on-failure" {
            warning: "Critical services SHOULD use 'always' instead of 'on-failure'"
        }
    }
    
    valid: _recommendation.error == _|_
    warnings: [
        if _recommendation.warning != _|_ {
            _recommendation.warning
        },
    ]
}
```

---

## 3. Network Validation

### 3.1 Network Mode Validation

```cue
#NetworkMode: "bridge" | "host" | "none" | "container" | "overlay"

#ValidateNetworkMode: {
    mode:  #NetworkMode
    ports: [...string]
    
    // Host mode conflicts with port mappings
    _hostModeConflict: mode == "host" && len(ports) > 0
    
    // None mode should have no network requirements
    _noneModeWarning: mode == "none" && len(ports) > 0
    
    errors: [
        if _hostModeConflict {
            code: "VAL-PLT-NET-001"
            message: "Network mode 'host' is incompatible with port mappings"
            hint: "Remove port mappings when using host network mode"
        },
    ]
    
    warnings: [
        if _noneModeWarning {
            code: "VAL-PLT-NET-002"
            message: "Network mode 'none' with port mappings will have no effect"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 3.2 Network Subnet Validation

```cue
// Docker network subnet validation
#ValidateSubnet: {
    subnet:   #CIDRPattern
    existing: [...string]
    
    // Parse CIDR
    _parts: strings.Split(subnet, "/")
    _ip:    _parts[0]
    _mask:  strconv.Atoi(_parts[1])
    
    // Check for overlaps (simplified)
    _overlaps: [
        for existing_subnet in existing
        if _checkOverlap(subnet, existing_subnet) {
            existing_subnet
        }
    ]
    
    valid: len(_overlaps) == 0
    error: {
        if len(_overlaps) > 0 {
            "Subnet \(subnet) overlaps with existing: \(strings.Join(_overlaps, ", "))"
        }
    }
}

// Default Docker networks (reserved)
#ReservedNetworks: {
    bridge:   "172.17.0.0/16"
    host:     "host"
    none:     "none"
}

// Recommended homelab subnets
#RecommendedSubnets: {
    frontend:   "172.20.0.0/24"
    backend:    "172.21.0.0/24"
    database:   "172.22.0.0/24"
    monitoring: "172.23.0.0/24"
}
```

### 3.3 Port Mapping Validation

```cue
#ValidatePortMapping: {
    mapping:  string  // "8080:80" or "8080:80/tcp"
    existing: [...string]
    
    // Parse mapping
    _parts: strings.Split(mapping, ":")
    _hostPart: _parts[0]
    _containerPart: _parts[1]
    
    // Extract protocol
    _containerParts: strings.Split(_containerPart, "/")
    _containerPort: strconv.Atoi(_containerParts[0])
    _protocol: _containerParts[1] | *"tcp"
    
    // Host port may include IP
    _hostParts: strings.Split(_hostPart, ":")
    _hostPort: strconv.Atoi(_hostParts[len(_hostParts)-1])
    _hostIP: {
        if len(_hostParts) > 1 {
            _hostParts[0]
        }
    }
    
    // Validation
    _validHostPort:      _hostPort >= 1 && _hostPort <= 65535
    _validContainerPort: _containerPort >= 1 && _containerPort <= 65535
    _validProtocol:      _protocol == "tcp" || _protocol == "udp"
    
    // Check privileged ports
    _privilegedPort: _hostPort < 1024
    
    // Check conflicts
    _conflict: list.Contains(existing, "\(_hostPort)/\(_protocol)")
    
    errors: [
        if !_validHostPort {
            code: "VAL-PLT-PORT-001"
            message: "Invalid host port: \(_hostPort)"
        },
        if !_validContainerPort {
            code: "VAL-PLT-PORT-002"
            message: "Invalid container port: \(_containerPort)"
        },
        if _conflict {
            code: "VAL-PLT-PORT-003"
            message: "Port \(_hostPort)/\(_protocol) is already in use"
        },
    ]
    
    warnings: [
        if _privilegedPort {
            code: "VAL-PLT-PORT-004"
            message: "Port \(_hostPort) is a privileged port (<1024), requires root"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 4. Volume Validation

### 4.1 Volume Mount Validation

```cue
#VolumeType: "volume" | "bind" | "tmpfs" | "npipe"

#ValidateVolumeMount: {
    type:     #VolumeType
    source:   string
    target:   string
    readOnly: bool | *false
    
    // Bind mount validation
    _bindValidation: {
        if type == "bind" {
            // Source must be absolute path
            absolutePath: strings.HasPrefix(source, "/")
            
            // Check dangerous paths
            dangerousPaths: ["/", "/etc", "/usr", "/bin", "/sbin", "/var", "/root"]
            isDangerous: list.Contains(dangerousPaths, source) && !readOnly
        }
    }
    
    // Target validation
    _targetValidation: {
        absolutePath: strings.HasPrefix(target, "/")
        noTrailingSlash: !strings.HasSuffix(target, "/") || target == "/"
    }
    
    // Volume name validation (for named volumes)
    _volumeValidation: {
        if type == "volume" {
            validName: source =~ "^[a-zA-Z0-9][a-zA-Z0-9_.-]*$"
        }
    }
    
    errors: [
        if type == "bind" && !_bindValidation.absolutePath {
            code: "VAL-PLT-VOL-001"
            message: "Bind mount source must be absolute path: \(source)"
        },
        if type == "bind" && _bindValidation.isDangerous {
            code: "VAL-PLT-VOL-002"
            message: "Dangerous bind mount to system path: \(source) (use readOnly: true)"
        },
        if !_targetValidation.absolutePath {
            code: "VAL-PLT-VOL-003"
            message: "Mount target must be absolute path: \(target)"
        },
        if type == "volume" && !_volumeValidation.validName {
            code: "VAL-PLT-VOL-004"
            message: "Invalid volume name: \(source)"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 4.2 Volume Driver Validation

```cue
#VolumeDriver: "local" | "nfs" | "cifs" | "overlay" | "devicemapper"

#ValidateVolumeDriver: {
    driver:  #VolumeDriver
    options: {...}
    
    // Local driver options
    _localValidation: {
        if driver == "local" {
            validOptions: ["type", "o", "device"]
            invalidKeys: [
                for k, _ in options
                if !list.Contains(validOptions, k) {
                    k
                }
            ]
        }
    }
    
    // NFS driver validation
    _nfsValidation: {
        if driver == "nfs" {
            requiredOptions: ["share", "addr"]
            missingKeys: [
                for opt in requiredOptions
                if options[opt] == _|_ {
                    opt
                }
            ]
        }
    }
    
    errors: [
        if driver == "local" && len(_localValidation.invalidKeys) > 0 {
            code: "VAL-PLT-VOL-005"
            message: "Invalid local driver options: \(strings.Join(_localValidation.invalidKeys, ", "))"
        },
        if driver == "nfs" && len(_nfsValidation.missingKeys) > 0 {
            code: "VAL-PLT-VOL-006"
            message: "Missing required NFS options: \(strings.Join(_nfsValidation.missingKeys, ", "))"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 5. Resource Constraints Validation

### 5.1 Memory Limits

```cue
#ValidateMemoryLimits: {
    memoryMin: string  // e.g., "128M"
    memoryMax: string  // e.g., "512M"
    hostMemory: int    // Host memory in MB
    
    _minMB: _parseMemory(memoryMin)
    _maxMB: _parseMemory(memoryMax)
    
    // Docker minimum memory
    _dockerMinimum: 6  // 6MB is Docker's minimum
    
    errors: [
        if _minMB < _dockerMinimum {
            code: "VAL-PLT-RES-001"
            message: "Memory minimum \(memoryMin) is below Docker minimum (6MB)"
        },
        if _minMB > _maxMB {
            code: "VAL-PLT-RES-002"
            message: "Memory minimum (\(memoryMin)) exceeds maximum (\(memoryMax))"
        },
        if _maxMB > hostMemory {
            code: "VAL-PLT-RES-003"
            message: "Memory maximum (\(memoryMax)) exceeds host memory (\(hostMemory)MB)"
        },
    ]
    
    // Memory ratio recommendation
    warnings: [
        if _maxMB < _minMB * 2 {
            code: "VAL-PLT-RES-004"
            message: "Recommended: memory_max should be at least 2x memory_min for burst capacity"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 5.2 CPU Limits

```cue
#ValidateCPULimits: {
    cpuMin:    float
    cpuMax:    float
    hostCores: int
    
    errors: [
        if cpuMin < 0.01 {
            code: "VAL-PLT-RES-005"
            message: "CPU minimum must be at least 0.01 cores"
        },
        if cpuMin > cpuMax {
            code: "VAL-PLT-RES-006"
            message: "CPU minimum (\(cpuMin)) exceeds maximum (\(cpuMax))"
        },
        if cpuMax > float(hostCores) {
            code: "VAL-PLT-RES-007"
            message: "CPU maximum (\(cpuMax)) exceeds host cores (\(hostCores))"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 6. Health Check Validation

```cue
#ValidateHealthCheck: {
    type:        "http" | "tcp" | "cmd" | "none"
    test?:       [...string] | string
    endpoint?:   string
    interval:    string
    timeout:     string
    retries:     int
    startPeriod: string
    
    _intervalSec: _parseDuration(interval)
    _timeoutSec:  _parseDuration(timeout)
    _startSec:    _parseDuration(startPeriod)
    
    errors: [
        if _timeoutSec >= _intervalSec {
            code: "VAL-PLT-HC-001"
            message: "Health check timeout (\(timeout)) must be less than interval (\(interval))"
        },
        if retries < 1 || retries > 10 {
            code: "VAL-PLT-HC-002"
            message: "Health check retries must be between 1 and 10"
        },
        if type == "http" && endpoint == _|_ {
            code: "VAL-PLT-HC-003"
            message: "HTTP health check requires 'endpoint' field"
        },
        if type == "cmd" && test == _|_ {
            code: "VAL-PLT-HC-004"
            message: "CMD health check requires 'test' field"
        },
    ]
    
    // Format for Docker
    dockerHealthCheck: {
        if type == "http" {
            test: ["CMD", "curl", "-f", endpoint, "||", "exit", "1"]
        }
        if type == "tcp" {
            test: ["CMD", "nc", "-z", "localhost", "\(_extractPort(endpoint))"]
        }
        if type == "cmd" {
            test: test
        }
        if type == "none" {
            test: ["NONE"]
        }
        interval:     interval
        timeout:      timeout
        retries:      retries
        start_period: startPeriod
    }
    
    valid: len(errors) == 0
}
```

---

## 7. OpenTofu Variable Validation

### 7.1 Docker Provider Variables

```hcl
# docker_variables.tf

variable "docker_host" {
  description = "Docker daemon socket"
  type        = string
  default     = "unix:///var/run/docker.sock"
  
  validation {
    condition = (
      startswith(var.docker_host, "unix://") ||
      startswith(var.docker_host, "tcp://") ||
      startswith(var.docker_host, "ssh://")
    )
    error_message = "docker_host must start with unix://, tcp://, or ssh://"
  }
}

variable "docker_cert_path" {
  description = "Path to Docker TLS certificates (for tcp:// connections)"
  type        = string
  default     = null
  
  validation {
    condition = (
      var.docker_cert_path == null ||
      can(regex("^/", var.docker_cert_path))
    )
    error_message = "docker_cert_path must be an absolute path"
  }
}

variable "docker_registry_auth" {
  description = "Docker registry authentication"
  type = map(object({
    username = string
    password = string
  }))
  default   = {}
  sensitive = true
}
```

### 7.2 Container Resource Variables

```hcl
# container_variables.tf

variable "container_memory_limit" {
  description = "Container memory limit"
  type        = string
  default     = "512M"
  
  validation {
    condition     = can(regex("^[1-9][0-9]*[KMG]$", var.container_memory_limit))
    error_message = "container_memory_limit must be in format like 512M, 2G"
  }
}

variable "container_cpu_limit" {
  description = "Container CPU limit (number of cores)"
  type        = number
  default     = 1.0
  
  validation {
    condition     = var.container_cpu_limit >= 0.1 && var.container_cpu_limit <= 128
    error_message = "container_cpu_limit must be between 0.1 and 128 cores"
  }
}

variable "container_restart_policy" {
  description = "Container restart policy"
  type        = string
  default     = "unless-stopped"
  
  validation {
    condition = contains(
      ["no", "always", "on-failure", "unless-stopped"],
      var.container_restart_policy
    )
    error_message = "container_restart_policy must be one of: no, always, on-failure, unless-stopped"
  }
}
```

### 7.3 Network Variables

```hcl
# network_variables.tf

variable "network_driver" {
  description = "Docker network driver"
  type        = string
  default     = "bridge"
  
  validation {
    condition     = contains(["bridge", "overlay", "host", "none", "macvlan"], var.network_driver)
    error_message = "network_driver must be one of: bridge, overlay, host, none, macvlan"
  }
}

variable "network_subnet" {
  description = "Network subnet in CIDR notation"
  type        = string
  default     = "172.20.0.0/24"
  
  validation {
    condition     = can(cidrsubnet(var.network_subnet, 0, 0))
    error_message = "network_subnet must be a valid CIDR block"
  }
}

variable "network_gateway" {
  description = "Network gateway IP address"
  type        = string
  default     = null
  
  validation {
    condition = (
      var.network_gateway == null ||
      can(regex("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$", var.network_gateway))
    )
    error_message = "network_gateway must be a valid IPv4 address"
  }
}
```

---

## 8. Docker Compose Validation

### 8.1 Compose File Structure

```cue
#DockerCompose: {
    version?: string
    name?:    string
    
    services: {
        [serviceName=_]: #ComposeService
    }
    
    networks?: {
        [networkName=_]: #ComposeNetwork | null
    }
    
    volumes?: {
        [volumeName=_]: #ComposeVolume | null
    }
    
    configs?: {
        [configName=_]: #ComposeConfig
    }
    
    secrets?: {
        [secretName=_]: #ComposeSecret
    }
}

#ComposeService: {
    image?:          string
    build?:          string | #ComposeBuild
    container_name?: #ContainerName
    command?:        string | [...string]
    entrypoint?:     string | [...string]
    environment?:    {...} | [...string]
    env_file?:       string | [...string]
    ports?:          [...string]
    expose?:         [...(int | string)]
    volumes?:        [...string]
    networks?:       [...string] | {[string]: {...}}
    depends_on?:     [...string] | {[string]: {...}}
    restart?:        #RestartPolicy
    healthcheck?:    #ComposeHealthCheck
    deploy?:         #ComposeDeploy
    labels?:         {...} | [...string]
    ...
}

#ComposeBuild: {
    context:    string
    dockerfile?: string
    args?:      {...}
    target?:    string
    ...
}

#ComposeNetwork: {
    driver?:     string
    driver_opts?: {...}
    internal?:   bool
    external?:   bool | {name: string}
    ipam?:       #ComposeIPAM
    labels?:     {...}
    ...
}

#ComposeVolume: {
    driver?:     string
    driver_opts?: {...}
    external?:   bool | {name: string}
    labels?:     {...}
    ...
}

#ComposeHealthCheck: {
    test:          [...string] | string
    interval?:     string
    timeout?:      string
    retries?:      int
    start_period?: string
    disable?:      bool
}

#ComposeDeploy: {
    replicas?:   int
    resources?:  #ComposeResources
    restart_policy?: {...}
    placement?:  {...}
    ...
}

#ComposeResources: {
    limits?: {
        cpus?:   string
        memory?: string
    }
    reservations?: {
        cpus?:   string
        memory?: string
    }
}
```

---

## 9. Error Catalog (Docker-Specific)

| Code | Category | Description |
|------|----------|-------------|
| `VAL-PLT-IMG-001` | Image | Invalid image reference format |
| `VAL-PLT-IMG-002` | Image | Image not found in registry |
| `VAL-PLT-IMG-003` | Image | Using 'latest' tag (warning) |
| `VAL-PLT-NET-001` | Network | Host mode with port mappings |
| `VAL-PLT-NET-002` | Network | None mode with port mappings |
| `VAL-PLT-NET-003` | Network | Subnet overlap detected |
| `VAL-PLT-PORT-001` | Port | Invalid host port |
| `VAL-PLT-PORT-002` | Port | Invalid container port |
| `VAL-PLT-PORT-003` | Port | Port already in use |
| `VAL-PLT-PORT-004` | Port | Privileged port (warning) |
| `VAL-PLT-VOL-001` | Volume | Bind mount not absolute |
| `VAL-PLT-VOL-002` | Volume | Dangerous system path |
| `VAL-PLT-VOL-003` | Volume | Target not absolute |
| `VAL-PLT-VOL-004` | Volume | Invalid volume name |
| `VAL-PLT-VOL-005` | Volume | Invalid driver options |
| `VAL-PLT-VOL-006` | Volume | Missing NFS options |
| `VAL-PLT-RES-001` | Resource | Memory below Docker minimum |
| `VAL-PLT-RES-002` | Resource | Memory min > max |
| `VAL-PLT-RES-003` | Resource | Memory exceeds host |
| `VAL-PLT-RES-004` | Resource | Memory ratio warning |
| `VAL-PLT-RES-005` | Resource | CPU minimum too low |
| `VAL-PLT-RES-006` | Resource | CPU min > max |
| `VAL-PLT-RES-007` | Resource | CPU exceeds host cores |
| `VAL-PLT-HC-001` | HealthCheck | Timeout >= interval |
| `VAL-PLT-HC-002` | HealthCheck | Invalid retry count |
| `VAL-PLT-HC-003` | HealthCheck | HTTP without endpoint |
| `VAL-PLT-HC-004` | HealthCheck | CMD without test |

---

## References

- **Foundation Layer:** [Base Validation](../layer-1-foundation/base/VALIDATION.md) - Core validation patterns
- **Layer 3 Usage:** See StackKit-specific validation for service-level rules
- **Docker Documentation:** https://docs.docker.com/
- **Kreuzwerker Docker Provider:** https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
