# Platform Layer: Docker Security Hardening

**Scope:** This document defines Docker-specific security hardening patterns that extend the Foundation Layer. Based on best practices for production container deployments.

---

## 1. Hardening Philosophy

### Strong Defaults, Intentional Overrides

Docker containers ship with many capabilities enabled by default. Our approach:

1. **Drop ALL capabilities** by default
2. **Add back only what's needed** per-service
3. **Document why** any relaxation is required

### Attack Surface Reduction

Each hardening measure reduces potential attack vectors:

| Measure | Prevents |
|---------|----------|
| Non-root user | Privilege escalation |
| Read-only filesystem | Persistent malware |
| No new privileges | Runtime escalation |
| Capability drop | Kernel exploitation |
| Resource limits | Resource exhaustion |
| noexec tmpfs | Payload execution |

---

## 2. Container Security Context

### 2.1 Standard Hardened Configuration

```yaml
# docker-compose.yml hardened service template
services:
  example:
    image: example:latest
    
    # Run as non-root user (e.g., nobody:users = 99:100 on Unraid)
    user: "1000:1000"
    
    # Disable interactive access
    tty: false
    stdin_open: false
    
    # Read-only filesystem where possible
    read_only: true
    
    # Prevent privilege escalation
    security_opt:
      - no-new-privileges:true
    
    # Drop ALL capabilities
    cap_drop:
      - ALL
    
    # Add back only required capabilities (example)
    # cap_add:
    #   - NET_BIND_SERVICE
```

### 2.2 Capability Reference

Common capabilities and when they might be needed:

| Capability | Use Case | Add If |
|------------|----------|--------|
| `NET_BIND_SERVICE` | Bind ports < 1024 | Web servers on 80/443 |
| `CHOWN` | Change file ownership | Installers, init scripts |
| `SETUID/SETGID` | Switch users | Process managers |
| `NET_RAW` | Raw sockets | Network diagnostics only |
| `SYS_ADMIN` | Many syscalls | **Avoid if possible** |

---

## 3. Resource Limits

### 3.1 Memory and CPU

Prevent containers from consuming all host resources:

```yaml
services:
  example:
    # Memory hard limit
    mem_limit: 2g
    
    # Memory soft limit (reservation)
    mem_reservation: 512m
    
    # CPU limit (number of CPUs)
    cpus: 2
    
    # Prevent fork bombs
    pids_limit: 512
```

### 3.2 Profile Recommendations

| Profile | Memory | CPU | PIDs | Use Case |
|---------|--------|-----|------|----------|
| Minimal | 256m | 0.5 | 128 | Sidecars, proxies |
| Standard | 1g | 2 | 512 | Most services |
| Heavy | 4g | 4 | 1024 | Databases, build tools |
| Unrestricted | - | - | - | **Only for trusted workloads** |

---

## 4. Filesystem Hardening

### 4.1 Read-Only Root

```yaml
services:
  example:
    read_only: true
    
    # Writable tmpfs for runtime needs
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=512m
      - /var/run:rw,noexec,nosuid,nodev,size=64m
```

### 4.2 Tmpfs Options

| Option | Effect |
|--------|--------|
| `noexec` | Cannot execute binaries |
| `nosuid` | Ignore SUID bits |
| `nodev` | No device files |
| `size=512m` | Limit size |

**Note:** For services with auto-update (like Plex), use `exec` instead of `noexec`.

### 4.3 Volume Mount Security

```yaml
services:
  plex:
    volumes:
      # Config - read-write (required)
      - /config:/config:rw
      
      # Media - read-only (data protection)
      - /data/movies:/movies:ro
      - /data/tv:/tv:ro
```

---

## 5. Logging Limits

Prevent logging bombs that fill disk:

```yaml
services:
  example:
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

### Log Driver Options

| Driver | Best For |
|--------|----------|
| `json-file` | Local debugging, default |
| `syslog` | Central syslog server |
| `journald` | Systemd integration |
| `none` | Extreme cases only |

---

## 6. Network Isolation

### 6.1 DMZ for Public Services

```yaml
networks:
  internal:
    internal: true  # No external access
  
  dmz:
    driver: bridge  # Exposed services only

services:
  reverse-proxy:
    networks:
      - dmz
      - internal
  
  database:
    networks:
      - internal  # Never exposed
```

### 6.2 Disable ICC Where Possible

For high-security environments:

```yaml
networks:
  isolated:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
```

---

## 7. Hardening Profiles

### 7.1 Minimal Profile

For sidecars and simple utilities:

```yaml
x-minimal-hardening: &minimal-hardening
  user: "65534:65534"  # nobody
  read_only: true
  security_opt:
    - no-new-privileges:true
  cap_drop:
    - ALL
  mem_limit: 256m
  cpus: 0.5
  pids_limit: 128
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"
```

### 7.2 Standard Profile

For most application containers:

```yaml
x-standard-hardening: &standard-hardening
  user: "1000:1000"
  read_only: true
  security_opt:
    - no-new-privileges:true
  cap_drop:
    - ALL
  tmpfs:
    - /tmp:rw,noexec,nosuid,nodev,size=512m
  mem_limit: 1g
  cpus: 2
  pids_limit: 512
  logging:
    driver: json-file
    options:
      max-size: "50m"
      max-file: "5"
```

### 7.3 Hardened Profile

For public-facing containers:

```yaml
x-hardened: &hardened
  user: "1000:1000"
  read_only: true
  security_opt:
    - no-new-privileges:true
    - apparmor:docker-default
    - seccomp:default
  cap_drop:
    - ALL
  tmpfs:
    - /tmp:rw,noexec,nosuid,nodev,size=256m
  mem_limit: 512m
  cpus: 1
  pids_limit: 256
  networks:
    - dmz
  logging:
    driver: json-file
    options:
      max-size: "50m"
      max-file: "5"
```

---

## 8. Service-Specific Examples

### 8.1 Plex (Media Server)

```yaml
services:
  plex:
    image: plexinc/pms-docker:latest
    user: "1000:1000"
    tty: false
    stdin_open: false
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - NET_RAW
      - NET_ADMIN
      - SYS_ADMIN
    # Needs write for transcoding, exec for updates
    tmpfs:
      - /tmp:rw,exec,nosuid,nodev,size=2g
    mem_limit: 4g
    cpus: 4
    pids_limit: 1024
    volumes:
      - /config/plex:/config:rw
      - /data/movies:/movies:ro
      - /data/tv:/tv:ro
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

### 8.2 Reverse Proxy (Traefik)

```yaml
services:
  traefik:
    image: traefik:v3
    user: "1000:1000"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Bind 80/443
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=64m
    mem_limit: 256m
    cpus: 1
    pids_limit: 128
    networks:
      - dmz
      - internal
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "10"
```

### 8.3 Database (PostgreSQL)

```yaml
services:
  postgres:
    image: postgres:16
    user: "999:999"  # postgres user
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    # Cannot be read_only due to data dir
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=256m
    mem_limit: 2g
    cpus: 2
    pids_limit: 256
    networks:
      - internal  # Never in DMZ
    volumes:
      - postgres_data:/var/lib/postgresql/data:rw
    logging:
      driver: json-file
      options:
        max-size: "50m"
        max-file: "5"
```

---

## 9. Validation Checklist

### Pre-Deployment Checks

| Check | Command | Expected |
|-------|---------|----------|
| Non-root | `docker inspect --format '{{.Config.User}}'` | Non-empty |
| Capabilities | `docker inspect --format '{{.HostConfig.CapDrop}}'` | Contains ALL |
| Privileges | `docker inspect --format '{{.HostConfig.Privileged}}'` | false |
| Memory limit | `docker stats --no-stream` | Shows limit |

### Security Scan

```bash
# Scan image for vulnerabilities
docker scout cves <image>

# Check container config
docker inspect <container> | jq '.[] | {
  User: .Config.User,
  CapDrop: .HostConfig.CapDrop,
  CapAdd: .HostConfig.CapAdd,
  Privileged: .HostConfig.Privileged,
  ReadonlyRootfs: .HostConfig.ReadonlyRootfs,
  SecurityOpt: .HostConfig.SecurityOpt
}'
```

---

## 10. Integration with Identity

### mTLS for Container Communication

When combined with the Identity layer:

```yaml
services:
  app:
    <<: *standard-hardening
    volumes:
      # step-ca issued certificates
      - /certs/app.crt:/certs/app.crt:ro
      - /certs/app.key:/certs/app.key:ro
      - /certs/ca.crt:/certs/ca.crt:ro
    environment:
      - TLS_CERT=/certs/app.crt
      - TLS_KEY=/certs/app.key
      - TLS_CA=/certs/ca.crt
```

### SPIFFE Integration

For workload identity:

```yaml
services:
  app:
    <<: *standard-hardening
    volumes:
      # SPIFFE workload API socket
      - /run/spire/sockets:/run/spire/sockets:ro
    environment:
      - SPIFFE_ENDPOINT_SOCKET=/run/spire/sockets/agent.sock
```

---

## References

- [base/security.cue](../../../base/security.cue) - CUE schema for container security
- [Layer 1 Identity](../../layer-1-foundation/base/IDENTITY.md) - Zero-trust identity architecture
- [Docker Platform Contract](CONTRACT.md) - Platform contract
