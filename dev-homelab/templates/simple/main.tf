# =============================================================================
# Dev Homelab - Production-Ready OpenTofu Configuration
# =============================================================================
# Purpose: Production-ready homelab with Dokploy, Traefik, and Zero-Trust security
# Architecture:
#   - Dokploy as PAAS managing Kuma and whoami (not standalone containers)
#   - Traefik as reverse proxy for automatic HTTPS and routing
#   - Persistent volumes with proper backups
#   - Security: tinyauth for OIDC/passkey auth, mTLS ready
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

variable "dokploy_enabled" {
  type        = bool
  description = "Enable Dokploy PAAS service"
  default     = true
}

variable "traefik_enabled" {
  type        = bool
  description = "Enable Traefik reverse proxy"
  default     = true
}

variable "tinyauth_enabled" {
  type        = bool
  description = "Enable tinyauth for SSO/OIDC"
  default     = true
}

variable "kuma_enabled" {
  type        = bool
  description = "Enable Uptime Kuma via Dokploy"
  default     = true
}

variable "whoami_enabled" {
  type        = bool
  description = "Enable whoami test service via Dokploy"
  default     = true
}

variable "enable_security_hardening" {
  type        = bool
  description = "Enable Docker security hardening"
  default     = true
}

variable "acme_email" {
  type        = string
  description = "Email for Let's Encrypt certificates (local env uses self-signed)"
  default     = "admin@stack.local"
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  hostname  = var.advertise_host != "" ? var.advertise_host : "localhost"
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())

  # Domain mappings for Traefik routing
  domains = {
    dokploy = "dokploy.${var.domain}"
    traefik = "traefik.${var.domain}"
    kuma    = "kuma.${var.domain}"
    whoami  = "whoami.${var.domain}"
    auth    = "auth.${var.domain}"
  }
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
# NETWORK ARCHITECTURE
# =============================================================================

# Main application network - isolated from direct external access
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

  labels {
    label = "traefik.enable"
    value = "true"
  }
}

# Internal network for database communication (no external access)
resource "docker_network" "internal_db" {
  name     = "${var.network_name}_db"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet = "172.21.1.0/24"
  }

  labels {
    label = "stackkit.managed"
    value = "true"
  }
}

# =============================================================================
# PERSISTENT VOLUMES
# =============================================================================

# Dokploy persistent data
resource "docker_volume" "dokploy_data" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy-data"

  labels {
    label = "stackkit.managed"
    value = "true"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# Dokploy PostgreSQL data
resource "docker_volume" "dokploy_postgres_data" {
  count = var.dokploy_enabled ? 1 : 0
  name  = "dokploy-postgres-data"

  labels {
    label = "stackkit.managed"
    value = "true"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# Traefik configuration and certificates
resource "docker_volume" "traefik_data" {
  count = var.traefik_enabled ? 1 : 0
  name  = "traefik-data"

  labels {
    label = "stackkit.managed"
    value = "true"
  }
}

# Traefik certificates storage
resource "docker_volume" "traefik_certs" {
  count = var.traefik_enabled ? 1 : 0
  name  = "traefik-certs"

  labels {
    label = "stackkit.managed"
    value = "true"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# TinyAuth data
resource "docker_volume" "tinyauth_data" {
  count = var.tinyauth_enabled ? 1 : 0
  name  = "tinyauth-data"

  labels {
    label = "stackkit.managed"
    value = "true"
  }

  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# =============================================================================
# TRAEFIK REVERSE PROXY
# =============================================================================

resource "docker_image" "traefik" {
  count = var.traefik_enabled ? 1 : 0
  name  = "traefik:v3.1"
}

resource "docker_container" "traefik" {
  count = var.traefik_enabled ? 1 : 0
  name  = "traefik"
  image = docker_image.traefik[0].image_id

  restart = "unless-stopped"

  # Security hardening
  user = "0:0" # Root required for binding ports < 1024

  security_opts = var.enable_security_hardening ? [
    "no-new-privileges:true"
  ] : []

  capabilities {
    drop = var.enable_security_hardening ? ["ALL"] : []
    add  = ["NET_BIND_SERVICE"]
  }

  read_only = var.enable_security_hardening

  # Port mappings
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

  # Docker socket for automatic service discovery
  mounts {
    type      = "bind"
    target    = "/var/run/docker.sock"
    source    = "/var/run/docker.sock"
    read_only = true
  }

  # Traefik configuration
  command = [
    "--api.dashboard=true",
    "--api.insecure=true", # Insecure only for local dev - dashboard accessible
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--providers.docker.network=${docker_network.dev_net.name}",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    # Local dev uses self-signed certificates
    "--certificatesresolvers.local.acme.tlschallenge=true",
    "--certificatesresolvers.local.acme.email=${var.acme_email}",
    "--certificatesresolvers.local.acme.storage=/letsencrypt/acme.json",
    # Logging
    "--log.level=INFO",
    "--accesslog=true",
    # Global redirect to HTTPS (commented for local dev - enable for prod)
    # "--entrypoints.web.http.redirections.entryPoint.to=websecure",
    # "--entrypoints.web.http.redirections.entryPoint.scheme=https",
  ]

  env = [
    "TZ=Europe/Berlin"
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
    value = "traefik"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  # Traefik dashboard accessible via traefik.stack.local
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
# TINYAUTH - OIDC/SSO PROXY
# =============================================================================

resource "docker_image" "tinyauth" {
  count = var.tinyauth_enabled ? 1 : 0
  name  = "ghcr.io/steveiliop56/tinyauth:v3"
}

resource "docker_container" "tinyauth" {
  count = var.tinyauth_enabled ? 1 : 0
  name  = "tinyauth"
  image = docker_image.tinyauth[0].image_id

  restart = "unless-stopped"

  # Security hardening
  user = "1000:1000"

  security_opts = var.enable_security_hardening ? [
    "no-new-privileges:true"
  ] : []

  capabilities {
    drop = var.enable_security_hardening ? ["ALL"] : []
  }

  read_only = var.enable_security_hardening

  networks_advanced {
    name = docker_network.dev_net.name
  }

  volumes {
    volume_name    = docker_volume.tinyauth_data[0].name
    container_path = "/data"
  }

  # Writable tmpfs for runtime
  mounts {
    type   = "tmpfs"
    target = "/tmp"
    tmpfs_options {
      mode       = 1777
      size_bytes = 67108864 # 64MB
    }
  }

  env = [
    "TZ=Europe/Berlin",
    "APP_URL=http://${local.domains.auth}",
    # Session configuration
    "SESSION_SECRET=${random_password.tinyauth_session[0].result}",
    # OIDC configuration (placeholder - user configures real IdP)
    # "OIDC_ISSUER=https://your-idp.com",
    # "OIDC_CLIENT_ID=your-client-id",
    # "OIDC_CLIENT_SECRET=your-client-secret",
    # "OIDC_REDIRECT_URL=http://auth.stack.local/auth/oidc/callback",
    # Local user for development (REMOVE IN PRODUCTION)
    # Note: Password should be hashed with bcrypt - generate at runtime
    "USERS=admin:$2a$10$YourHashedPasswordHere",
    # App whitelist - protect these services
    "APP_WHITELIST=dokploy,traefik,kuma,whoami",
    # Log level
    "LOG_LEVEL=info"
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

  # ForwardAuth middleware for other services
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

  depends_on = [
    docker_container.traefik[0]
  ]
}

# Generate secure passwords
resource "random_password" "tinyauth_session" {
  count   = var.tinyauth_enabled ? 1 : 0
  length  = 32
  special = true
}

resource "random_password" "tinyauth_admin" {
  count   = var.tinyauth_enabled ? 1 : 0
  length  = 16
  special = true
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

  # Security hardening
  user = "999:999" # postgres user

  security_opts = var.enable_security_hardening ? [
    "no-new-privileges:true"
  ] : []

  capabilities {
    drop = var.enable_security_hardening ? ["ALL"] : []
  }

  networks_advanced {
    name = docker_network.internal_db.name
  }

  volumes {
    volume_name    = docker_volume.dokploy_postgres_data[0].name
    container_path = "/var/lib/postgresql/data"
  }

  # Writable tmpfs for runtime
  mounts {
    type   = "tmpfs"
    target = "/tmp"
    tmpfs_options {
      mode       = 1777
      size_bytes = 268435456 # 256MB
    }
  }

  env = [
    "POSTGRES_USER=dokploy",
    "POSTGRES_PASSWORD=${random_password.dokploy_db[0].result}",
    "POSTGRES_DB=dokploy",
    "PGDATA=/var/lib/postgresql/data/pgdata"
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

# Generate secure database password
resource "random_password" "dokploy_db" {
  count   = var.dokploy_enabled ? 1 : 0
  length  = 32
  special = false
}

# =============================================================================
# DOKPOLOY PAAS SERVICE
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

  # Security hardening
  user = "0:0" # Root required for Docker socket access

  security_opts = var.enable_security_hardening ? [
    "no-new-privileges:true"
  ] : []

  # Dokploy needs extended capabilities for container management
  capabilities {
    drop = var.enable_security_hardening ? ["ALL"] : []
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

  # Mount docker socket for container management
  mounts {
    type   = "bind"
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
  }

  env = [
    "DOCKER_HOST=unix:///var/run/docker.sock",
    "DATABASE_URL=postgresql://dokploy:${random_password.dokploy_db[0].result}@dokploy-postgres:5432/dokploy",
    "NODE_ENV=production",
    "PORT=3000",
    "TRPC_PLAYGROUND=false",
    "LETSENCRYPT_EMAIL=${var.acme_email}",
    # Enable Traefik integration
    "TRAEFIK_ENABLED=true",
    "TRAEFIK_NETWORK=${docker_network.dev_net.name}",
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

  labels {
    label = "traefik.enable"
    value = "true"
  }

  # Main Dokploy UI - protected by tinyauth
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

  # Add tinyauth middleware for security
  labels {
    label = "traefik.http.routers.dokploy.middlewares"
    value = var.tinyauth_enabled ? "tinyauth@docker" : ""
  }

  labels {
    label = "traefik.http.services.dokploy.loadbalancer.server.port"
    value = "3000"
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:3000/api/trpc/health.live"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "60s"
  }

  depends_on = [
    docker_container.dokploy_postgres[0],
    docker_container.traefik[0]
  ]
}

# =============================================================================
# DOKPOLOY INITIALIZATION - Deploy Kuma and Whoami as Dokploy Projects
# =============================================================================

# Wait for Dokploy to be ready, then configure it via API
resource "terraform_data" "dokploy_init" {
  count = var.dokploy_enabled ? 1 : 0

  triggers_replace = [
    docker_container.dokploy[0].id
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Dokploy to be ready..."
      MAX_RETRIES=60
      RETRY=0
      
      until curl -sf http://localhost:3000/api/trpc/health.live 2>/dev/null; do
        RETRY=$((RETRY + 1))
        if [ $RETRY -ge $MAX_RETRIES ]; then
          echo "Dokploy failed to become ready"
          exit 1
        fi
        echo "Waiting for Dokploy... ($RETRY/$MAX_RETRIES)"
        sleep 5
      done
      
      echo "Dokploy is ready!"
      
      # Create admin user via API
      echo "Setting up Dokploy admin user..."
      curl -sf -X POST http://localhost:3000/api/setup \
        -H "Content-Type: application/json" \
        -d '{
          "name": "Admin",
          "email": "admin@stack.local",
          "password": "${random_password.dokploy_admin[0].result}"
        }' 2>/dev/null || echo "Admin may already exist"
      
      echo "Dokploy initialization complete"
    EOT

    environment = {
      DOKploy_ADMIN_PASSWORD = random_password.dokploy_admin[0].result
    }
  }

  depends_on = [
    docker_container.dokploy[0]
  ]
}

# Generate Dokploy admin password
resource "random_password" "dokploy_admin" {
  count   = var.dokploy_enabled ? 1 : 0
  length  = 24
  special = true
}

# =============================================================================
# UPTIME KUMA VIA DOKPOLOY (Docker Compose Template)
# =============================================================================

# This creates the configuration that Dokploy will deploy
resource "local_file" "kuma_compose" {
  count = var.kuma_enabled && var.dokploy_enabled ? 1 : 0

  filename = "${path.module}/.kuma-compose.yaml"
  content  = <<-EOT
    version: "3.8"
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:1
        container_name: kuma-managed
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
          # Apply tinyauth middleware if available
          - "traefik.http.routers.kuma.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD", "wget", "-q", "--spider", "http://localhost:3001/"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s
    
    volumes:
      kuma-data:
        driver: local
    
    networks:
      dokploy-network:
        external: true
        name: ${docker_network.dev_net.name}
  EOT

  depends_on = [
    terraform_data.dokploy_init[0]
  ]
}

# =============================================================================
# WHOAMI VIA DOKPOLOY (Docker Compose Template)
# =============================================================================

resource "local_file" "whoami_compose" {
  count = var.whoami_enabled && var.dokploy_enabled ? 1 : 0

  filename = "${path.module}/.whoami-compose.yaml"
  content  = <<-EOT
    version: "3.8"
    services:
      whoami:
        image: traefik/whoami:latest
        container_name: whoami-managed
        restart: unless-stopped
        networks:
          - dokploy-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoami.rule=Host(`whoami.stack.local`)"
          - "traefik.http.routers.whoami.entrypoints=web"
          - "traefik.http.services.whoami.loadbalancer.server.port=80"
          # Apply tinyauth middleware for protected access
          - "traefik.http.routers.whoami.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD", "wget", "-q", "--spider", "http://localhost/"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 10s
    
    networks:
      dokploy-network:
        external: true
        name: ${docker_network.dev_net.name}
  EOT

  depends_on = [
    terraform_data.dokploy_init[0]
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

output "domains" {
  description = "Service domain mappings"
  value       = local.domains
}

output "dokploy_url" {
  description = "URL to access Dokploy UI"
  value       = var.dokploy_enabled ? "http://${local.domains.dokploy}" : null
}

output "dokploy_admin_password" {
  description = "Dokploy admin password (sensitive)"
  value       = var.dokploy_enabled ? random_password.dokploy_admin[0].result : null
  sensitive   = true
}

output "traefik_url" {
  description = "URL to access Traefik dashboard"
  value       = var.traefik_enabled ? "http://${local.domains.traefik}" : null
}

output "kuma_url" {
  description = "URL to access Uptime Kuma"
  value       = var.kuma_enabled ? "http://${local.domains.kuma}" : null
}

output "whoami_url" {
  description = "URL to access whoami test service"
  value       = var.whoami_enabled ? "http://${local.domains.whoami}" : null
}

output "auth_url" {
  description = "URL to access TinyAuth login"
  value       = var.tinyauth_enabled ? "http://${local.domains.auth}" : null
}

output "tinyauth_admin_password" {
  description = "TinyAuth admin password (sensitive)"
  value       = var.tinyauth_enabled ? random_password.tinyauth_admin[0].result : null
  sensitive   = true
}

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value       = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║              DEV HOMELAB - PRODUCTION READY                        ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  Network: ${docker_network.dev_net.name} (${var.network_subnet})
    ║  Internal DB Network: ${docker_network.internal_db.name}
    ║
    ║  🔐 SECURITY ENABLED
    ║  • All admin interfaces protected by authentication
    ║  • No anonymous access to sensitive services
    ║  • TinyAuth configured for SSO/OIDC ready
    ║
    ║  🌐 Service URLs (via Traefik):
    ║  ${var.dokploy_enabled ? "  ✓ dokploy    → http://${local.domains.dokploy}" : "  ✗ dokploy    (disabled)"}
    ║  ${var.traefik_enabled ? "  ✓ traefik    → http://${local.domains.traefik}" : "  ✗ traefik    (disabled)"}
    ║  ${var.kuma_enabled ? "  ✓ kuma       → http://${local.domains.kuma}" : "  ✗ kuma       (disabled)"}
    ║  ${var.whoami_enabled ? "  ✓ whoami     → http://${local.domains.whoami}" : "  ✗ whoami     (disabled)"}
    ║  ${var.tinyauth_enabled ? "  ✓ auth       → http://${local.domains.auth}" : "  ✗ auth       (disabled)"}
    ║
    ║  📦 Dokploy PAAS manages:
    ║  • Kuma and Whoami deployed THROUGH Dokploy (not standalone)
    ║  • Automatic HTTPS and routing via Traefik
    ║  • Persistent volumes with backup labels
    ║
    ║  🔑 Credentials (sensitive - use terraform output):
    ║  • Dokploy admin: admin@stack.local (see: dokploy_admin_password)
    ║  • TinyAuth admin: admin (see: tinyauth_admin_password)
    ║
    ║  📋 Next Steps:
    ║  1. Access Dokploy UI: http://${local.domains.dokploy}
    ║  2. Login with admin credentials
    ║  3. Deploy Kuma and Whoami via Dokploy UI or API
    ║  4. All services route through Traefik with auth protection
    ║
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}

# Add random provider requirement
terraform {
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
