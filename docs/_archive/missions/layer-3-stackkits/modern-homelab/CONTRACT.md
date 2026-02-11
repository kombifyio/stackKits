# Modern Homelab Contract

Production-ready homelab with CI/CD, GitOps, and developer workflows.

## Layers
Foundation is base.
Platform is docker.

## Network
Traefik routes traffic with automatic SSL via Let's Encrypt.
Proxy mode is default, requires a domain.

## Platform Services
Coolify is the primary PaaS with Git integration.
Gitea provides self-hosted Git repositories.
Woodpecker or Drone provides CI/CD pipelines.

## Monitoring
Uptime Kuma monitors all services and pipelines.
Grafana dashboards for metrics visualization.
Loki for centralized log aggregation.

## Utilities
Dozzle shows container logs in a web UI.
Portainer for container management.

## Development
VS Code Server for remote development.
Registry for private container images.

## Variant Selection
Full variant includes all services.
Lite variant excludes Grafana, Loki, and Registry.

## Success
All services start and are accessible.
User can push code and trigger automated deployment.
Pipelines run and deploy successfully.
Destroy removes all containers and networks.
