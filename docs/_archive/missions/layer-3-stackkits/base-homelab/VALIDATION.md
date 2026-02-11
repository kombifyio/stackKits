# StackKit Layer: base-homelab Validation

**Scope:** This document defines service-specific validation rules for the base-homelab StackKit. It extends Layer 1 (Foundation) and Layer 2 (Docker) validation with homelab-specific constraints.

---

## 1. Service Validation Overview

### 1.1 Defined Services

| Service | Category | Criticality | Required Ports | Dependencies |
|---------|----------|-------------|----------------|--------------|
| Traefik | Core | Critical | 80, 443, 8080 | None |
| Dokploy | Management | Important | 3000 | Traefik |
| Coolify | Management | Important | 3001 | Traefik |
| Uptime Kuma | Monitoring | Important | 3002 | Traefik |
| Beszel | Monitoring | Normal | 3003 | Traefik |
| Dozzle | Utility | Optional | 3004 | Traefik, Docker Socket |
| Dockge | Management | Normal | 3005 | Traefik, Docker Socket |
| Portainer | Management | Optional | 9000, 9443 | Traefik, Docker Socket |
| Netdata | Monitoring | Optional | 19999 | Traefik |

### 1.2 Service Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SERVICE DEPENDENCY GRAPH                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│                         ┌──────────────┐                                 │
│                         │   TRAEFIK    │ (Reverse Proxy)                 │
│                         │   CRITICAL   │                                 │
│                         └──────┬───────┘                                 │
│                                │                                         │
│            ┌───────────────────┼───────────────────┐                    │
│            │                   │                   │                     │
│            ▼                   ▼                   ▼                     │
│    ┌───────────────┐   ┌───────────────┐   ┌───────────────┐           │
│    │   DOKPLOY     │   │   COOLIFY     │   │ UPTIME KUMA   │           │
│    │   IMPORTANT   │   │   IMPORTANT   │   │   IMPORTANT   │           │
│    └───────────────┘   └───────────────┘   └───────────────┘           │
│                                                                          │
│            ┌───────────────────┴───────────────────┐                    │
│            │                                       │                     │
│            ▼                                       ▼                     │
│    ┌───────────────┐                       ┌───────────────┐           │
│    │    BESZEL     │                       │    DOZZLE     │           │
│    │    NORMAL     │                       │   OPTIONAL    │           │
│    └───────────────┘                       └───────────────┘           │
│                                                                          │
│    ┌───────────────┐   ┌───────────────┐   ┌───────────────┐           │
│    │    DOCKGE     │   │   PORTAINER   │   │    NETDATA    │           │
│    │    NORMAL     │   │   OPTIONAL    │   │   OPTIONAL    │           │
│    └───────────────┘   └───────────────┘   └───────────────┘           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Service-Specific Validation

### 2.1 Traefik Validation

```cue
#TraefikValidation: {
    service: {...}
    
    // Required ports
    _requiredPorts: [80, 443]
    _optionalPorts: [8080]  // Dashboard
    
    _hasPorts: [
        for port in _requiredPorts
        if !_hasPort(service.ports, port) {
            port
        }
    ]
    
    // Required volumes
    _requiredVolumes: [
        "/var/run/docker.sock:/var/run/docker.sock:ro",
        // letsencrypt or acme.json
    ]
    
    // Required labels for self-discovery
    _requiredLabels: [
        "traefik.enable=true",
    ]
    
    // Entrypoints validation
    _validEntrypoints: {
        web:       {address: ":80"}
        websecure: {address: ":443"}
        dashboard: {address: ":8080"}
    }
    
    errors: [
        if len(_hasPorts) > 0 {
            code: "VAL-SVC-TRF-001"
            message: "Traefik missing required ports: \(strings.Join([for p in _hasPorts {"\(p)"}], ", "))"
        },
        if service.restart != "always" && service.restart != "unless-stopped" {
            code: "VAL-SVC-TRF-002"
            message: "Critical service Traefik must have restart=always or unless-stopped"
        },
    ]
    
    warnings: [
        if !_hasVolume(service.volumes, "/var/run/docker.sock") {
            code: "VAL-SVC-TRF-003"
            message: "Traefik should have Docker socket mounted for container discovery"
        },
        if !_hasLabel(service.labels, "traefik.enable") {
            code: "VAL-SVC-TRF-004"
            message: "Traefik should have traefik.enable label for self-registration"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 2.2 Dokploy/Coolify Validation (PaaS)

```cue
#PaaSValidation: {
    service: {...}
    type:    "dokploy" | "coolify"
    
    // Mutual exclusivity check
    otherPaaSEnabled: bool
    
    // Required volumes for PaaS
    _requiredVolumes: [
        "/var/run/docker.sock:/var/run/docker.sock",
    ]
    
    // Port ranges
    _portRange: {
        dokploy: 3000
        coolify: 3001
    }
    
    errors: [
        if !_hasVolume(service.volumes, "/var/run/docker.sock") {
            code: "VAL-SVC-PAAS-001"
            message: "\(type) requires Docker socket access"
        },
        if otherPaaSEnabled {
            code: "VAL-SVC-PAAS-002"
            message: "Only one PaaS platform (Dokploy or Coolify) should be enabled"
            hint: "Choose either Dokploy or Coolify, not both"
        },
    ]
    
    warnings: [
        if service.resources.memory.max == _|_ {
            code: "VAL-SVC-PAAS-003"
            message: "PaaS platforms can be memory-intensive, consider setting memory limits"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 2.3 Uptime Kuma Validation

```cue
#UptimeKumaValidation: {
    service: {...}
    
    // Data persistence
    _dataVolume: _findVolume(service.volumes, "/app/data")
    
    errors: [
        if _dataVolume == _|_ {
            code: "VAL-SVC-UK-001"
            message: "Uptime Kuma requires persistent volume for /app/data"
            hint: "Add volume: uptime-kuma-data:/app/data"
        },
    ]
    
    warnings: [
        if service.healthcheck == _|_ {
            code: "VAL-SVC-UK-002"
            message: "Uptime Kuma should have health check for self-monitoring"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 2.4 Docker Socket Services Validation

```cue
#DockerSocketValidation: {
    service: {...}
    name:    string
    
    // Services requiring Docker socket
    _socketServices: ["dozzle", "dockge", "portainer", "dokploy", "coolify", "traefik"]
    
    _requiresSocket: list.Contains(_socketServices, name)
    _hasSocket: _hasVolume(service.volumes, "/var/run/docker.sock")
    
    // Security considerations
    _socketReadOnly: _hasVolume(service.volumes, "/var/run/docker.sock:ro")
    
    errors: [
        if _requiresSocket && !_hasSocket {
            code: "VAL-SVC-SOCK-001"
            message: "Service \(name) requires Docker socket access"
        },
    ]
    
    warnings: [
        if _hasSocket && !_socketReadOnly {
            code: "VAL-SVC-SOCK-002"
            message: "Docker socket should be mounted read-only when possible"
            hint: "Use /var/run/docker.sock:/var/run/docker.sock:ro"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 3. Variant Validation

### 3.1 Variant Definitions

```cue
#Variant: "minimal" | "standard" | "full"

#VariantConfig: {
    variant: #Variant
    
    // Service inclusion by variant
    _serviceMatrix: {
        minimal: {
            traefik:     true
            dokploy:     false  // OR coolify
            coolify:     true
            uptime_kuma: false
            beszel:      false
            dozzle:      false
            dockge:      false
            portainer:   false
            netdata:     false
        }
        standard: {
            traefik:     true
            dokploy:     true   // OR coolify
            coolify:     false
            uptime_kuma: true
            beszel:      true
            dozzle:      true
            dockge:      false
            portainer:   false
            netdata:     false
        }
        full: {
            traefik:     true
            dokploy:     true   // OR coolify
            coolify:     false
            uptime_kuma: true
            beszel:      true
            dozzle:      true
            dockge:      true
            portainer:   true
            netdata:     true
        }
    }
    
    requiredServices: _serviceMatrix[variant]
}
```

### 3.2 Variant Validation Rules

```cue
#ValidateVariant: {
    variant:  #Variant
    services: {...}
    
    _required: #VariantConfig & {variant: variant}
    
    // Check all required services are present
    _missingServices: [
        for name, required in _required.requiredServices
        if required && services[name] == _|_ {
            name
        }
    ]
    
    // Check no forbidden services (for minimal)
    _extraServices: [
        for name, _ in services
        if !_required.requiredServices[name] {
            name
        }
    ]
    
    errors: [
        if len(_missingServices) > 0 {
            code: "VAL-VAR-001"
            message: "Variant '\(variant)' missing required services: \(strings.Join(_missingServices, ", "))"
        },
    ]
    
    warnings: [
        if variant == "minimal" && len(_extraServices) > 0 {
            code: "VAL-VAR-002"
            message: "Variant 'minimal' has extra services: \(strings.Join(_extraServices, ", "))"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 4. Hardware Tier Validation

### 4.1 Resource Tiers

| Tier | RAM | CPU | Disk | Suitable Variants |
|------|-----|-----|------|-------------------|
| Micro | < 2GB | 1 core | < 20GB | None (too small) |
| Small | 2-4GB | 2 cores | 20-50GB | Minimal |
| Medium | 4-8GB | 2-4 cores | 50-100GB | Minimal, Standard |
| Large | 8-16GB | 4-8 cores | 100-500GB | All |
| XLarge | > 16GB | > 8 cores | > 500GB | All |

### 4.2 Hardware Compatibility Validation

```cue
#ValidateHardware: {
    hardware: {
        ram_mb:     int
        cpu_cores:  int
        disk_gb:    int
    }
    variant: #Variant
    
    // Tier detection
    _tier: {
        if hardware.ram_mb < 2048 { "micro" }
        if hardware.ram_mb >= 2048 && hardware.ram_mb < 4096 { "small" }
        if hardware.ram_mb >= 4096 && hardware.ram_mb < 8192 { "medium" }
        if hardware.ram_mb >= 8192 && hardware.ram_mb < 16384 { "large" }
        if hardware.ram_mb >= 16384 { "xlarge" }
    }
    
    // Compatibility matrix
    _compatible: {
        micro: []
        small: ["minimal"]
        medium: ["minimal", "standard"]
        large: ["minimal", "standard", "full"]
        xlarge: ["minimal", "standard", "full"]
    }
    
    _isCompatible: list.Contains(_compatible[_tier], variant)
    
    errors: [
        if !_isCompatible {
            code: "VAL-HW-001"
            message: "Hardware tier '\(_tier)' is not compatible with variant '\(variant)'"
            hint: "Suitable variants for your hardware: \(strings.Join(_compatible[_tier], ", "))"
        },
    ]
    
    // Minimum resources for base-homelab
    _minimumRequirements: {
        minimal: {ram_mb: 2048, cpu_cores: 2, disk_gb: 20}
        standard: {ram_mb: 4096, cpu_cores: 2, disk_gb: 50}
        full: {ram_mb: 8192, cpu_cores: 4, disk_gb: 100}
    }
    
    warnings: [
        if hardware.ram_mb < _minimumRequirements[variant].ram_mb * 1.2 {
            code: "VAL-HW-002"
            message: "RAM is close to minimum, consider upgrading for better performance"
        },
    ]
    
    valid: len(errors) == 0
    tier: _tier
}
```

---

## 5. Port Allocation Validation

### 5.1 Port Assignments

```cue
#PortAssignments: {
    // Reserved system ports
    _systemPorts: [22, 53, 67, 68, 123, 161, 162]
    
    // base-homelab service ports
    _servicePorts: {
        traefik_http:      80
        traefik_https:     443
        traefik_dashboard: 8080
        dokploy:           3000
        coolify:           3001
        uptime_kuma:       3002
        beszel:            3003
        dozzle:            3004
        dockge:            3005
        portainer_http:    9000
        portainer_https:   9443
        netdata:           19999
    }
    
    // Available port ranges
    _availableRanges: {
        applications: {start: 3100, end: 3999}
        databases:    {start: 5432, end: 5499}
        caching:      {start: 6379, end: 6399}
        messaging:    {start: 5672, end: 5699}
    }
}

#ValidatePortAllocation: {
    services: {...}
    
    // Extract all ports
    _allPorts: [
        for name, svc in services
        if svc.ports != _|_
        for port in svc.ports {
            service: name
            port:    _extractHostPort(port)
        }
    ]
    
    // Find duplicates
    _portCounts: {
        for p in _allPorts {
            (string(p.port)): {
                count: int | *0
                count: _ + 1
                services: [...string] | *[]
                services: _ + [p.service]
            }
        }
    }
    
    _conflicts: [
        for port, data in _portCounts
        if data.count > 1 {
            port:     port
            services: data.services
        }
    ]
    
    errors: [
        for conflict in _conflicts {
            code: "VAL-PORT-001"
            message: "Port \(conflict.port) used by multiple services: \(strings.Join(conflict.services, ", "))"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 6. Success Criteria Validation

### 6.1 Deployment Success Criteria

```cue
#DeploymentCriteria: {
    stack: {...}
    
    // All critical services must be healthy
    _criticalServices: [
        for name, svc in stack.services
        if svc.criticality == "critical" {
            name: name
            status: svc.status
            health: svc.healthStatus
        }
    ]
    
    _allCriticalHealthy: [
        for svc in _criticalServices
        if svc.health != "healthy" {
            svc.name
        }
    ]
    
    // Important services should be healthy
    _importantServices: [
        for name, svc in stack.services
        if svc.criticality == "important" {
            name: name
            status: svc.status
            health: svc.healthStatus
        }
    ]
    
    _unhealthyImportant: [
        for svc in _importantServices
        if svc.health != "healthy" {
            svc.name
        }
    ]
    
    success: {
        critical: len(_allCriticalHealthy) == 0
        important: len(_unhealthyImportant) == 0
        overall: critical && important
    }
    
    status: {
        if success.overall { "DEPLOYED" }
        if success.critical && !success.important { "DEGRADED" }
        if !success.critical { "FAILED" }
    }
}
```

### 6.2 Operational Readiness Checklist

```cue
#OperationalReadiness: {
    stack: {...}
    
    checklist: {
        // Network connectivity
        traefikResponding: bool
        sslCertificateValid: bool
        
        // Service availability
        allServicesRunning: bool
        healthChecksPass: bool
        
        // Persistence
        volumesMounted: bool
        backupConfigured: bool
        
        // Security
        dashboardProtected: bool
        noDefaultPasswords: bool
        
        // Monitoring
        uptimeMonitoringActive: bool
        loggingConfigured: bool
    }
    
    _score: list.Sum([
        for k, v in checklist
        if v { 1 }
    ])
    
    _total: len(checklist)
    
    readinessPercent: _score / _total * 100
    ready: readinessPercent >= 80
    
    missing: [
        for k, v in checklist
        if !v { k }
    ]
}
```

---

## 7. Error Catalog (base-homelab Specific)

| Code | Category | Description |
|------|----------|-------------|
| `VAL-SVC-TRF-001` | Traefik | Missing required ports |
| `VAL-SVC-TRF-002` | Traefik | Invalid restart policy |
| `VAL-SVC-TRF-003` | Traefik | Missing Docker socket |
| `VAL-SVC-TRF-004` | Traefik | Missing self-registration label |
| `VAL-SVC-PAAS-001` | PaaS | Missing Docker socket |
| `VAL-SVC-PAAS-002` | PaaS | Multiple PaaS platforms |
| `VAL-SVC-PAAS-003` | PaaS | No memory limits |
| `VAL-SVC-UK-001` | Uptime Kuma | Missing data volume |
| `VAL-SVC-UK-002` | Uptime Kuma | No health check |
| `VAL-SVC-SOCK-001` | Docker Socket | Missing required socket |
| `VAL-SVC-SOCK-002` | Docker Socket | Socket not read-only |
| `VAL-VAR-001` | Variant | Missing required services |
| `VAL-VAR-002` | Variant | Extra services in minimal |
| `VAL-HW-001` | Hardware | Tier incompatible with variant |
| `VAL-HW-002` | Hardware | RAM close to minimum |
| `VAL-PORT-001` | Ports | Port conflict |

---

## References

- **Layer 1:** [Foundation Validation](../../layer-1-foundation/base/VALIDATION.md)
- **Layer 2:** [Docker Validation](../../layer-2-platform/docker/VALIDATION.md)
- **Contract:** [base-homelab Contract](./CONTRACT.md)
