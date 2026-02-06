# Base Homelab Contract
A ready-to-deploy homelab stack for beginners. Deploy in under 10 minutes with a single command.

## Layer 1: Base
Inherits all definitions from base stackkit.
Provides network configuration, security defaults, and observability patterns.

## Layer 2: Platform
Docker is the container runtime.
All containers run on a single host.

## Layer 3: Services

### Network
Traefik routes traffic and handles SSL.
Ports mode works without a domain, proxy mode enables subdomains with HTTPS.

### Platform
Coolify is the PaaS when the user has their own domain.
Dokploy is the PaaS for deploying apps when no public domain is set.

### Monitoring
Uptime Kuma is preconfigured with all homelab services.
Beszel is the alternative for users who prefer metrics over uptime checks.

### Utilities
Dozzle shows container logs in a web UI.
Whoami validates that routing and SSL work correctly.

## Variant Selection
Coolify variant is selected when user provides a public domain.
Dokploy variant is selected when no domain or local domain is used.
Beszel variant is selected when user explicitly wants metrics focus.

## Success
All services start and are accessible.
User can deploy a sample app via the PaaS.
Destroy removes all containers and networks.
