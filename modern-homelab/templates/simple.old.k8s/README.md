# Modern Homelab - OpenTofu Simple Templates

This directory contains OpenTofu configurations for direct execution
via KombiStack Core (without Terramate orchestration).

## Structure

```
simple/
├── main.tf           # Main entry point
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Provider requirements
├── nodes/            # Node provisioning
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k3s/              # k3s cluster setup
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── addons/           # Kubernetes addons (Helm)
    ├── traefik.tf
    ├── longhorn.tf
    ├── monitoring.tf
    └── gitops.tf
```

## Usage

```bash
# Initialize
tofu init

# Plan deployment
tofu plan -var-file="../../kombination.tfvars.json"

# Apply
tofu apply -var-file="../../kombination.tfvars.json"
```

## Variables

See `variables.tf` for all available configuration options.
The Unifier engine generates `kombination.tfvars.json` from user's `kombination.yaml`.
