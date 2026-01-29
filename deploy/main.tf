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

variable "uptime_kuma_port" {
  type        = number
  description = "Host port for Uptime Kuma service"
  default     = 3001
}

variable "uptime_kuma_enabled" {
  type        = bool
  description = "Enable Uptime Kuma service"
  default     = true
}

variable "dokploy_port" {
  type        = number
  description = "Host port for Dokploy service"
  default     = 3000
}

variable "dokploy_enabled" {
  type        = bool
  description = "Enable Dokploy service"
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

variable "docker_host" {
  type        = string
  description = "Docker daemon address"
  default     = "unix:///var/run/docker.sock"
}

provider "docker" {
  host = var.docker_host
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
# VOLUMES
# =============================================================================

resource "docker_volume" "kuma_data" {
  count = var.uptime_kuma_enabled ? 1 : 0
  name  = "kuma-data"
  
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
# UPTIME KUMA SERVICE
# =============================================================================

resource "docker_image" "uptime_kuma" {
  count = var.uptime_kuma_enabled ? 1 : 0
  name  = "louislam/uptime-kuma:1"
}

resource "docker_container" "uptime_kuma" {
  count = var.uptime_kuma_enabled ? 1 : 0
  name  = "uptime-kuma"
  image = docker_image.uptime_kuma[0].image_id
  
  restart = "unless-stopped"
  
  ports {
    internal = 3001
    external = var.uptime_kuma_port
    protocol = "tcp"
  }
  
  networks_advanced {
    name = docker_network.dev_net.name
  }
  
  volumes {
    volume_name    = docker_volume.kuma_data[0].name
    container_path = "/app/data"
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
    value = "uptime-kuma"
  }
  
  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3001/"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }
}

# =============================================================================
# DOKPOLOY VOLUMES
# =============================================================================

resource "docker_volume" "dokploy_data" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy-data"

  labels {
    label = "stackkit.managed"
    value = "true"
  }

  labels {
    label = "stackkit.name"
    value = "dev-homelab"
  }
}

resource "docker_volume" "dokploy_postgres_data" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy-postgres-data"

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
# DOKPOLOY POSTGRES DATABASE
# =============================================================================

resource "docker_image" "dokploy_postgres" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "postgres:16-alpine"
}

resource "docker_container" "dokploy_postgres" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy-postgres"
  image = docker_image.dokploy_postgres[0].image_id

  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.dokploy_postgres_data[0].name
    container_path = "/var/lib/postgresql/data"
  }

  env = [
    "POSTGRES_USER=dokploy",
    "POSTGRES_PASSWORD=dokploy",
    "POSTGRES_DB=dokploy",
  ]

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
    value = "dokploy-postgres"
  }

  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -U dokploy -d dokploy"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 5
    start_period = "10s"
  }
}

# =============================================================================
# DOKPOLOY SERVICE
# =============================================================================

resource "docker_image" "dokploy" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy/dokploy:latest"
}

resource "docker_container" "dokploy" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy"
  image = docker_image.dokploy[0].image_id

  restart = "unless-stopped"

  ports {
    internal = 3000
    external = var.dokploy_port
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.dokploy_data[0].name
    container_path = "/etc/dokploy"
  }

  # Mount docker socket for container management
  mounts {
    type   = "bind"
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
  }

  env = [
    "DOCKER_HOST=unix:///var/run/docker.sock",
    "DATABASE_URL=postgresql://dokploy:dokploy@dokploy-postgres:5432/dokploy",
    "NODE_ENV=production",
  ]

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
    value = "dokploy"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/trpc/health.live"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "60s"
  }

  depends_on = [
    docker_container.dokploy_postgres[0]
  ]
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

output "uptime_kuma_url" {
  description = "URL to access Uptime Kuma service"
  value       = var.uptime_kuma_enabled ? "http://${local.hostname}:${var.uptime_kuma_port}" : null
}

output "uptime_kuma_container_id" {
  description = "Uptime Kuma container ID"
  value       = var.uptime_kuma_enabled ? docker_container.uptime_kuma[0].id : null
}

output "dokploy_url" {
  description = "URL to access Dokploy service"
  value       = var.dokploy_enabled ? "http://${local.hostname}:${var.dokploy_port}" : null
}

output "dokploy_container_id" {
  description = "Dokploy container ID"
  value       = var.dokploy_enabled ? docker_container.dokploy[0].id : null
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
    ║  ${var.whoami_enabled ? "  ✓ whoami       → http://${local.hostname}:${var.whoami_port}" : "  ✗ whoami       (disabled)"}
    ║  ${var.uptime_kuma_enabled ? "  ✓ uptime-kuma  → http://${local.hostname}:${var.uptime_kuma_port}" : "  ✗ uptime-kuma  (disabled)"}
    ║  ${var.dokploy_enabled ? "  ✓ dokploy      → http://${local.hostname}:${var.dokploy_port}" : "  ✗ dokploy      (disabled)"}
    ║
    ║  Test Commands:
    ║    curl http://${local.hostname}:${var.whoami_port}
    ║    curl http://${local.hostname}:${var.uptime_kuma_port}
    ║    curl http://${local.hostname}:${var.dokploy_port}
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
