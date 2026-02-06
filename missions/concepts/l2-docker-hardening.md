# Layer 2: Docker Container Hardening

**Scope:** Best practices for securing Docker containers in homelab environments. These recommendations are the basis for the [Docker Hardening Contract](../layer-2-platform/docker/HARDENING.md).

---

## Philosophy

Hardening Docker containers significantly reduces attack surface. The key principle:

> **Strong defaults, not hard limitations**

All settings can be relaxed if your use case requires it, but the defaults are secure.

---

## Quick Reference

### 1. Run as Non-Root User

```yaml
user: "1000:1000"
# Or for Unraid: user: "99:100" (nobody:users)
```

### 2. Disable TTY and Stdin

```yaml
tty: false
stdin_open: false
```

### 3. Read-Only Filesystem

```yaml
read_only: true
```

### 4. Prevent Privilege Escalation

```yaml
security_opt:
  - no-new-privileges:true
```

### 5. Drop All Capabilities

```yaml
cap_drop:
  - ALL
# Add back only what's needed:
# cap_add:
#   - NET_BIND_SERVICE
```

**Example for Plex (dropping specific dangerous caps):**

```yaml
cap_drop:
  - NET_RAW
  - NET_ADMIN
  - SYS_ADMIN
```

### 6. Secure tmpfs

```yaml
tmpfs:
  - /tmp:rw,noexec,nosuid,nodev,size=512m
```

- `noexec`: Cannot execute binaries (prevents payload execution)
- `nosuid`: Ignore SUID bits
- `nodev`: No device files
- `size=512m`: Limit size to prevent disk exhaustion

**Note:** For auto-updating software (like Plex), use `exec` instead of `noexec`.

### 7. Resource Limits

```yaml
pids_limit: 512
mem_limit: 3g
cpus: 3
```

### 8. Log Rotation

```yaml
logging:
  driver: json-file
  options:
    max-size: "50m"
    max-file: "5"
```

### 9. Read-Only Data Mounts

```yaml
volumes:
  - /mnt/data/movies:/movies:ro
  - /mnt/data/tv:/tv:ro
  - /config:/config:rw  # Only config needs write
```

### 10. Network Isolation (DMZ)

Run exposed containers in a separate DMZ network:

```yaml
networks:
  internal:
    internal: true
  dmz:
    driver: bridge

services:
  public-app:
    networks:
      - dmz
  database:
    networks:
      - internal  # Never in DMZ
```

---

## Complete Hardened Template

```yaml
x-hardened: &hardened
  user: "1000:1000"
  tty: false
  stdin_open: false
  read_only: true
  security_opt:
    - no-new-privileges:true
  cap_drop:
    - ALL
  tmpfs:
    - /tmp:rw,noexec,nosuid,nodev,size=512m
  pids_limit: 512
  mem_limit: 2g
  cpus: 2
  logging:
    driver: json-file
    options:
      max-size: "50m"
      max-file: "5"

services:
  my-app:
    <<: *hardened
    image: my-app:latest
    # Add specific overrides as needed
```

---

## Troubleshooting

When hardening breaks a container:

1. Check logs: `docker logs <container>`
2. Add capabilities back one at a time
3. Check if `read_only: true` is the issue (some apps need write access)
4. Verify the user has permission to the mounted volumes

**AI assistants (ChatGPT, Claude)** can help pinpoint the choking point.

---

## Risk Levels

| Configuration | Risk Reduction | Notes |
|--------------|----------------|-------|
| Non-root user | High | Always do this |
| no-new-privileges | High | Always do this |
| cap_drop: ALL | High | Add back only what's needed |
| read_only | Medium | Some apps need write |
| Resource limits | Medium | Prevents DoS |
| noexec tmpfs | Medium | Blocks payload execution |
| DMZ network | High | For exposed services |

---

## When Hardening Isn't Enough

For truly sensitive workloads:

1. **VM isolation**: Run in a dedicated virtual machine
2. **Separate host**: Use a dedicated physical machine
3. **Air gap**: Network isolation from main homelab

---

## Integration

These settings are codified in:

- [base/security.cue](../../base/security.cue) - `#ContainerSecurityContext` and `#DockerHardeningProfile`
- [Layer 2 Docker Contract](../layer-2-platform/docker/CONTRACT.md) - Platform contract
- [Layer 2 Docker Hardening](../layer-2-platform/docker/HARDENING.md) - Full documentation

---

## References

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)