# Modern Homelab - Simple Template

> **Status: TODO** - Template structure defined, implementation pending

This template deploys a basic modern-homelab setup with:
- 1 cloud node (VPS with public IP)
- N local nodes (on-premises, connected via VPN)

## Prerequisites

- Hetzner Cloud account (or other supported provider)
- Domain with DNS access
- SSH key pair

## Files (TODO)

- `main.tf` - Cloud node provisioning
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `docker.tf` - Docker installation
- `coolify.tf` - Coolify setup
- `headscale.tf` - VPN coordination setup

## Usage

```bash
tofu init
tofu plan -var-file=terraform.tfvars
tofu apply -var-file=terraform.tfvars
```
