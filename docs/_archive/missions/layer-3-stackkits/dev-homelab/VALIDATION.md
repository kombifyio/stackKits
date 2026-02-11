# StackKit Layer: dev-homelab Validation

**Scope:** This document defines validation rules for the dev-homelab StackKit. Dev-homelab uses the **minimal foundation** and **Docker platform**, optimized for development environments.

---

## 1. Dev-Homelab Overview

### 1.1 Foundation & Platform Selection

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DEV-HOMELAB LAYER COMPOSITION                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Layer 1: Foundation                                                     │
│  ┌─────────────┐                                                        │
│  │  MINIMAL    │  ← Selected (lightweight, fast startup)                │
│  │  Foundation │                                                        │
│  └─────────────┘                                                        │
│       │                                                                  │
│       ▼                                                                  │
│  Layer 2: Platform                                                       │
│  ┌─────────────┐                                                        │
│  │   DOCKER    │  ← Selected (single-host, simple)                      │
│  │  Platform   │                                                        │
│  └─────────────┘                                                        │
│       │                                                                  │
│       ▼                                                                  │
│  Layer 3: StackKit                                                       │
│  ┌─────────────┐                                                        │
│  │ DEV-HOMELAB │  ← This document                                       │
│  │  StackKit   │                                                        │
│  └─────────────┘                                                        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Design Goals

| Goal | Description |
|------|-------------|
| **Fast Startup** | Stack deploys in < 2 minutes |
| **Low Resources** | Runs on 2GB RAM, 2 cores |
| **Developer Focus** | Optimized for development workflows |
| **Easy Reset** | Can destroy and recreate quickly |
| **Local-Only** | No external dependencies |

---

## 2. Service Definitions

### 2.1 Core Services

| Service | Purpose | Required | Port |
|---------|---------|----------|------|
| Traefik | Reverse proxy (minimal config) | Yes | 80, 443, 8080 |
| Coolify | PaaS (development deployments) | Yes | 3001 |
| Dozzle | Log viewer | Yes | 3004 |

### 2.2 Optional Services

| Service | Purpose | Default | Port |
|---------|---------|---------|------|
| Adminer | Database admin | Off | 8081 |
| MailHog | Email testing | Off | 8025, 1025 |
| MinIO | S3-compatible storage | Off | 9000, 9001 |
| Redis Commander | Redis UI | Off | 8082 |

---

## 3. Validation Rules

### 3.1 Resource Constraints

```cue
#DevHomelabResources: {
    // Minimum requirements (lower than base-homelab)
    minimum: {
        ram_mb:    2048   // 2GB
        cpu_cores: 2
        disk_gb:   20
    }
    
    // Recommended for comfortable development
    recommended: {
        ram_mb:    4096   // 4GB
        cpu_cores: 4
        disk_gb:   50
    }
    
    // Service allocations (minimal)
    services: {
        traefik: {
            memory_min: "64M"
            memory_max: "128M"
        }
        coolify: {
            memory_min: "256M"
            memory_max: "512M"
        }
        dozzle: {
            memory_min: "32M"
            memory_max: "64M"
        }
    }
}

#ValidateDevResources: {
    hardware: {
        ram_mb:    int
        cpu_cores: int
    }
    
    _meetsMinimum: hardware.ram_mb >= 2048 && hardware.cpu_cores >= 2
    
    errors: [
        if !_meetsMinimum {
            code: "VAL-DEV-RES-001"
            message: "dev-homelab requires at least 2GB RAM and 2 CPU cores"
        },
    ]
    
    warnings: [
        if hardware.ram_mb < 4096 {
            code: "VAL-DEV-RES-002"
            message: "4GB+ RAM recommended for better development experience"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 3.2 Network Validation

```cue
#DevNetworkConfig: {
    // Development uses local domains
    domain: =~"^[a-z0-9-]+\\.local$" | =~"^localhost$"
    
    // Simplified subnet
    subnet: "172.30.0.0/24"
    
    // No external access required
    external: false
}

#ValidateDevNetwork: {
    network: {...}
    
    errors: [
        if !strings.HasSuffix(network.domain, ".local") && network.domain != "localhost" {
            code: "VAL-DEV-NET-001"
            message: "dev-homelab should use .local domain or localhost"
            hint: "Use 'dev.local' or 'myproject.local'"
        },
    ]
    
    valid: len(errors) == 0
}
```

### 3.3 TLS Validation (Development Mode)

```cue
#DevTLSConfig: {
    // Development always uses self-signed
    provider: "selfsigned"
    
    // mkcert for local development
    mkcert: bool | *true
    
    // No ACME in development
    acme: false
}

#ValidateDevTLS: {
    tls: {...}
    
    errors: [
        if tls.acme == true {
            code: "VAL-DEV-TLS-001"
            message: "dev-homelab should not use ACME/Let's Encrypt"
            hint: "Use mkcert for local development certificates"
        },
    ]
    
    warnings: [
        if tls.mkcert != true {
            code: "VAL-DEV-TLS-002"
            message: "Consider using mkcert for trusted local certificates"
        },
    ]
    
    valid: len(errors) == 0
}
```

---

## 4. Service Validation

### 4.1 Traefik (Minimal Config)

```cue
#DevTraefikValidation: {
    service: {...}
    
    // Development-specific settings
    _expectedConfig: {
        // No ACME
        certificatesResolvers: _|_
        
        // Dashboard enabled without auth (local only)
        api: {
            dashboard: true
            insecure:  true  // OK for local dev
        }
    }
    
    errors: []  // Relaxed for development
    
    warnings: [
        if service.ports != _|_ && len(service.ports) > 3 {
            code: "VAL-DEV-TRF-001"
            message: "Minimal Traefik should only expose essential ports"
        },
    ]
    
    valid: true
}
```

### 4.2 Coolify Validation

```cue
#DevCoolifyValidation: {
    service: {...}
    
    // Coolify is the primary PaaS for dev
    _required: true
    
    // Data persistence
    _hasDataVolume: _hasVolume(service.volumes, "/data")
    
    errors: [
        if !_hasDataVolume {
            code: "VAL-DEV-CLF-001"
            message: "Coolify requires /data volume for persistence"
        },
    ]
    
    // Relaxed health check requirement for dev
    warnings: []
    
    valid: len(errors) == 0
}
```

### 4.3 Development Tools Validation

```cue
#DevToolsValidation: {
    services: {...}
    
    // Check optional dev tools
    _hasMailHog: services.mailhog != _|_
    _hasAdminer: services.adminer != _|_
    _hasMinIO:   services.minio != _|_
    
    // Port conflicts with optional services
    _devPorts: {
        mailhog_smtp: 1025
        mailhog_web:  8025
        adminer:      8081
        minio_api:    9000
        minio_console: 9001
    }
    
    errors: []  // No strict requirements for dev tools
    
    info: [
        if _hasMailHog {
            "MailHog available at :8025 (SMTP on :1025)"
        },
        if _hasAdminer {
            "Adminer available at :8081"
        },
        if _hasMinIO {
            "MinIO available at :9000 (console :9001)"
        },
    ]
    
    valid: true
}
```

---

## 5. Data Persistence Validation

### 5.1 Development Data Strategy

```cue
#DevDataStrategy: {
    // Development prioritizes fast reset over persistence
    strategy: "ephemeral" | "persistent"
    
    // Ephemeral: data can be lost, fast startup
    // Persistent: data survives restarts
    
    _config: {
        if strategy == "ephemeral" {
            volumeDriver: "local"
            backup: false
            tmpfs: true
        }
        if strategy == "persistent" {
            volumeDriver: "local"
            backup: false  // Still no backup in dev
            tmpfs: false
        }
    }
}

#ValidateDevData: {
    strategy: "ephemeral" | "persistent"
    volumes:  {...}
    
    warnings: [
        if strategy == "ephemeral" {
            code: "VAL-DEV-DATA-001"
            message: "Ephemeral mode: data will be lost on stack destroy"
        },
    ]
    
    valid: true
}
```

---

## 6. Startup Time Validation

### 6.1 Performance Targets

```cue
#DevPerformanceTargets: {
    // Target startup times
    targets: {
        total:    "120s"   // Full stack in 2 minutes
        traefik:  "10s"
        coolify:  "60s"    // Coolify is slow to start
        dozzle:   "5s"
    }
    
    // Image pull times (first run)
    imagePull: {
        total: "300s"  // 5 minutes with slow connection
    }
}

#ValidateDevPerformance: {
    services: {...}
    
    // Warn about heavy images
    _heavyImages: [
        for name, svc in services
        if _estimateImageSize(svc.image) > 500 {  // MB
            name
        }
    ]
    
    warnings: [
        if len(_heavyImages) > 0 {
            code: "VAL-DEV-PERF-001"
            message: "Heavy images may slow startup: \(strings.Join(_heavyImages, ", "))"
        },
    ]
    
    valid: true
}
```

---

## 7. Differences from base-homelab

### 7.1 Comparison Matrix

| Aspect | base-homelab | dev-homelab |
|--------|--------------|-------------|
| Foundation | Base/Extended | **Minimal** |
| Min RAM | 4GB | **2GB** |
| Min CPU | 2 cores | **2 cores** |
| Services | 5-9 | **3-6** |
| TLS | Let's Encrypt | **mkcert/self-signed** |
| Domain | Public | **\*.local** |
| Backup | Yes | **No** |
| Monitoring | Full | **Dozzle only** |
| Health Checks | Required | **Optional** |
| Persistence | Required | **Optional** |

### 7.2 Relaxed Validations

```cue
// These validations are relaxed for dev-homelab:

#DevRelaxedValidation: {
    // Health checks are optional
    healthCheckRequired: false
    
    // Persistence is optional
    persistenceRequired: false
    
    // TLS can be self-signed
    trustedTLSRequired: false
    
    // Dashboard auth is optional
    dashboardAuthRequired: false
    
    // Resource limits are suggestions
    resourceLimitsStrict: false
    
    // Backup is not required
    backupRequired: false
}
```

---

## 8. Quick Start Validation

### 8.1 One-Command Deploy

```cue
#QuickStartValidation: {
    // dev-homelab should work with minimal config
    _quickStartConfig: {
        name:    "dev"
        domain:  "dev.local"
        variant: "minimal"  // Implied for dev
    }
    
    // Validate quick start is possible
    _canQuickStart: {
        noExternalDeps: true
        noSecrets: true
        defaultsWork: true
    }
}
```

### 8.2 Default Configuration

```yaml
# dev-homelab defaults (implicit)
apiVersion: stackkits.io/v1
kind: StackKit
metadata:
  name: dev
  type: dev-homelab

spec:
  domain: dev.local
  
  tls:
    provider: selfsigned
    mkcert: true
  
  services:
    traefik:
      enabled: true
      dashboard: true
      insecure: true  # OK for local dev
      
    coolify:
      enabled: true
      
    dozzle:
      enabled: true
  
  persistence:
    strategy: ephemeral
    
  backup:
    enabled: false
```

---

## 9. Error Catalog (dev-homelab Specific)

| Code | Category | Description |
|------|----------|-------------|
| `VAL-DEV-RES-001` | Resources | Insufficient RAM/CPU |
| `VAL-DEV-RES-002` | Resources | Below recommended |
| `VAL-DEV-NET-001` | Network | Non-local domain |
| `VAL-DEV-TLS-001` | TLS | ACME in development |
| `VAL-DEV-TLS-002` | TLS | mkcert not used |
| `VAL-DEV-TRF-001` | Traefik | Too many ports |
| `VAL-DEV-CLF-001` | Coolify | Missing data volume |
| `VAL-DEV-DATA-001` | Data | Ephemeral mode |
| `VAL-DEV-PERF-001` | Performance | Heavy images |

---

## References

- **Layer 1:** [Minimal Foundation](../../layer-1-foundation/minimal/CONTRACT.md)
- **Layer 2:** [Docker Platform](../../layer-2-platform/docker/VALIDATION.md)
- **Alternative:** [base-homelab Validation](../base-homelab/VALIDATION.md)
- **Contract:** [dev-homelab Contract](./CONTRACT.md)
