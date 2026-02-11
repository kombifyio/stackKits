# Docker Platform Contract

Single host container runtime. Simplest deployment model.

## Runtime
Docker Engine as container runtime.
Compose-compatible service definitions.
Direct container management.

## Orchestration
No orchestration, single host only.
Manual scaling by changing replica count.
Restart policies for basic resilience.

## Networking
Bridge network for container communication.
Port mapping for external access.
Optional overlay for future swarm migration.
DMZ network isolation for public-facing containers.

## Storage
Docker volumes for persistent data.
Bind mounts for config files.
Local storage only.
Read-only mounts for data protection where applicable.

## Discovery
Container names as DNS hostnames.
Traefik for HTTP routing.
No external service mesh.

## Security (Hardening)
Containers run as non-root by default.
All capabilities dropped, add back only what's needed.
Read-only root filesystem where possible.
Resource limits (memory, CPU, PIDs) enforced.
noexec tmpfs for /tmp to prevent payload execution.
Log rotation to prevent disk exhaustion.
mTLS for container-to-container communication (via step-ca).

## Use Case
Homelabs and personal servers.
Development environments.
Simple production for low-traffic apps.
