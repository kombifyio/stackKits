# =============================================================================
# Dev Homelab - Minimal OpenTofu Configuration
# =============================================================================
# Purpose: E2E testing of StackKit CLI and tooling integration
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# =============================================================================
# VARIABLES
# =============================================================================

variable "advertise_host" {
  type        = string
  description = "Hostname or IP for accessing services"
  default     = ""
}

variable "network_name" {
  type        = string
  description = "Docker network name"
  default     = "dev_net"
}

variable "network_subnet" {
  type        = string
  description = "Docker network subnet"
  default     = "172.21.0.0/16"
}

variable "whoami_port" {
  type        = number
  description = "Host port for whoami service"
  default     = 9080
}

variable "whoami_enabled" {
  type        = bool
  description = "Enable whoami service"
  default     = true
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  hostname       = var.advertise_host != "" ? var.advertise_host : "${data.external.hostname.result.hostname}.local"
  timestamp      = formatdate("YYYY-MM-DD-hhmm", timestamp())
  container_name = "whoami-${local.timestamp}"
}

# =============================================================================
# DATA SOURCES
# =============================================================================

data "external" "hostname" {
  program = ["bash", "-c", "echo '{\"hostname\": \"'$(hostname)'\"}'"]
}

# =============================================================================
# DOCKER PROVIDER
# =============================================================================

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# =============================================================================
# NETWORK
# =============================================================================

resource "docker_network" "dev_net" {
  name   = var.network_name
  driver = "bridge"
  
  ipam_config {
    subnet = var.network_subnet
  }
  
  labels {
    label = "stackkit.managed"
    value = "true"
  }
  
  labels {
    label = "stackkit.name"
    value = "dev-homelab"
  }
}

# =============================================================================
# WHOAMI SERVICE
# =============================================================================

resource "docker_image" "whoami" {
  count = var.whoami_enabled ? 1 : 0
  name  = "traefik/whoami:latest"
}

resource "docker_container" "whoami" {
  count = var.whoami_enabled ? 1 : 0
  name  = "whoami"
  image = docker_image.whoami[0].image_id
  
  restart = "unless-stopped"
  
  ports {
    internal = 80
    external = var.whoami_port
    protocol = "tcp"
  }
  
  networks_advanced {
    name = docker_network.dev_net.name
  }
  
  labels {
    label = "stackkit.managed"
    value = "true"
  }
  
  labels {
    label = "stackkit.name"
    value = "dev-homelab"
  }
  
  labels {
    label = "stackkit.service"
    value = "whoami"
  }
  
  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost/"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.dev_net.id
}

output "network_name" {
  description = "Docker network name"
  value       = docker_network.dev_net.name
}

output "whoami_url" {
  description = "URL to access whoami service"
  value       = var.whoami_enabled ? "http://${local.hostname}:${var.whoami_port}" : null
}

output "whoami_container_id" {
  description = "Whoami container ID"
  value       = var.whoami_enabled ? docker_container.whoami[0].id : null
}

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                    DEV HOMELAB DEPLOYED                            ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  Network: ${docker_network.dev_net.name} (${var.network_subnet})
    ║  
    ║  Services:
    ║  ${var.whoami_enabled ? "  ✓ whoami    → http://${local.hostname}:${var.whoami_port}" : "  ✗ whoami    (disabled)"}
    ║  
    ║  Test: curl http://${local.hostname}:${var.whoami_port}
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
