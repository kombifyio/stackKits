# Template Reference

> **Version:** 1.0  
> **Status:** Production Ready

This document provides a comprehensive reference for creating OpenTofu templates within StackKits.

## Overview

StackKits use OpenTofu (Terraform-compatible) templates to provision infrastructure. Templates are organized into two modes:

- **Simple Mode:** Single `main.tf` file for standalone deployments
- **Advanced Mode:** Terramate-orchestrated stacks for complex multi-node setups

## Directory Structure

```
templates/
├── simple/
│   ├── main.tf              # Main configuration
│   ├── variables.tf         # Input variables (optional, can be in main.tf)
│   ├── outputs.tf           # Output definitions (optional)
│   └── terraform.tfvars.example
└── advanced/
    ├── terramate.tm.hcl     # Terramate configuration
    └── stacks/
        ├── bootstrap/       # OS preparation
        ├── network/         # Network setup
        └── services/        # Container services
```

## Provider Configuration

### Required Providers

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Docker container management
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }

    # Remote execution for bootstrap
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

    # Local file generation
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
```

### Optional Providers

```hcl
# For public domain deployments
cloudflare = {
  source  = "cloudflare/cloudflare"
  version = "~> 4.0"
}

# For TLS certificate management
acme = {
  source  = "vancluever/acme"
  version = "~> 2.0"
}

# For secret management
random = {
  source  = "hashicorp/random"
  version = "~> 3.0"
}
```

## Variable Patterns

### Standard Variables

Every StackKit should define these core variables:

```hcl
# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "domain" {
  description = "Primary domain for the homelab"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+[a-z0-9]$", var.domain))
    error_message = "Domain must be a valid DNS name."
  }
}

variable "acme_email" {
  description = "Email for ACME/Let's Encrypt certificates"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.acme_email))
    error_message = "Must be a valid email address."
  }
}

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================

variable "variant" {
  description = "Service variant: default, beszel, or minimal"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "beszel", "minimal"], var.variant)
    error_message = "Variant must be 'default', 'beszel', or 'minimal'."
  }
}

variable "compute_tier" {
  description = "Compute tier: high, standard, or low"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["high", "standard", "low"], var.compute_tier)
    error_message = "Compute tier must be 'high', 'standard', or 'low'."
  }
}

variable "timezone" {
  description = "Server timezone (IANA format)"
  type        = string
  default     = "UTC"
}

variable "data_dir" {
  description = "Root directory for application data"
  type        = string
  default     = "/opt/homelab"
}
```

### Sensitive Variables

```hcl
variable "admin_password" {
  description = "Admin password for services"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "Password must be at least 12 characters."
  }
}

variable "ssh_private_key" {
  description = "SSH private key for remote execution"
  type        = string
  sensitive   = true
  default     = ""
}
```

## Resource Patterns

### Docker Network

```hcl
resource "docker_network" "homelab" {
  name   = "homelab-network"
  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }

  labels {
    label = "managed-by"
    value = "stackkit"
  }
}
```

### Docker Image

```hcl
resource "docker_image" "traefik" {
  name         = "traefik:v3.1"
  keep_locally = true

  # Force pull on version change
  pull_triggers = [
    "traefik:v3.1"
  ]
}
```

### Docker Volume

```hcl
resource "docker_volume" "traefik_certs" {
  name = "traefik-certs"

  labels {
    label = "managed-by"
    value = "stackkit"
  }

  labels {
    label = "backup"
    value = "true"
  }
}
```

### Docker Container

```hcl
resource "docker_container" "traefik" {
  name  = "traefik"
  image = docker_image.traefik.image_id

  restart = "unless-stopped"

  # Network
  networks_advanced {
    name         = docker_network.homelab.name
    ipv4_address = "172.20.0.2"
  }

  # Ports
  ports {
    internal = 80
    external = 80
    protocol = "tcp"
  }

  ports {
    internal = 443
    external = 443
    protocol = "tcp"
  }

  # Volumes
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.traefik_certs.name
    container_path = "/certs"
  }

  # Environment
  env = [
    "TRAEFIK_LOG_LEVEL=INFO",
    "TRAEFIK_API_DASHBOARD=true",
  ]

  # Command
  command = [
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
  ]

  # Labels
  labels {
    label = "managed-by"
    value = "stackkit"
  }

  labels {
    label = "stackkit"
    value = "base-homelab"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  # Health check
  healthcheck {
    test         = ["CMD", "traefik", "healthcheck", "--ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  # Resource limits
  memory = local.resource_limits.traefik.memory
  cpu_shares = local.resource_limits.traefik.cpu_shares

  # Lifecycle
  lifecycle {
    create_before_destroy = true
  }
}
```

### Conditional Resources

```hcl
# Only create if variant requires it
resource "docker_container" "uptime_kuma" {
  count = local.is_default ? 1 : 0

  name  = "uptime-kuma"
  image = docker_image.uptime_kuma[0].image_id
  # ...
}

# Reference conditional resources
output "uptime_kuma_url" {
  value = local.is_default ? "https://status.${var.domain}" : "disabled"
}
```

## Local Values

Use locals for computed values and DRY principles:

```hcl
locals {
  # Variant flags
  is_default  = var.variant == "default"
  is_beszel   = var.variant == "beszel"
  is_minimal  = var.variant == "minimal"

  # Service URLs
  urls = {
    traefik   = "traefik.${var.domain}"
    deploy    = "deploy.${var.domain}"
    status    = "status.${var.domain}"
    monitor   = "monitor.${var.domain}"
  }

  # Resource limits by tier
  resource_limits = {
    traefik = lookup({
      high     = { memory = 536870912, cpu_shares = 1024 }  # 512MB, 1 CPU
      standard = { memory = 268435456, cpu_shares = 512 }   # 256MB, 0.5 CPU
      low      = { memory = 134217728, cpu_shares = 256 }   # 128MB, 0.25 CPU
    }, var.compute_tier)

    platform = lookup({
      high     = { memory = 2147483648, cpu_shares = 2048 }  # 2GB, 2 CPU
      standard = { memory = 536870912, cpu_shares = 1024 }   # 512MB, 1 CPU
      low      = { memory = 268435456, cpu_shares = 512 }    # 256MB, 0.5 CPU
    }, var.compute_tier)
  }

  # Common labels
  common_labels = {
    "managed-by" = "stackkit"
    "stackkit"   = "base-homelab"
    "variant"    = var.variant
  }
}
```

## Bootstrap Pattern

For OS-level preparation using `null_resource`:

```hcl
# Bootstrap script
resource "null_resource" "bootstrap" {
  # Re-run if script changes
  triggers = {
    script_hash = filesha256("${path.module}/scripts/bootstrap.sh")
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = var.ssh_private_key
  }

  # Copy bootstrap script
  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/tmp/bootstrap.sh"
  }

  # Execute bootstrap
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "sudo /tmp/bootstrap.sh",
    ]
  }
}

# Docker depends on bootstrap
resource "docker_network" "homelab" {
  depends_on = [null_resource.bootstrap]
  # ...
}
```

## Output Patterns

### Service URLs

```hcl
output "service_urls" {
  description = "URLs for all deployed services"
  value = {
    traefik = "https://${local.urls.traefik}"
    deploy  = local.use_dokploy ? "https://${local.urls.deploy}" : null
    status  = local.is_default ? "https://${local.urls.status}" : null
  }
}
```

### Credentials

```hcl
output "credentials" {
  description = "Service credentials (sensitive)"
  sensitive   = true
  value = {
    admin_password = random_password.admin.result
  }
}
```

### Deployment Info

```hcl
output "deployment_info" {
  description = "Deployment metadata"
  value = {
    stackkit     = "base-homelab"
    variant      = var.variant
    compute_tier = var.compute_tier
    deployed_at  = timestamp()
    services     = [for c in docker_container.all : c.name]
  }
}
```

## Terramate Integration (Advanced Mode)

### Stack Configuration

```hcl
# terramate.tm.hcl
terramate {
  required_version = ">= 0.6.0"
}

stack {
  name        = "base-homelab"
  description = "Base Homelab StackKit"
  id          = "base-homelab-main"
}

globals {
  domain       = "homelab.local"
  variant      = "default"
  compute_tier = "standard"
}
```

### Stack Ordering

```hcl
# stacks/bootstrap/terramate.tm.hcl
stack {
  name = "bootstrap"
  after = []  # Runs first
}

# stacks/network/terramate.tm.hcl
stack {
  name  = "network"
  after = ["bootstrap"]
}

# stacks/services/terramate.tm.hcl
stack {
  name  = "services"
  after = ["network"]
}
```

### Shared Code Generation

```hcl
# terramate.tm.hcl
generate_hcl "_generated_provider.tf" {
  content {
    terraform {
      required_providers {
        docker = {
          source  = "kreuzwerker/docker"
          version = "~> 3.0"
        }
      }
    }

    provider "docker" {}
  }
}

generate_hcl "_generated_variables.tf" {
  content {
    variable "domain" {
      type    = string
      default = global.domain
    }
  }
}
```

## Best Practices

### 1. Idempotency

Always design templates to be safely re-applied:

```hcl
# Good: Uses create_before_destroy
lifecycle {
  create_before_destroy = true
}

# Good: Uses count for optional resources
count = var.enable_feature ? 1 : 0

# Avoid: Inline commands that aren't idempotent
# provisioner "local-exec" { command = "rm -rf /data" }  # BAD
```

### 2. Error Handling

```hcl
# Use validation blocks
variable "port" {
  type = number
  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

# Use preconditions
resource "docker_container" "app" {
  lifecycle {
    precondition {
      condition     = docker_image.app.id != ""
      error_message = "Image must be pulled before container creation."
    }
  }
}
```

### 3. Documentation

```hcl
# Document all variables
variable "domain" {
  description = <<-EOT
    Primary domain for the homelab.
    
    This domain will be used for:
    - Service subdomains (e.g., traefik.domain.com)
    - SSL certificate generation
    - Traefik routing rules
    
    Example: "homelab.example.com"
  EOT
  type = string
}
```

### 4. Security

```hcl
# Mark sensitive values
variable "api_key" {
  type      = string
  sensitive = true
}

output "credentials" {
  value     = { api_key = var.api_key }
  sensitive = true
}

# Avoid hardcoding secrets
# BAD: password = "admin123"
# GOOD: password = random_password.admin.result
```

### 5. State Management

```hcl
# Configure remote state for production
terraform {
  backend "s3" {
    bucket = "my-tf-state"
    key    = "stackkits/base-homelab/terraform.tfstate"
    region = "us-east-1"
  }
}

# Or local for development
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

## Template Debugging

### Validate Syntax

```bash
tofu validate
```

### Preview Changes

```bash
tofu plan -out=plan.tfplan
```

### Inspect State

```bash
tofu state list
tofu state show docker_container.traefik
```

### Debug Logging

```bash
TF_LOG=DEBUG tofu apply
```

## Next Steps

- [Creating StackKits](creating-stackkits.md) - Full StackKit guide
- [Variant System](variants.md) - OS and compute variants
- [CLI Reference](cli-reference.md) - Command-line usage
