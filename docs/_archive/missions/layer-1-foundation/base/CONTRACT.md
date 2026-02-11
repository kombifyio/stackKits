# Base Foundation Contract

Sensible defaults for homelabs and small teams. Opinionated but overridable.

## Network
Default network with isolated subnet.
DNS resolution between containers.
Bridge networking for single-host setups.

## Security
SSH key-only authentication.
Basic firewall with deny-by-default incoming.
Secrets stored in environment variables or files.

## Identity (Zero-Trust)
Passkey-first authentication via pocketid (local).
mTLS for device trust (step-ca as certificate authority).
RBAC via lldap groups mapped to roles (owner, operator, developer, viewer).
Emergency admin access available.
All settings adjustable - password auth supported if preferred.

## Observability
Structured logging to stdout.
Health check endpoints for all services.
Basic metrics collection ready.

## Configuration
Sensible defaults for all values.
Override via spec file or environment.
Validation before apply.

## Use Case
Homelab operators who want working defaults without complex configuration.
Small teams without dedicated ops.
Professional personal projects and self-hosted infrastructure.
