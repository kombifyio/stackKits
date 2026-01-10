# Adopting StackKits on Existing Systems

> **Version:** 1.0  
> **Status:** Planning Phase

This document describes how to apply StackKits to systems that already have services running, enabling gradual adoption without disrupting existing infrastructure.

## Overview

Deploying StackKits on existing systems requires careful handling of:

1. **Service Discovery** - Identify what's already running
2. **Conflict Resolution** - Handle port/volume conflicts
3. **State Import** - Bring existing resources under management
4. **Migration Strategies** - Move from manual to declarative management

## Adoption Modes

### 1. Coexist Mode

StackKits manage new services alongside existing ones:

```yaml
# kombination.yaml
adoption:
  mode: coexist
  
  existing:
    # Leave these services alone
    exclude:
      - portainer
      - custom-app
    
    # StackKit avoids these ports
    reserved_ports:
      - 9443  # Portainer
      - 8080  # Custom app
```

**Pros:**
- Minimal disruption
- Gradual adoption
- No downtime

**Cons:**
- Dual management (manual + StackKit)
- Potential configuration drift
- Resource overhead

### 2. Migrate Mode

Gradually move existing services under StackKit management:

```yaml
# kombination.yaml
adoption:
  mode: migrate
  
  services:
    traefik:
      action: adopt     # Import existing Traefik
      preserve:
        config: true    # Keep current configuration
        certs: true     # Keep SSL certificates
      
    portainer:
      action: migrate   # Replace with StackKit version
      strategy: blue-green
      
    jellyfin:
      action: import    # Import as custom service
      from: docker      # Detect from running container
```

**Pros:**
- Controlled transition
- Preserves data
- Validates before cutover

**Cons:**
- Longer adoption timeline
- Requires planning

### 3. Takeover Mode

Full StackKit management (advanced users):

```yaml
# kombination.yaml
adoption:
  mode: takeover
  
  # Stop and remove unmanaged containers
  cleanup: true
  
  # Backup before takeover
  backup:
    enabled: true
    destination: /opt/backup/pre-stackkit
```

**Warning:** This mode will stop all containers not defined in the StackKit.

## System Analysis

### Analyze Command

```bash
# Analyze current system
stackkit analyze

# Output:
# ╔══════════════════════════════════════════════════════════════════╗
# ║                      SYSTEM ANALYSIS                              ║
# ╠══════════════════════════════════════════════════════════════════╣
# ║                                                                   ║
# ║  Operating System:                                                ║
# ║    Distribution: Ubuntu 24.04 LTS (noble)                         ║
# ║    Kernel: 6.5.0-15-generic                                       ║
# ║                                                                   ║
# ║  Resources:                                                       ║
# ║    CPU: 4 cores                                                   ║
# ║    Memory: 8 GB                                                   ║
# ║    Storage: 120 GB (45 GB used)                                   ║
# ║    Compute Tier: standard                                         ║
# ║                                                                   ║
# ║  Docker:                                                          ║
# ║    Version: 24.0.7                                                ║
# ║    Containers: 5 running, 2 stopped                               ║
# ║    Networks: 3 (bridge, host, homelab)                            ║
# ║    Volumes: 12 (8.5 GB used)                                      ║
# ║                                                                   ║
# ║  Detected Services:                                               ║
# ║    ✓ traefik (v2.10)      ports: 80, 443, 8080                   ║
# ║    ✓ portainer (2.19)     ports: 9443                            ║
# ║    ✓ jellyfin (10.8)      ports: 8096                            ║
# ║    ✓ sonarr (4.0)         ports: 8989                            ║
# ║    ✓ radarr (5.0)         ports: 7878                            ║
# ║                                                                   ║
# ║  Potential Conflicts:                                             ║
# ║    ⚠ traefik: Different version than StackKit default            ║
# ║    ⚠ portainer: Port 9443 not in StackKit templates              ║
# ║                                                                   ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Recommendations:
#   1. Adopt traefik (preserve config and certs)
#   2. Exclude portainer (not in StackKit)
#   3. Import jellyfin, sonarr, radarr as StackKit services
```

### Detailed Service Analysis

```bash
# Analyze specific service
stackkit analyze traefik

# Output:
# Service: traefik
# Image: traefik:v2.10.7
# Status: running (uptime: 45d 12h)
# 
# Ports:
#   80/tcp  → 0.0.0.0:80
#   443/tcp → 0.0.0.0:443
#   8080/tcp → 0.0.0.0:8080 (dashboard)
# 
# Volumes:
#   /var/run/docker.sock → /var/run/docker.sock (bind, ro)
#   traefik_certs → /certs (volume)
#   /opt/traefik/config → /etc/traefik (bind)
# 
# Labels:
#   traefik.enable=true
#   traefik.http.routers.api.rule=Host(`traefik.home.local`)
# 
# Health: healthy (last check: 5s ago)
# 
# StackKit Compatibility:
#   ✓ Compatible with base-homelab
#   ✓ Can be adopted (preserve config)
#   ⚠ Version mismatch (StackKit uses v3.1)
#     Action: Keep v2.10 or upgrade during adoption
```

## Import Strategies

### From Docker Containers

```bash
# Import all running containers
stackkit import --from docker

# Import specific container
stackkit import --from docker --name traefik

# Preview only (dry-run)
stackkit import --from docker --dry-run
```

Generated configuration:

```yaml
# Generated: imported-services.yaml
services:
  traefik:
    source: docker
    image: traefik:v2.10.7
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_certs:/certs
      - /opt/traefik/config:/etc/traefik
    labels:
      traefik.enable: "true"
```

### From Docker Compose

```bash
# Import from docker-compose.yml
stackkit import --from compose ./docker-compose.yml

# Import with volume mapping
stackkit import --from compose ./docker-compose.yml \
  --volume-map "/old/path=/new/path"
```

### From Portainer Stacks

```bash
# Connect to Portainer API
stackkit import --from portainer \
  --endpoint https://portainer.local:9443 \
  --api-key "${PORTAINER_API_KEY}"

# Import specific stack
stackkit import --from portainer --stack media-server
```

## State Import

### OpenTofu State Import

When adopting existing Docker resources:

```bash
# Auto-import existing resources
stackkit adopt --auto-import

# Manual import (advanced)
cd deploy/
tofu import docker_container.traefik $(docker inspect traefik --format '{{.Id}}')
tofu import docker_network.homelab homelab
tofu import docker_volume.traefik_certs traefik_certs
```

### State Reconciliation

```bash
# Check for drift between running containers and desired state
stackkit reconcile

# Output:
# Reconciliation Report:
# 
# traefik:
#   ✓ Image: matches
#   ⚠ Ports: differs (running: 8080, desired: none)
#   ✓ Volumes: matches
# 
# jellyfin:
#   ⚠ Image: differs (running: 10.8.9, desired: 10.9.0)
#   ✓ Ports: matches
#   ✓ Volumes: matches
# 
# Actions:
#   stackkit apply --update traefik  # Sync ports
#   stackkit apply --update jellyfin # Update image
```

## Conflict Resolution

### Port Conflicts

```yaml
# kombination.yaml
adoption:
  conflicts:
    ports:
      # Remap conflicting ports
      9443:
        action: remap
        to: 9444
      
      # Reserve for existing service
      8080:
        action: reserve
        reason: "Custom application"
```

### Volume Conflicts

```yaml
adoption:
  conflicts:
    volumes:
      # Preserve existing volume data
      traefik_certs:
        action: adopt
        preserve_data: true
      
      # Migrate to new volume
      old_jellyfin_config:
        action: migrate
        to: jellyfin-config
```

### Network Conflicts

```yaml
adoption:
  conflicts:
    networks:
      # Use existing network
      homelab:
        action: adopt
      
      # Create new with different subnet
      existing_bridge:
        action: coexist
        new_subnet: "172.21.0.0/16"
```

## Migration Workflows

### Blue-Green Migration

For zero-downtime service replacement:

```yaml
adoption:
  services:
    traefik:
      strategy: blue-green
      steps:
        - deploy_new:
            ports: [8080, 8443]  # Temporary ports
            validate: true
        - switch_traffic:
            method: dns          # or: proxy, manual
            rollback_window: 5m
        - cleanup_old:
            delay: 10m
            backup: true
```

### Rolling Migration

For multi-container services:

```yaml
adoption:
  services:
    media-stack:
      strategy: rolling
      order:
        - jellyfin     # Migrate first
        - sonarr       # Then automation
        - radarr
        - prowlarr     # Finally indexer
      delay_between: 2m
      validation:
        health_check: true
        timeout: 60s
```

## Backup & Rollback

### Pre-Adoption Backup

```bash
# Create full backup before adoption
stackkit backup --pre-adoption

# Backup location: /opt/backup/stackkit-pre-adoption-2026-01-10/
# Contents:
#   - container-configs/
#   - volumes/
#   - networks.json
#   - docker-compose.yml (if exists)
```

### Rollback Procedure

```bash
# Rollback to pre-adoption state
stackkit rollback --to pre-adoption

# Rollback specific service
stackkit rollback --service traefik --to previous

# List available rollback points
stackkit rollback --list
```

## Best Practices

### 1. Always Analyze First

```bash
# Full system analysis before any changes
stackkit analyze --full > system-analysis.json
```

### 2. Test in Isolation

```bash
# Use a test network for validation
stackkit apply --test-mode

# Validate services are working
stackkit validate --health

# Promote to production
stackkit apply --promote
```

### 3. Document Existing State

```bash
# Export current container configs
for c in $(docker ps --format '{{.Names}}'); do
  docker inspect $c > "backup/$c.json"
done
```

### 4. Incremental Adoption

Start with non-critical services:

1. **Week 1:** Adopt monitoring (Uptime Kuma, Beszel)
2. **Week 2:** Adopt reverse proxy (Traefik)
3. **Week 3:** Adopt applications (Jellyfin, etc.)
4. **Week 4:** Full StackKit management

### 5. Keep Escape Hatches

```yaml
# Always maintain manual override capability
adoption:
  safety:
    # Export compose files for manual fallback
    export_compose: true
    export_path: /opt/backup/compose/
    
    # Keep container labels for identification
    preserve_labels: true
```

## Troubleshooting

### Service Won't Start After Adoption

```bash
# Check container logs
docker logs <container_name>

# Verify volume permissions
ls -la /var/lib/docker/volumes/<volume>/_data/

# Compare with original configuration
diff original-config.json current-config.json
```

### State Mismatch

```bash
# Refresh OpenTofu state
stackkit refresh

# Force state sync
stackkit apply --refresh-only
```

### Network Connectivity Issues

```bash
# Verify network configuration
docker network inspect homelab

# Check DNS resolution inside containers
docker exec traefik nslookup jellyfin
```

## Next Steps

- [CLI Reference](cli-reference.md) - Command details
- [Architecture](architecture.md) - System design
- [Roadmap](ROADMAP.md) - Future features
