# StackKits Networking Standards (Local-First)

This document defines the **global networking standard** for StackKits.

The goal is strict:
- **Everything must work immediately** after deployment.
- **Domains are never a prerequisite.**
- There must always be an **always-valid fallback** that works in real networks.

## Core Principles

### 1) “Always Works” Addressing (in priority order)

Every StackKit must provide links/outputs for these access methods:

1. **Direct IP + port** (most universal)
   - Example: `http://192.168.1.10:3000`
   - Works on any LAN, regardless of DNS/mDNS.

2. **mDNS host identity**: `HOSTNAME.local` + port (zero-config convenience)
   - Example: `http://homelab.local:3000`
   - This is a convenience, not a dependency. Clients may need mDNS enabled.

3. **Optional domain-based hostnames** (only when the user provides a real domain)
   - Example: `https://deploy.example.com`

**Never rely on** `service.HOSTNAME.local` (subdomains under `.local`).
- `.local` is typically **mDNS host identity**, not a DNS zone.
- Subdomains under `.local` are not reliably resolvable without extra infrastructure.

### 2) Ports-First Is Not “localhost”

Ports-first means:
- Services publish ports on a LAN bind address (usually `0.0.0.0`).
- Links point to either `HOSTNAME.local:<port>` or `<server-ip>:<port>`.

**localhost/127.0.0.1 must never be the default access story** because it fails for all remote clients.

### 3) Optional Proxy/TLS (Upgrade Path)

A reverse proxy (e.g., Traefik) is allowed and recommended for:
- Clean hostnames
- Optional TLS
- Central auth/middleware

But it must be:
- **Optional**
- **Non-breaking**: direct port access must still work.

Let’s Encrypt/ACME is optional and must only be enabled when:
- A real domain is provided
- DNS resolves to the host
- Ports 80/443 are reachable as required

## Base Homelab Standard (Reference)

### Required outputs
Base Homelab must always output:
- `advertised_host` (defaults to `HOSTNAME.local`, override to IP/hostname)
- Service URLs in **direct-port form**

### Recommended default port allocations (stable)
These defaults should be stable across releases (changing them is a breaking UX change):
- Traefik dashboard: `8080`
- Dokploy: `3000`
- Uptime Kuma: `3001`
- Beszel: `8090`
- Dozzle: `8888`
- Whoami: `9080`
- Dockge: `5001`
- Portainer: `9000`
- Netdata: `19999`

### Parameters for robustness
Every StackKit should expose two knobs:
- `bind_address`: where ports listen (default `0.0.0.0`)
- `advertise_host`: what host/IP is used in printed links (default `HOSTNAME.local`)

This avoids “it works on my machine” outputs and handles networks without mDNS.

## Network Profiles (Use-Case Driven)

### Profile A: Simple LAN (zero-config)
- Access: `HOSTNAME.local:<port>` and `<server-ip>:<port>`
- DNS: none
- TLS: optional; typically not required

### Profile B: LAN with internal DNS (recommended improvement)
If users want clean hostnames without public domains:
- Run internal DNS (router DNS, dnsmasq, AdGuard Home, Pi-hole, CoreDNS)
- Use a DNS-safe internal zone (recommended: `home.arpa`)
- Then services can have reliable hostnames like `deploy.home.arpa`

### Profile C: Public domain
- DNS: public
- TLS: Let’s Encrypt
- Still keep direct ports available for “always works”

## What “Robust” Means for StackKits

A StackKit is robust if:
- A user can always reach services by IP:port
- mDNS improves ergonomics but isn’t required
- Proxy/TLS is an upgrade, not a dependency
- Documentation and outputs never claim localhost is sufficient for real usage
