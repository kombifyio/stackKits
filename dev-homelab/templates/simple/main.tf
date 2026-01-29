# =============================================================================
# Dev Homelab - Hybrid Architecture
# =============================================================================
# Architecture: Platform services via Terraform, Apps via Dokploy
#
# Layer 2 (PLATFORM) - Managed by Terraform:
#   ├── Traefik (reverse proxy)     - CRITICAL infrastructure
#   ├── TinyAuth (identity)         - CRITICAL for access
#   ├── Dokploy (PAAS controller)   - Manages Layer 3
#   └── Dokploy PostgreSQL          - Required by Dokploy
#
# Layer 3 (APPLICATIONS) - Managed BY Dokploy:
#   ├── Kuma (monitoring)           - Deployed via Dokploy API
#   ├── Whoami (test)               - Deployed via Dokploy API
#   └── User applications           - Deployed via Dokploy UI/API
#
# Security Principle: Critical infrastructure outside Dokploy ensures
# you can diagnose/fix Dokploy issues if it fails.
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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
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
  description = "Enable Traefik reverse proxy (Layer 2)"
  default     = true
}

variable "enable_tinyauth" {
  type        = bool
  description = "Enable TinyAuth identity proxy (Layer 1)"
  default     = true
}

variable "enable_dokploy" {
  type        = bool
  description = "Enable Dokploy PAAS (Layer 2)"
  default     = true
}

variable "enable_dokploy_apps" {
  type        = bool
  description = "Enable Dokploy-managed applications (Layer 3)"
  default     = true
}

variable "docker_host" {
  type        = string
  description = "Docker daemon address"
  default     = "tcp://vm:2375"
}

variable "tinyauth_users" {
  type        = string
  description = "TinyAuth users configuration (bcrypt hashed)"
  default     = "admin:$2a$10$N9qo8uLOickgx2ZMRZoMy.MqrI0N3p9zqNVvB6fCNCkKeTLQ9b1Vy"
}

variable "tinyauth_app_url" {
  type        = string
  description = "TinyAuth application URL"
  default     = "http://auth.stack.local"
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
# PERSISTENT VOLUMES - Organized by Layer
# =============================================================================

# Layer 1: Foundation
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

# Layer 2: Platform
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

resource "docker_volume" "dokploy_data" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy-data"
  labels {
    label = "stackkit.layer"
    value = "2-platform"
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
    value = "2-platform"
  }
  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# Layer 3: Applications (managed by Dokploy)
# These volumes are created but managed by Dokploy
resource "docker_volume" "kuma_data" {
  count = var.enable_dokploy_apps ? 1 : 0
  name  = "kuma-data"
  labels {
    label = "stackkit.layer"
    value = "3-application"
  }
  labels {
    label = "stackkit.managed-by"
    value = "dokploy"
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
# LAYER 1: FOUNDATION - TINYAUTH IDENTITY
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
    "APP_URL=${var.tinyauth_app_url}",
    "SECRET=${random_password.tinyauth_secret[0].result}",
    # Default: admin / admin123
    "USERS=${var.tinyauth_users}",
    "APP_WHITELIST=dokploy,traefik,kuma,whoami",
    "DISABLE_CONTINUE=true"
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

  # ForwardAuth middleware
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
# LAYER 2: PLATFORM - DOKPLOY DATABASE
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
    value = "2-platform"
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
# LAYER 2: PLATFORM - DOKPLOY PAAS
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
    value = "2-platform"
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
# LAYER 3: APPLICATIONS - DOKPLOY COMPOSE CONFIGS
# =============================================================================
# These are Docker Compose templates that Dokploy will use to deploy
# Layer 3 applications. They are NOT deployed by Terraform directly.

resource "local_file" "kuma_compose" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  filename = "${path.module}/.kuma-compose.yaml"
  content  = <<-EOT
    version: "3.8"
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:1
        container_name: kuma
        restart: unless-stopped
        volumes:
          - kuma-data:/app/data
        networks:
          - dokploy-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.kuma.rule=Host(`kuma.stack.local`)"
          - "traefik.http.routers.kuma.entrypoints=web"
          - "traefik.http.services.kuma.loadbalancer.server.port=3001"
          - "traefik.http.routers.kuma.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD", "wget", "-q", "--spider", "http://localhost:3001/"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s
    
    volumes:
      kuma-data:
        external: true
        name: kuma-data
    
    networks:
      dokploy-network:
        external: true
        name: dev_net
  EOT
}

resource "local_file" "whoami_compose" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  filename = "${path.module}/.whoami-compose.yaml"
  content  = <<-EOT
    version: "3.8"
    services:
      whoami:
        image: traefik/whoami:latest
        container_name: whoami
        restart: unless-stopped
        networks:
          - dokploy-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoami.rule=Host(`whoami.stack.local`)"
          - "traefik.http.routers.whoami.entrypoints=web"
          - "traefik.http.services.whoami.loadbalancer.server.port=80"
          - "traefik.http.routers.whoami.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD", "wget", "-q", "--spider", "http://localhost:80/"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 10s
    
    networks:
      dokploy-network:
        external: true
        name: dev_net
  EOT
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
  description = "Traefik dashboard URL (Layer 2 Platform)"
  value       = var.enable_traefik ? "http://${local.domains.traefik}" : null
}

output "auth_url" {
  description = "TinyAuth login URL (Layer 1 Foundation)"
  value       = var.enable_tinyauth ? "http://${local.domains.auth}" : null
}

output "dokploy_url" {
  description = "Dokploy UI URL (Layer 2 Platform)"
  value       = var.enable_dokploy ? "http://${local.domains.dokploy}" : null
}

output "kuma_url" {
  description = "Uptime Kuma URL (Layer 3 Application - deploy via Dokploy)"
  value       = var.enable_dokploy_apps ? "http://${local.domains.kuma} (deploy via Dokploy)" : null
}

output "whoami_url" {
  description = "Whoami test URL (Layer 3 Application - deploy via Dokploy)"
  value       = var.enable_dokploy_apps ? "http://${local.domains.whoami} (deploy via Dokploy)" : null
}

output "credentials" {
  description = "Default credentials"
  value       = var.enable_tinyauth ? "TinyAuth: admin / admin123" : null
  sensitive   = false
}

output "tinyauth_username" {
  description = "TinyAuth admin username"
  value       = var.enable_tinyauth ? "admin" : null
}

output "tinyauth_password" {
  description = "TinyAuth admin password"
  value       = var.enable_tinyauth ? "admin123" : null
  sensitive   = true
}

output "tinyauth_login_url" {
  description = "TinyAuth login URL"
  value       = var.enable_tinyauth ? "http://${local.domains.auth}" : null
}

output "dokploy_login_url" {
  description = "Dokploy login URL"
  value       = var.enable_dokploy ? "http://${local.domains.dokploy}" : null
}

output "architecture_summary" {
  description = "Hybrid Architecture Summary"
  value       = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║              DEV HOMELAB - VM-BASED DEPLOYMENT                     ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  ALL SERVICES RUN INSIDE THE UBUNTU VM (NOT on Windows host)      ║
    ║                                                                   ║
    ║  LAYER 1 (Foundation) - Managed by Terraform INSIDE VM:          ║
    ║    ${var.enable_tinyauth ? "✓" : "✗"} TinyAuth    → http://${local.domains.auth}           ║
    ║        Purpose: Identity & Access Control                        ║
    ║        Credentials: admin / admin123                             ║
    ║                                                                   ║
    ║  LAYER 2 (Platform) - Managed by Terraform INSIDE VM:            ║
    ║    ${var.enable_traefik ? "✓" : "✗"} Traefik     → http://${local.domains.traefik}        ║
    ║        Purpose: Reverse Proxy & Routing                          ║
    ║                                                                   ║
    ║    ${var.enable_dokploy ? "✓" : "✗"} Dokploy     → http://${local.domains.dokploy}        ║
    ║        Purpose: PAAS Controller for Layer 3                      ║
    ║        Protected by: TinyAuth SSO                                ║
    ║                                                                   ║
    ║    ${var.enable_dokploy ? "✓" : "✗"} PostgreSQL  → Internal only                     ║
    ║        Purpose: Database for Dokploy                             ║
    ║                                                                   ║
    ║  LAYER 3 (Applications) - Managed BY Dokploy:                    ║
    ║    ${var.enable_dokploy_apps ? "✓" : "✗"} Kuma     → http://${local.domains.kuma}          ║
    ║        Deploy: Via Dokploy UI/API                                ║
    ║                                                                   ║
    ║    ${var.enable_dokploy_apps ? "✓" : "✗"} Whoami   → http://${local.domains.whoami}        ║
    ║        Deploy: Via Dokploy UI/API                                ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  🔐 FIRST LOGIN FLOW                                              ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  Step 1: Login to TinyAuth                                        ║
    ║    URL: http://${local.domains.auth}                             ║
    ║    Username: admin                                                ║
    ║    Password: admin123                                             ║
    ║    ⚠️  CHANGE PASSWORD IMMEDIATELY AFTER FIRST LOGIN              ║
    ║                                                                   ║
    ║  Step 2: Access Dokploy (via TinyAuth SSO)                        ║
    ║    URL: http://${local.domains.dokploy}                          ║
    ║    You'll be redirected to TinyAuth for authentication            ║
    ║                                                                   ║
    ║  Step 3: Deploy Layer 3 Applications                              ║
    ║    Use Dokploy UI to deploy Kuma and Whoami                      ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  🔍 VERIFICATION                                                  ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  Host: docker ps                    # Should show ONLY 'vm'      ║
    ║  VM:   docker exec vm docker ps     # Should show ALL services   ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
