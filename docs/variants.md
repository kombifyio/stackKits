# Variant System

> **Version:** 1.0  
> **Status:** Production Ready

The variant system allows StackKits to adapt to different operating systems, hardware configurations, and deployment scenarios. This document explains how variants work and how to create custom variants.

## Overview

StackKits support two types of variants:

1. **OS Variants** - Operating system-specific configurations
2. **Compute Variants** - Resource tier configurations

```
variants/
├── os/
│   ├── ubuntu-24.cue    # Ubuntu 24.04 LTS
│   ├── ubuntu-22.cue    # Ubuntu 22.04 LTS
│   └── debian-12.cue    # Debian 12 Bookworm
└── compute/
    └── compute.cue      # high, standard, low tiers
```

## OS Variants

OS variants handle differences between Linux distributions:

- Package managers (apt, dnf, pacman)
- Package names (bat vs batcat, fd vs fdfind)
- Firewall backends (ufw, firewalld, iptables)
- Service managers (systemd units)
- Docker installation paths

### Available OS Variants

| Variant | Distribution | Version | EOL | Status |
|---------|-------------|---------|-----|--------|
| `ubuntu-24` | Ubuntu | 24.04 LTS | 2034-04 | ✅ Recommended |
| `ubuntu-22` | Ubuntu | 22.04 LTS | 2032-04 | ✅ Supported |
| `debian-12` | Debian | 12 Bookworm | 2028-06 | ✅ Supported |
| `debian-11` | Debian | 11 Bullseye | 2026-06 | ⚠️ Legacy |

### OS Variant Structure

```cue
// variants/os/ubuntu-24.cue
package base_homelab

#Ubuntu24Variant: #OSVariant & {
    // OS identification
    os: {
        family:       "debian"
        distribution: "ubuntu"
        version:      "24.04"
        codename:     "noble"
        eol:          "2034-04"
        lts:          true
    }

    // Package management
    packages: {
        manager: "apt"
        
        updateCmd: [
            "apt-get update",
            "apt-get upgrade -y",
        ]

        // Base system packages
        base: [
            "apt-transport-https",
            "ca-certificates",
            "curl",
            "gnupg",
            "lsb-release",
        ]

        // Modern CLI tools
        tools: [
            "bat",
            "eza",          // Renamed from exa
            "fd-find",
            "ripgrep",
            "htop",
            "btop",
        ]

        // Tool aliases (Ubuntu-specific binary names)
        toolAliases: {
            "bat":     "batcat"
            "fd-find": "fdfind"
        }

        // Docker installation
        docker: {
            repo:       "https://download.docker.com/linux/ubuntu"
            keyUrl:     "https://download.docker.com/linux/ubuntu/gpg"
            keyring:    "/etc/apt/keyrings/docker.gpg"
            sourcelist: "/etc/apt/sources.list.d/docker.list"
            packages: [
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-buildx-plugin",
                "docker-compose-plugin",
            ]
        }
    }

    // Firewall configuration
    firewall: {
        backend: "ufw"
        package: "ufw"
        commands: {
            enable:   "ufw --force enable"
            disable:  "ufw disable"
            status:   "ufw status verbose"
            allow:    "ufw allow"
            deny:     "ufw deny"
            reset:    "ufw --force reset"
        }
    }

    // Service management
    services: {
        manager: "systemd"
        commands: {
            enable:  "systemctl enable"
            start:   "systemctl start"
            stop:    "systemctl stop"
            restart: "systemctl restart"
            status:  "systemctl status"
        }
    }
}
```

### Selecting an OS Variant

In your `kombination.yaml`:

```yaml
# Explicit OS selection
nodes:
  - name: server-1
    os: ubuntu-24
    # ...

# Or with full specification
nodes:
  - name: server-1
    os:
      distribution: ubuntu
      version: "24.04"
```

### Creating a Custom OS Variant

To add support for a new distribution:

1. Create the variant file:

```cue
// variants/os/rocky-9.cue
package base_homelab

#Rocky9Variant: #OSVariant & {
    os: {
        family:       "rhel"
        distribution: "rocky"
        version:      "9"
        codename:     "Blue Onyx"
        eol:          "2032-05"
    }

    packages: {
        manager: "dnf"
        
        updateCmd: [
            "dnf update -y",
        ]

        base: [
            "curl",
            "ca-certificates",
            "dnf-plugins-core",
        ]

        docker: {
            repo: "https://download.docker.com/linux/centos/docker-ce.repo"
            packages: [
                "docker-ce",
                "docker-ce-cli",
                "containerd.io",
                "docker-compose-plugin",
            ]
        }
    }

    firewall: {
        backend: "firewalld"
        package: "firewalld"
        commands: {
            enable: "firewall-cmd --permanent --add-service="
            reload: "firewall-cmd --reload"
        }
    }
}
```

2. Register the variant in the StackKit:

```cue
// stackfile.cue
#SupportedOS: "ubuntu-24" | "ubuntu-22" | "debian-12" | "rocky-9"
```

3. Update `stackkit.yaml`:

```yaml
requirements:
  os:
    - ubuntu-24
    - ubuntu-22
    - debian-12
    - rocky-9  # Added
```

## Compute Variants

Compute variants adjust resource allocations based on available hardware:

### Available Compute Tiers

| Tier | CPU | Memory | Use Case |
|------|-----|--------|----------|
| `high` | 8+ cores | 16+ GB | Production, heavy workloads |
| `standard` | 4 cores | 8 GB | Development, light production |
| `low` | 2 cores | 4 GB | Testing, minimal deployments |

### Compute Variant Structure

```cue
// variants/compute/compute.cue
package base_homelab

// Compute tier selection
#ComputeTier: "high" | "standard" | "low"

// Automatic tier selection based on resources
#AutoComputeTier: {
    cpu:    int
    memory: int  // in MB

    // Tier logic
    tier: *"low" | "standard" | "high"
    
    if cpu >= 8 && memory >= 16384 {
        tier: "high"
    }
    if cpu >= 4 && memory >= 8192 && cpu < 8 {
        tier: "standard"
    }
}

// Service resource limits by tier
#ComputeResources: {
    tier: #ComputeTier

    // Traefik
    traefik: {
        if tier == "high" {
            memory:    "512m"
            memoryMax: "1g"
            cpus:      1.0
        }
        if tier == "standard" {
            memory:    "256m"
            memoryMax: "512m"
            cpus:      0.5
        }
        if tier == "low" {
            memory:    "128m"
            memoryMax: "256m"
            cpus:      0.25
        }
    }

    // Dokploy / Main Platform
    platform: {
        if tier == "high" {
            memory:    "2g"
            memoryMax: "4g"
            cpus:      2.0
        }
        if tier == "standard" {
            memory:    "512m"
            memoryMax: "1g"
            cpus:      1.0
        }
        if tier == "low" {
            memory:    "256m"
            memoryMax: "512m"
            cpus:      0.5
        }
    }

    // Monitoring (Uptime Kuma, Beszel)
    monitoring: {
        if tier == "high" {
            memory:    "512m"
            memoryMax: "1g"
            cpus:      0.5
        }
        if tier == "standard" {
            memory:    "256m"
            memoryMax: "512m"
            cpus:      0.25
        }
        if tier == "low" {
            memory:    "128m"
            memoryMax: "256m"
            cpus:      0.1
        }
    }
}
```

### Specifying Compute Tier

```yaml
# Explicit tier
nodes:
  - name: server-1
    resources:
      cpu: 4
      memory: 8192  # MB
    compute_tier: standard

# Or let it auto-detect
nodes:
  - name: server-1
    resources:
      cpu: 4
      memory: 8192
    # compute_tier auto-selected as "standard"
```

## Service Variants

Some StackKits offer service variants (different service combinations):

### Base Homelab Variants

| Variant | Services | Use Case |
|---------|----------|----------|
| `default` | Traefik + Dokploy + Uptime Kuma | PaaS-style deployment |
| `beszel` | Traefik + Dokploy + Beszel | Lightweight monitoring |
| `minimal` | Traefik + Dockge + Portainer | Simple container management |

### Selecting a Service Variant

```yaml
# kombination.yaml
stackkit: base-homelab
variant: default  # or: beszel, minimal
```

### Variant Resolution

The CUE schema handles variant resolution:

```cue
// stackfile.cue
#BaseHomelabKit: base.#BaseStackKit & {
    // Variant selection
    variant: "default" | "beszel" | "minimal" | *"default"

    // Conditional service enablement
    services: [
        #TraefikService,  // Always included
        
        if variant == "default" || variant == "beszel" {
            #DokployService
        },
        if variant == "default" {
            #UptimeKumaService
        },
        if variant == "beszel" {
            #BeszelService
        },
        if variant == "minimal" {
            #DockgeService,
            #PortainerService,
            #NetdataService,
        },
    ]
}
```

## Variant Inheritance

Variants can inherit from each other:

```cue
// Base Ubuntu variant
#UbuntuBaseVariant: #OSVariant & {
    os: family: "debian"
    packages: manager: "apt"
    firewall: backend: "ufw"
}

// Ubuntu 24.04 extends base
#Ubuntu24Variant: #UbuntuBaseVariant & {
    os: {
        distribution: "ubuntu"
        version:      "24.04"
        codename:     "noble"
    }
}

// Ubuntu 22.04 extends base
#Ubuntu22Variant: #UbuntuBaseVariant & {
    os: {
        distribution: "ubuntu"
        version:      "22.04"
        codename:     "jammy"
    }
}
```

## Testing Variants

Validate all variant combinations:

```bash
# Test specific OS variant
cue vet ./... -d '#Ubuntu24Variant'

# Test compute tier
cue eval ./... -e '#ComputeResources & {tier: "standard"}'

# Test service variant
cue eval ./base-homelab/... -e '#BaseHomelabKit & {variant: "minimal"}'
```

## Best Practices

### 1. OS Variants

- **Test on actual systems** before publishing
- **Document EOL dates** to warn users
- **Handle package name differences** with aliases
- **Include Docker installation** instructions

### 2. Compute Variants

- **Be conservative** with low-tier limits
- **Test memory pressure** scenarios
- **Document minimum requirements** clearly
- **Allow manual overrides** for power users

### 3. Service Variants

- **Keep variants focused** on clear use cases
- **Ensure core services** are always present
- **Document trade-offs** between variants
- **Test all combinations** in CI

## Troubleshooting

### Variant Not Found

```
Error: unknown OS variant "centos-8"
```

**Solution:** Check `stackkit.yaml` for supported OS list, or create a custom variant.

### Resource Limit Exceeded

```
Error: container killed (OOM): memory limit 256m
```

**Solution:** Use a higher compute tier or increase service-specific limits.

### Package Installation Failed

```
Error: package "docker-ce" not found
```

**Solution:** Verify Docker repository configuration in OS variant.

## Next Steps

- [Creating StackKits](creating-stackkits.md) - Build custom StackKits
- [Template Reference](templates.md) - OpenTofu template patterns
- [Architecture](architecture.md) - Overall system design
