# =============================================================================
# Dev Homelab - Layer 3 StackKit
# =============================================================================
# Architecture:
#   Layer 1 (Foundation): Identity & Security (base/)
#   Layer 2 (Platform):   Docker + Traefik (platforms/docker/)
#   Layer 3 (StackKit):   Applications (this file)
#
# This StackKit deploys:
#   - TinyAuth (identity proxy) - Layer 1 concern, deployed as container
#   - Dokploy (PAAS) - Layer 3 application
#   - Kuma (monitoring) - Layer 3 application
#   - Whoami (test) - Layer 3 application
#
# Platform services (Traefik) are expected to be provided by Layer 2.
# For standalone deployment, we include a minimal Traefik setup.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

variable "domain" {
  type        = string
  description = "Base domain for services"
  default     = "stack.local"
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

variable "enable_traefik" {
  type        = bool
  description = "Enable Traefik reverse proxy (Layer 2 platform service)"
  default     = true
}

variable "enable_tinyauth" {
  type        = bool
  description = "Enable TinyAuth identity proxy (Layer 1 security)"
  default     = true
}

variable "enable_dokploy" {
  type        = bool
  description = "Enable Dokploy PAAS"
  default     = true
}

variable "enable_kuma" {
  type        = bool
  description = "Enable Uptime Kuma monitoring"
  default     = true
}

variable "enable_whoami" {
  type        = bool
  description = "Enable Whoami test service"
  default     = true
}

variable "docker_host" {
  type        = string
  description = "Docker daemon address"
  default     = "unix:///var/run/docker.sock"
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  domains = {
    dokploy = "dokploy.${var.domain}"
    traefik = "traefik.${var.domain}"
    kuma    = "kuma.${var.domain}"
    whoami  = "whoami.${var.domain}"
    auth    = "auth.${var.domain}"
  }
}

# =============================================================================
# PROVIDER
# =============================================================================

provider "docker" {
  host = var.docker_host
}

# =============================================================================
# LAYER 2: PLATFORM - NETWORK
# =============================================================================

resource "docker_network" "dev_net" {
  name   = var.network_name
  driver = "bridge"

  ipam_config {
    subnet = var.network_subnet
  }

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.managed"
    value = "true"
  }
}

resource "docker_network" "internal_db" {
  name     = "${var.network_name}_db"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet = "172.21.1.0/24"
  }

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }
}

# =============================================================================
# LAYER 2: PLATFORM - PERSISTENT VOLUMES
# =============================================================================

resource "docker_volume" "traefik_data" {
  count = var.enable_traefik ? 1 : 0
  name  = "traefik-data"

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }
}

resource "docker_volume" "traefik_certs" {
  count = var.enable_traefik ? 1 : 0
  name  = "traefik-certs"

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

resource "docker_volume" "tinyauth_data" {
  count = var.enable_tinyauth ? 1 : 0
  name  = "tinyauth-data"

  labels {
    label = "stackkit.layer"
    value = "1-foundation"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

resource "docker_volume" "dokploy_data" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy-data"

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

resource "docker_volume" "dokploy_postgres_data" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy-postgres-data"

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

resource "docker_volume" "kuma_data" {
  count = var.enable_kuma ? 1 : 0
  name  = "kuma-data"

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# =============================================================================
# LAYER 2: PLATFORM - TRAEFIK REVERSE PROXY
# =============================================================================

resource "docker_image" "traefik" {
  count = var.enable_traefik ? 1 : 0
  name  = "traefik:v3.1"
}

resource "docker_container" "traefik" {
  count = var.enable_traefik ? 1 : 0
  name  = "traefik"
  image = docker_image.traefik[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
    add  = ["NET_BIND_SERVICE"]
  }

  read_only = true

  # Only Traefik exposes ports externally
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

  ports {
    internal = 8080
    external = 8080
    protocol = "tcp"
  }

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.traefik_data[0].name
    container_path = "/etc/traefik"
  }

  volumes {
    volume_name    = docker_volume.traefik_certs[0].name
    container_path = "/letsencrypt"
  }

  mounts {
    type      = "bind"
    target    = "/var/run/docker.sock"
    source    = "/var/run/docker.sock"
    read_only = true
  }

  command = [
    "--api.dashboard=true",
    "--api.insecure=true",
    "--ping=true",
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--providers.docker.network=${docker_network.dev_net.name}",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    "--certificatesresolvers.local.acme.tlschallenge=true",
    "--certificatesresolvers.local.acme.email=admin@stack.local",
    "--certificatesresolvers.local.acme.storage=/letsencrypt/acme.json",
    "--log.level=INFO",
    "--accesslog=true",
  ]

  env = ["TZ=Europe/Berlin"]

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.service"
    value = "traefik"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.traefik.rule"
    value = "Host(`${local.domains.traefik}`)"
  }

  labels {
    label = "traefik.http.routers.traefik.service"
    value = "api@internal"
  }

  labels {
    label = "traefik.http.routers.traefik.entrypoints"
    value = "web"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:8080/ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

# =============================================================================
# LAYER 1: FOUNDATION - IDENTITY (TinyAuth)
# =============================================================================

resource "random_password" "tinyauth_secret" {
  count   = var.enable_tinyauth ? 1 : 0
  length  = 32
  special = true
}

resource "docker_image" "tinyauth" {
  count = var.enable_tinyauth ? 1 : 0
  name  = "ghcr.io/steveiliop56/tinyauth:v3"
}

resource "docker_container" "tinyauth" {
  count = var.enable_tinyauth ? 1 : 0
  name  = "tinyauth"
  image = docker_image.tinyauth[0].image_id

  restart = "unless-stopped"

  user = "1000:1000"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  read_only = true

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.tinyauth_data[0].name
    container_path = "/data"
  }

  mounts {
    type   = "tmpfs"
    target = "/tmp"
    tmpfs_options {
      mode       = 1777
      size_bytes = 67108864
    }
  }

  env = [
    "TZ=Europe/Berlin",
    "APP_URL=http://${local.domains.auth}",
    "SECRET=${random_password.tinyauth_secret[0].result}",
    # Default user: admin / admin123 (bcrypt hash)
    "USERS=admin:$2a$10$N9qo8uLOickgx2ZMRZoMy.MqrI0N3p9zqNVvB6fCNCkKeTLQ9b1Vy",
    "APP_WHITELIST=dokploy,traefik,kuma,whoami",
    "LOG_LEVEL=info"
  ]

  labels {
    label = "stackkit.layer"
    value = "1-foundation"
  }

  labels {
    label = "stackkit.service"
    value = "tinyauth"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.tinyauth.rule"
    value = "Host(`${local.domains.auth}`)"
  }

  labels {
    label = "traefik.http.routers.tinyauth.entrypoints"
    value = "web"
  }

  labels {
    label = "traefik.http.services.tinyauth.loadbalancer.server.port"
    value = "3000"
  }

  # ForwardAuth middleware for protecting other services
  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.address"
    value = "http://tinyauth:3000/api/auth/verify"
  }

  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders"
    value = "X-User,X-Email"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/health"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [docker_container.traefik]
}

# =============================================================================
# LAYER 3: STACKKIT - DATABASE
# =============================================================================

resource "random_password" "dokploy_db_password" {
  count   = var.enable_dokploy ? 1 : 0
  length  = 32
  special = false
}

resource "docker_image" "dokploy_postgres" {
  count = var.enable_dokploy ? 1 : 0
  name  = "postgres:16-alpine"
}

resource "docker_container" "dokploy_postgres" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy-postgres"
  image = docker_image.dokploy_postgres[0].image_id

  restart = "unless-stopped"

  user = "999:999"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  networks_advanced {
    name = docker_network.internal_db.name
  }

  volumes {
    volume_name    = docker_volume.dokploy_postgres_data[0].name
    container_path = "/var/lib/postgresql/data"
  }

  mounts {
    type   = "tmpfs"
    target = "/tmp"
    tmpfs_options {
      mode       = 1777
      size_bytes = 268435456
    }
  }

  env = [
    "POSTGRES_USER=dokploy",
    "POSTGRES_PASSWORD=${random_password.dokploy_db_password[0].result}",
    "POSTGRES_DB=dokploy",
    "PGDATA=/var/lib/postgresql/data/pgdata"
  ]

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
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
# LAYER 3: STACKKIT - DOKPLOY PAAS
# =============================================================================

resource "docker_image" "dokploy" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy/dokploy:latest"
}

resource "docker_container" "dokploy" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy"
  image = docker_image.dokploy[0].image_id

  restart = "unless-stopped"

  user = "0:0"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
    add  = ["CHOWN", "SETGID", "SETUID"]
  }

  networks_advanced {
    name = docker_network.dev_net.name
  }

  networks_advanced {
    name = docker_network.internal_db.name
  }

  volumes {
    volume_name    = docker_volume.dokploy_data[0].name
    container_path = "/etc/dokploy"
  }

  mounts {
    type   = "bind"
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
  }

  env = [
    "DOCKER_HOST=unix:///var/run/docker.sock",
    "DATABASE_URL=postgresql://dokploy:${random_password.dokploy_db_password[0].result}@dokploy-postgres:5432/dokploy",
    "NODE_ENV=production",
    "PORT=3000",
    "TRPC_PLAYGROUND=false",
    "LETSENCRYPT_EMAIL=admin@stack.local",
    "TRAEFIK_ENABLED=true",
    "TRAEFIK_NETWORK=${docker_network.dev_net.name}",
  ]

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.service"
    value = "dokploy"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.dokploy.rule"
    value = "Host(`${local.domains.dokploy}`)"
  }

  labels {
    label = "traefik.http.routers.dokploy.entrypoints"
    value = "web"
  }

  labels {
    label = "traefik.http.routers.dokploy.service"
    value = "dokploy"
  }

  labels {
    label = "traefik.http.routers.dokploy.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  labels {
    label = "traefik.http.services.dokploy.loadbalancer.server.port"
    value = "3000"
  }

  # Health check - check web interface
  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/settings"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 5
    start_period = "60s"
  }

  depends_on = [
    docker_container.dokploy_postgres,
    docker_container.traefik
  ]
}

# =============================================================================
# LAYER 3: STACKKIT - KUMA MONITORING
# =============================================================================

resource "docker_image" "kuma" {
  count = var.enable_kuma ? 1 : 0
  name  = "louislam/uptime-kuma:1"
}

resource "docker_container" "kuma" {
  count = var.enable_kuma ? 1 : 0
  name  = "kuma"
  image = docker_image.kuma[0].image_id

  restart = "unless-stopped"

  user = "0:0"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.kuma_data[0].name
    container_path = "/app/data"
  }

  env = ["TZ=Europe/Berlin"]

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.service"
    value = "kuma"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.kuma.rule"
    value = "Host(`${local.domains.kuma}`)"
  }

  labels {
    label = "traefik.http.routers.kuma.entrypoints"
    value = "web"
  }

  labels {
    label = "traefik.http.routers.kuma.service"
    value = "kuma"
  }

  labels {
    label = "traefik.http.routers.kuma.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  labels {
    label = "traefik.http.services.kuma.loadbalancer.server.port"
    value = "3001"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3001/"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "30s"
  }

  depends_on = [docker_container.traefik]
}

# =============================================================================
# LAYER 3: STACKKIT - WHOAMI TEST SERVICE
# =============================================================================

resource "docker_image" "whoami" {
  count = var.enable_whoami ? 1 : 0
  name  = "traefik/whoami:latest"
}

resource "docker_container" "whoami" {
  count = var.enable_whoami ? 1 : 0
  name  = "whoami"
  image = docker_image.whoami[0].image_id

  restart = "unless-stopped"

  user = "1000:1000"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  networks_advanced {
    name = docker_network.dev_net.name
  }

  env = ["TZ=Europe/Berlin"]

  labels {
    label = "stackkit.layer"
    value = "3-stackkit"
  }

  labels {
    label = "stackkit.service"
    value = "whoami"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.whoami.rule"
    value = "Host(`${local.domains.whoami}`)"
  }

  labels {
    label = "traefik.http.routers.whoami.entrypoints"
    value = "web"
  }

  labels {
    label = "traefik.http.routers.whoami.service"
    value = "whoami"
  }

  labels {
    label = "traefik.http.routers.whoami.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  labels {
    label = "traefik.http.services.whoami.loadbalancer.server.port"
    value = "80"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:80/"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [docker_container.traefik]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "network_name" {
  description = "Docker network name"
  value       = docker_network.dev_net.name
}

output "domains" {
  description = "Service domain mappings"
  value       = local.domains
}

output "traefik_url" {
  description = "Traefik dashboard URL"
  value       = var.enable_traefik ? "http://${local.domains.traefik}" : null
}

output "auth_url" {
  description = "TinyAuth login URL"
  value       = var.enable_tinyauth ? "http://${local.domains.auth}" : null
}

output "dokploy_url" {
  description = "Dokploy UI URL"
  value       = var.enable_dokploy ? "http://${local.domains.dokploy}" : null
}

output "kuma_url" {
  description = "Uptime Kuma URL"
  value       = var.enable_kuma ? "http://${local.domains.kuma}" : null
}

output "whoami_url" {
  description = "Whoami test URL"
  value       = var.enable_whoami ? "http://${local.domains.whoami}" : null
}

output "tinyauth_credentials" {
  description = "TinyAuth default credentials"
  value       = var.enable_tinyauth ? "admin / admin123" : null
}

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value       = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║              DEV HOMELAB - 3-LAYER ARCHITECTURE                    ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  Layer 1 (Foundation): Identity & Security                        ║
    ║    ${var.enable_tinyauth ? "✓ tinyauth" : "✗ tinyauth"} - http://${local.domains.auth}
    ║
    ║  Layer 2 (Platform): Docker + Traefik                             ║
    ║    ${var.enable_traefik ? "✓ traefik" : "✗ traefik"} - http://${local.domains.traefik}
    ║
    ║  Layer 3 (StackKit): Applications                                 ║
    ║    ${var.enable_dokploy ? "✓ dokploy" : "✗ dokploy"} - http://${local.domains.dokploy}
    ║    ${var.enable_kuma ? "✓ kuma" : "✗ kuma"} - http://${local.domains.kuma}
    ║    ${var.enable_whoami ? "✓ whoami" : "✗ whoami"} - http://${local.domains.whoami}
    ║
    ║  🔐 Security: ${var.enable_tinyauth ? "Enabled (admin/admin123)" : "Disabled"}
    ║  🌐 Routing: All services via Traefik on port 80
    ║
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
