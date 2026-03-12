# =============================================================================
# Base Kit - Single Server Deployment
# =============================================================================
# Architecture: Platform services via OpenTofu, Apps via Compose
#
# Standard/High Compute Tier:
#   L2 PaaS: Dokploy + PostgreSQL + Redis
#   L3 Apps: Kuma (monitoring), Whoami (test), user apps via Dokploy
#
# Low Compute Tier (Pi-Mode):
#   L2 PaaS: Dockge (lightweight Docker Compose manager)
#   L3 Apps: Whoami (test), user stacks via Dockge
#   No Uptime Kuma (resource constraint)
#
# Common (all tiers):
#   L1: Pocket ID (OIDC) + TinyAuth (ForwardAuth)
#   L2: Traefik (reverse proxy) + Dashboard
#
# Security Principle: Critical infrastructure outside PaaS ensures
# you can diagnose/fix PaaS issues if it fails.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0, < 3.9"
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
  default     = "base_net"
}

variable "network_subnet" {
  type        = string
  description = "Docker network subnet"
  default     = "172.20.0.0/16"
}

variable "enable_traefik" {
  type        = bool
  description = "Enable Traefik reverse proxy (Layer 2)"
  default     = true
}

variable "enable_tinyauth" {
  type        = bool
  description = "Enable TinyAuth ForwardAuth proxy (Layer 1)"
  default     = true
}

variable "enable_pocketid" {
  type        = bool
  description = "Enable Pocket ID OIDC identity provider (Layer 1)"
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

variable "enable_dockge" {
  type        = bool
  description = "Enable Dockge container manager (low compute tier, replaces Dokploy)"
  default     = false
}

variable "enable_uptime_kuma" {
  type        = bool
  description = "Enable Uptime Kuma monitoring"
  default     = true
}

variable "enable_vaultwarden" {
  type        = bool
  description = "Enable Vaultwarden password manager (Layer 3)"
  default     = true
}

variable "enable_jellyfin" {
  type        = bool
  description = "Enable Jellyfin media server (Layer 3, standard+ tier)"
  default     = true
}

variable "enable_immich" {
  type        = bool
  description = "Enable Immich photo management (Layer 3, standard+ tier)"
  default     = true
}

variable "media_path" {
  type        = string
  description = "Path to media files on host (bind-mounted into Jellyfin)"
  default     = "/opt/media"
}

variable "tinyauth_users" {
  type        = string
  description = "TinyAuth users configuration (bcrypt hashed)"
  default     = "admin:$2y$10$2aSDNcypqNOcOSOXkmQlSO0MBxZcUeRRtsU/gDZBIwWws.Oly8AYC"
}

variable "tinyauth_app_url" {
  type        = string
  description = "TinyAuth application URL"
  default     = "http://auth.stack.local"
}

variable "brand_color" {
  type        = string
  description = "Primary brand color for the dashboard (hex, e.g. #F97316)"
  default     = "#F97316"
}

variable "dashboard_title" {
  type        = string
  description = "Title shown in the homelab dashboard nav"
  default     = "My Homelab"
}

variable "enable_dashboard" {
  type        = bool
  description = "Enable the homelab links dashboard at base.<domain> (Layer 2)"
  default     = true
}

variable "admin_email" {
  type        = string
  description = "Admin email for login accounts (TinyAuth, Dokploy, Kuma)"
  default     = "admin"
}

variable "admin_password_plaintext" {
  type        = string
  description = "Auto-generated admin password (used by init containers)"
  default     = "admin123"
  sensitive   = true
}

variable "network_mode" {
  type        = string
  description = "Docker networking mode: 'bridge' (default) or 'host' (restricted VPS fallback)"
  default     = "bridge"
}

variable "dns_fixed" {
  type        = bool
  description = "Whether stackkit applied a DNS fix during prepare"
  default     = false
}

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS via Let's Encrypt ACME certificates"
  default     = false
}

variable "acme_email" {
  type        = string
  description = "Email address for Let's Encrypt ACME certificate registration"
  default     = ""
}

variable "acme_challenge" {
  type        = string
  description = "ACME challenge type: 'tls' (TLS-ALPN-01, needs port 443) or 'dns' (DNS-01, works behind NAT)"
  default     = "tls"
}

variable "dns_provider" {
  type        = string
  description = "DNS provider for DNS-01 ACME challenge (e.g. 'cloudflare', 'hetzner', 'digitalocean')"
  default     = ""
}

variable "dns_api_token" {
  type        = string
  description = "API token for DNS provider (used for DNS-01 ACME challenge)"
  default     = ""
  sensitive   = true
}

variable "dns_api_email" {
  type        = string
  description = "Email for DNS providers that use Global API Key auth (e.g. Cloudflare)"
  default     = ""
}

variable "dns_fix_method" {
  type        = string
  description = "DNS fix method applied: 'daemon-json' or 'host-prepull'"
  default     = ""
}

variable "storage_driver_degraded" {
  type        = bool
  description = "Whether Docker is using a degraded storage driver (e.g. vfs instead of overlay2)"
  default     = false
}

variable "storage_driver" {
  type        = string
  description = "Docker storage driver in use"
  default     = "overlay2"
}

variable "subdomain_prefix" {
  type        = string
  description = "Flat subdomain prefix for kombify.me tunnel mode (e.g. 'sh-mylab-abc'). When set, domains use flat naming: {prefix}-{service}.{domain} instead of {service}.{domain}"
  default     = ""
}

variable "enable_dnsmasq" {
  type        = bool
  description = "Enable dnsmasq local DNS server for *.homelab resolution (local mode)"
  default     = false
}

variable "enable_coolify" {
  type        = bool
  description = "Enable Coolify PAAS (alternative to Dokploy, standard+ tier)"
  default     = false
}

variable "reverse_proxy_backend" {
  type        = string
  description = "Which Traefik instance routes platform services: 'standalone' (own Traefik), 'dokploy' (Dokploy's Traefik), 'coolify' (Coolify's Traefik)"
  default     = "standalone"
}

variable "paas" {
  type        = string
  description = "PAAS platform selection: 'dokploy', 'coolify', 'dockge', 'none'"
  default     = "dokploy"
}

variable "server_lan_ip" {
  type        = string
  description = "Server LAN IP address for dnsmasq DNS resolution"
  default     = ""
}

# =============================================================================
# LOCALS
# =============================================================================

locals {
  # Networking mode
  is_host = var.network_mode == "host"

  # Reverse proxy backend: determines which Traefik routes platform services
  # - "standalone": StackKit deploys its own Traefik (default)
  # - "dokploy": platform services attach to Dokploy's Traefik network
  # - "coolify": platform services attach to Coolify's Traefik network
  rp_standalone = var.reverse_proxy_backend == "standalone"
  rp_dokploy    = var.reverse_proxy_backend == "dokploy"
  rp_coolify    = var.reverse_proxy_backend == "coolify"

  # The Docker network that platform services connect to for Traefik routing.
  # Standalone: base_net (our own). Dokploy: dokploy-network. Coolify: coolify.
  traefik_network_name = (
    local.rp_dokploy ? "dokploy-network" :
    local.rp_coolify ? "coolify" :
    var.network_name
  )

  # Resolved network name for services that need Traefik routing.
  # Standalone: use our own base_net. PAAS-managed: use their network.
  routing_network = (
    local.is_host ? "" :
    local.rp_standalone ? docker_network.base_net[0].name :
    data.docker_network.paas_traefik[0].name
  )

  # Protocol and entrypoint: HTTPS when enabled, HTTP otherwise
  proto      = var.enable_https ? "https" : "http"
  entrypoint = var.enable_https ? "websecure" : "web"

  # In host mode, all containers share the host network. Services that would
  # conflict on the same port need unique port assignments.
  host_ports = {
    tinyauth  = 3000  # TinyAuth native port
    pocketid  = 1411  # Pocket ID (set via PORT env)
    dokploy   = 3002  # Dokploy (moved from 3000 — avoids TinyAuth & Kuma conflict)
    dockge    = 5001  # Dockge native port (low compute tier)
    kuma      = 3001  # Kuma native port
    postgres  = 5432  # PostgreSQL standard
    redis     = 6379  # Redis standard
    dashboard    = 8090  # nginx (moved from 80 to avoid Traefik conflict)
    whoami       = 8091  # whoami (moved from 80 to avoid Traefik conflict)
    vaultwarden  = 8092  # Vaultwarden (native 80, remapped)
    jellyfin     = 8096  # Jellyfin native port
    immich       = 2283  # Immich server native port
    immich_ml    = 3003  # Immich ML worker (avoid 3000/3001)
    immich_pg    = 5433  # Immich PostgreSQL (5432 taken by Dokploy)
    immich_redis = 6380  # Immich Redis (6379 taken by Dokploy)
  }

  # Host-mode hint for dashboard
  host_mode_hint = local.is_host ? "<div style=\"background:#78350F;border:1px solid #D97706;border-radius:8px;padding:12px 16px;margin-bottom:20px;font-size:13px;color:#FEF3C7;\"><strong>&#9888; Host Networking Mode</strong> &mdash; Your VPS does not support Docker bridge networking. All containers run on the host network. For full network isolation, consider a KVM-based VPS (Hetzner, DigitalOcean, Linode).</div>" : ""

  dns_fix_hint = var.dns_fixed ? "<div style=\"background:#1E3A5F;border:1px solid #3B82F6;border-radius:8px;padding:12px 16px;margin-bottom:20px;font-size:13px;color:#DBEAFE;\"><strong>&#128268; DNS Fix Applied</strong> &mdash; stackkit automatically configured Docker DNS (method: ${var.dns_fix_method}). Container name resolution is working via external DNS servers (1.1.1.1, 8.8.8.8).</div>" : ""

  storage_hint = var.storage_driver_degraded ? "<div style=\"background:#7F1D1D;border:1px solid #EF4444;border-radius:8px;padding:12px 16px;margin-bottom:20px;font-size:13px;color:#FEE2E2;\"><strong>&#9888; Degraded Storage</strong> &mdash; Docker is using the <code>${var.storage_driver}</code> storage driver instead of overlay2. This uses more disk space and may be slower. Consider a KVM-based VPS for full performance.</div>" : ""

  # --- Compose file content (host vs bridge variants) ---
  # HCL ternary cannot use heredocs directly, so we define them as separate locals.

  kuma_compose_host = <<-EOT
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:1
        container_name: kuma
        restart: unless-stopped
        network_mode: host
        volumes:
          - kuma-data:/app/data
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.kuma.rule=Host(`${local.domains.kuma}`)"
          - "traefik.http.routers.kuma.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.kuma.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.kuma.loadbalancer.server.port=${local.host_ports.kuma}"
          - "traefik.http.routers.kuma.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:${local.host_ports.kuma}/ || exit 1"]
          interval: 30s
          timeout: 10s
          retries: 5
          start_period: 45s

      init-kuma:
        image: python:3.11-alpine
        restart: "no"
        network_mode: host
        environment:
          KUMA_URL: "http://127.0.0.1:${local.host_ports.kuma}"
          KUMA_USER: "${var.admin_email}"
          KUMA_PASS: "${random_password.kuma_admin[0].result}"
          DOMAIN: "${var.domain}"
        command:
          - sh
          - -c
          - |
            pip install -q uptime-kuma-api
            python3 << 'PYEOF'
            from uptime_kuma_api import UptimeKumaApi, MonitorType
            import os, sys
            url    = os.environ["KUMA_URL"]
            user   = os.environ["KUMA_USER"]
            pw     = os.environ["KUMA_PASS"]
            domain = os.environ["DOMAIN"]
            api = UptimeKumaApi(url, wait_events=True, timeout=30)
            try:
                api.setup(user, pw)
                print("Admin user created")
            except Exception as e:
                print(f"Setup skipped: {e}")
            try:
                api.login(user, pw)
                print("Logged in")
            except Exception as e:
                print(f"Login failed: {e}", file=sys.stderr)
                api.disconnect()
                sys.exit(1)
            monitors = [
                ("Traefik Dashboard", f"${local.proto}://traefik.{domain}"),
                ("TinyAuth",          f"${local.proto}://auth.{domain}"),
                ("${var.enable_dokploy ? "Dokploy" : "Dockge"}",  f"${local.proto}://${var.enable_dokploy ? "dokploy" : "dockge"}.{domain}"),
                ("Dashboard",         f"${local.proto}://base.{domain}"),
            ]
            for name, murl in monitors:
                try:
                    api.add_monitor(type=MonitorType.HTTP, name=name, url=murl,
                                    interval=60, maxretries=1,
                                    accepted_statuscodes=["200-399"])
                    print(f"Monitor added: {name}")
                except Exception as e:
                    print(f"Skip {name}: {e}")
            api.disconnect()
            print("Kuma setup complete!")
            PYEOF
        depends_on:
          uptime-kuma:
            condition: service_healthy

    volumes:
      kuma-data:
  EOT

  kuma_compose_bridge = <<-EOT
    services:
      uptime-kuma:
        image: louislam/uptime-kuma:1
        container_name: kuma
        restart: unless-stopped
        volumes:
          - kuma-data:/app/data
        networks:
          - traefik-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.kuma.rule=Host(`${local.domains.kuma}`)"
          - "traefik.http.routers.kuma.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.kuma.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.kuma.loadbalancer.server.port=3001"
          - "traefik.http.routers.kuma.middlewares=tinyauth@docker"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:3001/ || exit 1"]
          interval: 30s
          timeout: 10s
          retries: 5
          start_period: 45s

      init-kuma:
        image: python:3.11-alpine
        restart: "no"
        environment:
          KUMA_URL: "http://uptime-kuma:3001"
          KUMA_USER: "${var.admin_email}"
          KUMA_PASS: "${random_password.kuma_admin[0].result}"
          DOMAIN: "${var.domain}"
        command:
          - sh
          - -c
          - |
            pip install -q uptime-kuma-api
            python3 << 'PYEOF'
            from uptime_kuma_api import UptimeKumaApi, MonitorType
            import os, sys
            url    = os.environ["KUMA_URL"]
            user   = os.environ["KUMA_USER"]
            pw     = os.environ["KUMA_PASS"]
            domain = os.environ["DOMAIN"]
            api = UptimeKumaApi(url, wait_events=True, timeout=30)
            try:
                api.setup(user, pw)
                print("Admin user created")
            except Exception as e:
                print(f"Setup skipped: {e}")
            try:
                api.login(user, pw)
                print("Logged in")
            except Exception as e:
                print(f"Login failed: {e}", file=sys.stderr)
                api.disconnect()
                sys.exit(1)
            monitors = [
                ("Traefik Dashboard", f"${local.proto}://traefik.{domain}"),
                ("TinyAuth",          f"${local.proto}://auth.{domain}"),
                ("${var.enable_dokploy ? "Dokploy" : "Dockge"}",  f"${local.proto}://${var.enable_dokploy ? "dokploy" : "dockge"}.{domain}"),
                ("Dashboard",         f"${local.proto}://base.{domain}"),
            ]
            for name, murl in monitors:
                try:
                    api.add_monitor(type=MonitorType.HTTP, name=name, url=murl,
                                    interval=60, maxretries=1,
                                    accepted_statuscodes=["200-399"])
                    print(f"Monitor added: {name}")
                except Exception as e:
                    print(f"Skip {name}: {e}")
            api.disconnect()
            print("Kuma setup complete!")
            PYEOF
        depends_on:
          uptime-kuma:
            condition: service_healthy
        networks:
          - traefik-network

    volumes:
      kuma-data:

    networks:
      traefik-network:
        external: true
        name: ${local.traefik_network_name}
  EOT

  kuma_compose_content = local.is_host ? local.kuma_compose_host : local.kuma_compose_bridge

  whoami_compose_host = <<-EOT
    services:
      whoami:
        image: traefik/whoami:latest
        container_name: whoami
        restart: unless-stopped
        network_mode: host
        command: ["--port=${local.host_ports.whoami}"]
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoami.rule=Host(`${local.domains.whoami}`)"
          - "traefik.http.routers.whoami.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.whoami.loadbalancer.server.port=${local.host_ports.whoami}"
          - "traefik.http.routers.whoami.middlewares=tinyauth@docker"
  EOT

  whoami_compose_bridge = <<-EOT
    services:
      whoami:
        image: traefik/whoami:latest
        container_name: whoami
        restart: unless-stopped
        networks:
          - traefik-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoami.rule=Host(`${local.domains.whoami}`)"
          - "traefik.http.routers.whoami.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.whoami.loadbalancer.server.port=80"
          - "traefik.http.routers.whoami.middlewares=tinyauth@docker"

    networks:
      traefik-network:
        external: true
        name: ${local.traefik_network_name}
  EOT

  whoami_compose_content = local.is_host ? local.whoami_compose_host : local.whoami_compose_bridge

  # =============================================================================
  # VAULTWARDEN (Layer 3 — Password Vault)
  # =============================================================================
  vaultwarden_compose_host = <<-EOT
    services:
      vaultwarden:
        image: vaultwarden/server:latest
        container_name: vaultwarden
        restart: unless-stopped
        network_mode: host
        environment:
          - DOMAIN=${local.proto}://${local.domains.vault}
          - SIGNUPS_ALLOWED=false
          - ADMIN_TOKEN=${random_password.vaultwarden_admin[0].result}
          - ROCKET_PORT=${local.host_ports.vaultwarden}
        volumes:
          - vaultwarden-data:/data
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.vaultwarden.rule=Host(`${local.domains.vault}`)"
          - "traefik.http.routers.vaultwarden.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.vaultwarden.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.vaultwarden.loadbalancer.server.port=${local.host_ports.vaultwarden}"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:${local.host_ports.vaultwarden}/alive || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 10s
    volumes:
      vaultwarden-data:
  EOT

  vaultwarden_compose_bridge = <<-EOT
    services:
      vaultwarden:
        image: vaultwarden/server:latest
        container_name: vaultwarden
        restart: unless-stopped
        networks:
          - traefik-network
        environment:
          - DOMAIN=${local.proto}://${local.domains.vault}
          - SIGNUPS_ALLOWED=false
          - ADMIN_TOKEN=${random_password.vaultwarden_admin[0].result}
        volumes:
          - vaultwarden-data:/data
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.vaultwarden.rule=Host(`${local.domains.vault}`)"
          - "traefik.http.routers.vaultwarden.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.vaultwarden.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.vaultwarden.loadbalancer.server.port=80"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:80/alive || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 10s

    volumes:
      vaultwarden-data:

    networks:
      traefik-network:
        external: true
        name: ${local.traefik_network_name}
  EOT

  vaultwarden_compose_content = local.is_host ? local.vaultwarden_compose_host : local.vaultwarden_compose_bridge

  # =============================================================================
  # JELLYFIN (Layer 3 — Media Streaming)
  # =============================================================================
  jellyfin_compose_host = <<-EOT
    services:
      jellyfin:
        image: jellyfin/jellyfin:latest
        container_name: jellyfin
        restart: unless-stopped
        network_mode: host
        environment:
          - JELLYFIN_PublishedServerUrl=${local.proto}://${local.domains.media}
        volumes:
          - jellyfin-config:/config
          - jellyfin-cache:/cache
          - ${var.media_path}:/media:ro
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.jellyfin.rule=Host(`${local.domains.media}`)"
          - "traefik.http.routers.jellyfin.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.jellyfin.loadbalancer.server.port=${local.host_ports.jellyfin}"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:${local.host_ports.jellyfin}/health || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s
    volumes:
      jellyfin-config:
      jellyfin-cache:
  EOT

  jellyfin_compose_bridge = <<-EOT
    services:
      jellyfin:
        image: jellyfin/jellyfin:latest
        container_name: jellyfin
        restart: unless-stopped
        networks:
          - traefik-network
        environment:
          - JELLYFIN_PublishedServerUrl=${local.proto}://${local.domains.media}
        volumes:
          - jellyfin-config:/config
          - jellyfin-cache:/cache
          - ${var.media_path}:/media:ro
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.jellyfin.rule=Host(`${local.domains.media}`)"
          - "traefik.http.routers.jellyfin.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:8096/health || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s

    volumes:
      jellyfin-config:
      jellyfin-cache:

    networks:
      traefik-network:
        external: true
        name: ${local.traefik_network_name}
  EOT

  jellyfin_compose_content = local.is_host ? local.jellyfin_compose_host : local.jellyfin_compose_bridge

  # =============================================================================
  # IMMICH (Layer 3 — Photo Management)
  # =============================================================================
  immich_compose_host = <<-EOT
    services:
      immich-server:
        image: ghcr.io/immich-app/immich-server:release
        container_name: immich
        restart: unless-stopped
        network_mode: host
        environment:
          - DB_HOSTNAME=127.0.0.1
          - DB_PORT=${local.host_ports.immich_pg}
          - DB_USERNAME=immich
          - DB_PASSWORD=${random_password.immich_db[0].result}
          - DB_DATABASE_NAME=immich
          - REDIS_HOSTNAME=127.0.0.1
          - REDIS_PORT=${local.host_ports.immich_redis}
          - IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:${local.host_ports.immich_ml}:3003
          - IMMICH_SERVER_PORT=${local.host_ports.immich}
        volumes:
          - immich-upload:/usr/src/app/upload
          - /etc/localtime:/etc/localtime:ro
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.immich.rule=Host(`${local.domains.photos}`)"
          - "traefik.http.routers.immich.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.immich.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.immich.loadbalancer.server.port=${local.host_ports.immich}"
        depends_on:
          immich-postgres:
            condition: service_healthy
          immich-redis:
            condition: service_healthy
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:${local.host_ports.immich}/api/server/ping || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s

      immich-machine-learning:
        image: ghcr.io/immich-app/immich-machine-learning:release
        container_name: immich-ml
        restart: unless-stopped
        network_mode: host
        environment:
          - MACHINE_LEARNING_PORT=${local.host_ports.immich_ml}
        volumes:
          - immich-model-cache:/cache

      immich-postgres:
        image: tensorchord/pgvecto-rs:pg16-v0.3.0
        container_name: immich-postgres
        restart: unless-stopped
        network_mode: host
        environment:
          - POSTGRES_USER=immich
          - POSTGRES_PASSWORD=${random_password.immich_db[0].result}
          - POSTGRES_DB=immich
          - PGPORT=${local.host_ports.immich_pg}
        volumes:
          - immich-postgres-data:/var/lib/postgresql/data
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U immich -d immich -p ${local.host_ports.immich_pg}"]
          interval: 10s
          timeout: 5s
          retries: 5
          start_period: 10s

      immich-redis:
        image: redis:7-alpine
        container_name: immich-redis
        restart: unless-stopped
        network_mode: host
        command: ["redis-server", "--port", "${local.host_ports.immich_redis}"]
        healthcheck:
          test: ["CMD", "redis-cli", "-p", "${local.host_ports.immich_redis}", "ping"]
          interval: 10s
          timeout: 5s
          retries: 5

    volumes:
      immich-upload:
      immich-model-cache:
      immich-postgres-data:
  EOT

  immich_compose_bridge = <<-EOT
    services:
      immich-server:
        image: ghcr.io/immich-app/immich-server:release
        container_name: immich
        restart: unless-stopped
        networks:
          - traefik-network
          - immich-internal
        environment:
          - DB_HOSTNAME=immich-postgres
          - DB_PORT=5432
          - DB_USERNAME=immich
          - DB_PASSWORD=${random_password.immich_db[0].result}
          - DB_DATABASE_NAME=immich
          - REDIS_HOSTNAME=immich-redis
          - REDIS_PORT=6379
          - IMMICH_MACHINE_LEARNING_URL=http://immich-ml:3003
        volumes:
          - immich-upload:/usr/src/app/upload
          - /etc/localtime:/etc/localtime:ro
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.immich.rule=Host(`${local.domains.photos}`)"
          - "traefik.http.routers.immich.entrypoints=${local.entrypoint}"
%{if var.enable_https~}
          - "traefik.http.routers.immich.tls.certresolver=letsencrypt"
%{endif~}
          - "traefik.http.services.immich.loadbalancer.server.port=2283"
        depends_on:
          immich-postgres:
            condition: service_healthy
          immich-redis:
            condition: service_healthy
        healthcheck:
          test: ["CMD-SHELL", "curl -sf http://localhost:2283/api/server/ping || exit 1"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 30s

      immich-machine-learning:
        image: ghcr.io/immich-app/immich-machine-learning:release
        container_name: immich-ml
        restart: unless-stopped
        networks:
          - immich-internal
        volumes:
          - immich-model-cache:/cache

      immich-postgres:
        image: tensorchord/pgvecto-rs:pg16-v0.3.0
        container_name: immich-postgres
        restart: unless-stopped
        networks:
          - immich-internal
        environment:
          - POSTGRES_USER=immich
          - POSTGRES_PASSWORD=${random_password.immich_db[0].result}
          - POSTGRES_DB=immich
        volumes:
          - immich-postgres-data:/var/lib/postgresql/data
        healthcheck:
          test: ["CMD-SHELL", "pg_isready -U immich -d immich"]
          interval: 10s
          timeout: 5s
          retries: 5
          start_period: 10s

      immich-redis:
        image: redis:7-alpine
        container_name: immich-redis
        restart: unless-stopped
        networks:
          - immich-internal
        healthcheck:
          test: ["CMD", "redis-cli", "ping"]
          interval: 10s
          timeout: 5s
          retries: 5

    volumes:
      immich-upload:
      immich-model-cache:
      immich-postgres-data:

    networks:
      traefik-network:
        external: true
        name: ${local.traefik_network_name}
      immich-internal:
        driver: bridge
  EOT

  immich_compose_content = local.is_host ? local.immich_compose_host : local.immich_compose_bridge

  # When subdomain_prefix is set (kombify.me tunnel mode), domains use flat naming:
  #   {prefix}-{service}.{domain}  e.g. sh-mylab-abc-dash.kombify.me
  # When empty (own domain or LAN), domains use nested naming:
  #   {service}.{domain}           e.g. dash.kmbchr.de
  _p = var.subdomain_prefix

  domains = {
    dokploy   = local._p != "" ? "${local._p}-dokploy.${var.domain}" : "dokploy.${var.domain}"
    coolify   = local._p != "" ? "${local._p}-coolify.${var.domain}" : "coolify.${var.domain}"
    dockge    = local._p != "" ? "${local._p}-dockge.${var.domain}" : "dockge.${var.domain}"
    traefik   = local._p != "" ? "${local._p}-traefik.${var.domain}" : "traefik.${var.domain}"
    kuma      = local._p != "" ? "${local._p}-kuma.${var.domain}" : "kuma.${var.domain}"
    whoami    = local._p != "" ? "${local._p}-whoami.${var.domain}" : "whoami.${var.domain}"
    auth      = local._p != "" ? "${local._p}-tinyauth.${var.domain}" : "auth.${var.domain}"
    dashboard = local._p != "" ? "${local._p}-dash.${var.domain}" : "base.${var.domain}"
    pocketid  = local._p != "" ? "${local._p}-id.${var.domain}" : "id.${var.domain}"
    vault     = local._p != "" ? "${local._p}-vault.${var.domain}" : "vault.${var.domain}"
    media     = local._p != "" ? "${local._p}-media.${var.domain}" : "media.${var.domain}"
    photos    = local._p != "" ? "${local._p}-photos.${var.domain}" : "photos.${var.domain}"
  }

  # =============================================================================
  # HOMELAB DASHBOARD HTML
  # Brand color (${var.brand_color}) and domain (${var.domain}) are injected at
  # generation time. No external deps — served as a self-contained nginx:alpine
  # container at base.${var.domain}.
  # =============================================================================
  dashboard_html = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>${var.dashboard_title}</title>
      <style>
        :root {
          --brand: ${var.brand_color};
          --bg: #0F172A;
          --surface: #1E293B;
          --surface-h: #243352;
          --border: rgba(71,85,105,0.5);
          --text: #F1F5F9;
          --dim: #94A3B8;
          --muted: #64748B;
          --r: 12px;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--bg); color: var(--text); min-height: 100vh; line-height: 1.6; }
        nav { position: fixed; top: 0; left: 0; right: 0; z-index: 100; height: 52px; background: rgba(15,23,42,0.9); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border); display: flex; align-items: center; padding: 0 24px; gap: 10px; }
        .dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; background: var(--brand); box-shadow: 0 0 8px var(--brand); animation: pulse 2.5s infinite; }
        @keyframes pulse { 0%,100% {opacity:1} 50% {opacity:0.4} }
        .nav-title { font-weight: 700; font-size: 15px; }
        .nav-domain { font-family: monospace; font-size: 11px; color: var(--muted); background: rgba(255,255,255,0.05); padding: 2px 8px; border-radius: 4px; }
        .nav-kuma { margin-left: auto; text-decoration: none; font-size: 12px; font-weight: 500; color: var(--dim); padding: 4px 12px; border: 1px solid var(--border); border-radius: 6px; transition: color .15s, border-color .15s; }
        .nav-kuma:hover { color: var(--brand); border-color: var(--brand); }
        main { max-width: 1080px; margin: 0 auto; padding: 72px 24px 48px; }
        .hdr { margin-bottom: 36px; }
        .hdr h1 { font-size: 26px; font-weight: 700; margin-bottom: 4px; }
        .hdr p { font-size: 13px; color: var(--muted); }
        .accent { color: var(--brand); }
        .section { margin-bottom: 32px; }
        .slabel { font-size: 10px; font-weight: 700; letter-spacing: .12em; text-transform: uppercase; color: var(--muted); display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
        .slabel::after { content:''; flex:1; height:1px; background:var(--border); }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 10px; }
        a.card { display: block; text-decoration: none; background: var(--surface); border: 1px solid var(--border); border-radius: var(--r); padding: 18px 20px; overflow: hidden; position: relative; transition: background .15s, border-color .15s, transform .1s; }
        a.card::before { content:''; position:absolute; top:0; left:0; right:0; height:2px; background: var(--brand); transform: scaleX(0); transform-origin: left; transition: transform .2s; }
        a.card:hover { background: var(--surface-h); border-color: var(--brand); transform: translateY(-1px); }
        a.card:hover::before { transform: scaleX(1); }
        .chead { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 8px; }
        .cicon { width: 34px; height: 34px; border-radius: 8px; background: rgba(255,255,255,0.05); border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; }
        .cmeta { flex: 1; }
        .cname { font-weight: 600; font-size: 14px; }
        .cbadge { display: inline-block; font-size: 10px; font-weight: 600; letter-spacing: .04em; padding: 1px 6px; border-radius: 3px; background: rgba(255,255,255,0.06); color: var(--muted); margin-top: 2px; }
        .cstatus { width: 6px; height: 6px; border-radius: 50%; background: #22C55E; margin-top: 6px; flex-shrink: 0; }
        .cdesc { font-size: 12px; color: var(--dim); line-height: 1.5; margin-bottom: 10px; }
        .curl { font-family: monospace; font-size: 11px; color: var(--brand); opacity: .7; }
        a.card:hover .curl { opacity: 1; }
        footer { text-align: center; padding: 24px; border-top: 1px solid var(--border); font-size: 12px; color: var(--muted); }
        footer a { color: var(--brand); text-decoration: none; }
        footer a:hover { text-decoration: underline; }
      </style>
    </head>
    <body>
      <nav>
        <div class="dot"></div>
        <span class="nav-title">${var.dashboard_title}</span>
        <span class="nav-domain">${var.domain}</span>
        <a class="nav-kuma" href="${local.proto}://kuma.${var.domain}" target="_blank">&#9650; Status</a>
      </nav>
      <main>
        ${local.host_mode_hint}${local.dns_fix_hint}${local.storage_hint}
        <div class="hdr">
          <h1>Service <span class="accent">Dashboard</span></h1>
          <p>Running on <code style="font-family:monospace">${var.domain}</code> &middot; Managed by StackKits</p>
        </div>
        <section class="section">
          <div class="slabel">Platform</div>
          <div class="grid">
            <a class="card" href="${local.proto}://id.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128100;</div><div class="cmeta"><div class="cname">Pocket ID</div><span class="cbadge">L1 &middot; IdP</span></div><div class="cstatus"></div></div>
              <p class="cdesc">OIDC identity provider with passkey authentication. Manage users and SSO clients.</p>
              <div class="curl">id.${var.domain}</div>
            </a>
            <a class="card" href="${local.proto}://auth.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128274;</div><div class="cmeta"><div class="cname">TinyAuth</div><span class="cbadge">L1 &middot; ForwardAuth</span></div><div class="cstatus"></div></div>
              <p class="cdesc">ForwardAuth gateway. Protects all services via TinyAuth middleware backed by Pocket ID.</p>
              <div class="curl">auth.${var.domain}</div>
            </a>
            <a class="card" href="${local.proto}://traefik.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#9889;</div><div class="cmeta"><div class="cname">Traefik</div><span class="cbadge">L2 &middot; Reverse Proxy</span></div><div class="cstatus"></div></div>
              <p class="cdesc">Routes all traffic across services. View active routes, middlewares, and upstreams.</p>
              <div class="curl">traefik.${var.domain}</div>
            </a>
            ${var.enable_dokploy ? "<a class=\"card\" href=\"${local.proto}://dokploy.${var.domain}\" target=\"_blank\"><div class=\"chead\"><div class=\"cicon\">&#128640;</div><div class=\"cmeta\"><div class=\"cname\">Dokploy</div><span class=\"cbadge\">L2 &middot; PaaS</span></div><div class=\"cstatus\"></div></div><p class=\"cdesc\">Deploy and manage applications. Your self-hosted Heroku for services and compose stacks.</p><div class=\"curl\">dokploy.${var.domain}</div></a>" : ""}${var.enable_dockge ? "<a class=\"card\" href=\"${local.proto}://dockge.${var.domain}\" target=\"_blank\"><div class=\"chead\"><div class=\"cicon\">&#128230;</div><div class=\"cmeta\"><div class=\"cname\">Dockge</div><span class=\"cbadge\">L2 &middot; Compose Manager</span></div><div class=\"cstatus\"></div></div><p class=\"cdesc\">Lightweight Docker Compose manager. Create and manage compose stacks with a simple UI.</p><div class=\"curl\">dockge.${var.domain}</div></a>" : ""}
          </div>
        </section>
        <section class="section">
          <div class="slabel">Applications</div>
          <div class="grid">
            <a class="card" href="${local.proto}://kuma.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128202;</div><div class="cmeta"><div class="cname">Uptime Kuma</div><span class="cbadge">L3 &middot; Monitoring</span></div><div class="cstatus"></div></div>
              <p class="cdesc">Service uptime monitoring and status pages for all homelab services.</p>
              <div class="curl">kuma.${var.domain}</div>
            </a>
            <a class="card" href="${local.proto}://whoami.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#129302;</div><div class="cmeta"><div class="cname">Whoami</div><span class="cbadge">L3 &middot; Test</span></div><div class="cstatus"></div></div>
              <p class="cdesc">HTTP echo service for verifying Traefik routing, TinyAuth middleware, and headers.</p>
              <div class="curl">whoami.${var.domain}</div>
            </a>
            ${var.enable_vaultwarden ? "<a class=\"card\" href=\"${local.proto}://${local.domains.vault}\" target=\"_blank\"><div class=\"chead\"><div class=\"cicon\">&#128272;</div><div class=\"cmeta\"><div class=\"cname\">Vaultwarden</div><span class=\"cbadge\">L3 &middot; Vault</span></div><div class=\"cstatus\"></div></div><p class=\"cdesc\">Self-hosted password manager. Bitwarden-compatible vault for passwords, TOTP, and secure notes.</p><div class=\"curl\">${local.domains.vault}</div></a>" : ""}
            ${var.enable_jellyfin ? "<a class=\"card\" href=\"${local.proto}://${local.domains.media}\" target=\"_blank\"><div class=\"chead\"><div class=\"cicon\">&#127916;</div><div class=\"cmeta\"><div class=\"cname\">Jellyfin</div><span class=\"cbadge\">L3 &middot; Media</span></div><div class=\"cstatus\"></div></div><p class=\"cdesc\">Free media server for movies, TV, music, and photos. Stream to any device on your network.</p><div class=\"curl\">${local.domains.media}</div></a>" : ""}
            ${var.enable_immich ? "<a class=\"card\" href=\"${local.proto}://${local.domains.photos}\" target=\"_blank\"><div class=\"chead\"><div class=\"cicon\">&#128247;</div><div class=\"cmeta\"><div class=\"cname\">Immich</div><span class=\"cbadge\">L3 &middot; Photos</span></div><div class=\"cstatus\"></div></div><p class=\"cdesc\">Self-hosted photo and video management with AI-powered search, facial recognition, and mobile backup.</p><div class=\"curl\">${local.domains.photos}</div></a>" : ""}
          </div>
        </section>
        <section class="section">
          <div class="slabel">Getting Started</div>
          <div style="background:var(--surface);border:1px solid var(--border);border-radius:var(--r);padding:24px 28px;">
            <ol style="margin:0;padding-left:20px;font-size:13px;color:var(--dim);line-height:2.2;">
              <li>Login to <a href="${local.proto}://auth.${var.domain}" style="color:var(--brand);text-decoration:none;">TinyAuth</a> with your admin email + generated password</li>
              <li>Register a passkey at <a href="${local.proto}://id.${var.domain}/login/setup" style="color:var(--brand);text-decoration:none;font-family:monospace;">id.${var.domain}/login/setup</a> for passwordless login</li>
              ${var.enable_dokploy ? "<li>Access <a href=\"${local.proto}://dokploy.${var.domain}\" style=\"color:var(--brand);text-decoration:none;\">Dokploy</a> to deploy and manage applications (protected by TinyAuth)</li>" : ""}${var.enable_dockge ? "<li>Access <a href=\"${local.proto}://dockge.${var.domain}\" style=\"color:var(--brand);text-decoration:none;\">Dockge</a> to manage Docker Compose stacks (protected by TinyAuth)</li>" : ""}
              <li>Check <a href="${local.proto}://kuma.${var.domain}" style="color:var(--brand);text-decoration:none;">Uptime Kuma</a> for service monitoring</li>
              <li>Change your auto-generated password in TinyAuth settings</li>
            </ol>
          </div>
        </section>
      </main>
      <footer>Built with <a href="https://stackkits.io" target="_blank">StackKits</a> &nbsp;&middot;&nbsp; <span style="color:var(--brand)">&#9679;</span> &nbsp;${var.domain}</footer>
    </body>
    </html>
  HTML
}

# =============================================================================
# PROVIDER
# =============================================================================

provider "docker" {
  # Uses local Docker socket (unix:///var/run/docker.sock by default)
  # OpenTofu runs on the target server via SSH
}

# =============================================================================
# LAYER 2: PLATFORM - NETWORK
# =============================================================================

resource "docker_network" "base_net" {
  count  = local.is_host ? 0 : 1
  name   = var.network_name
  driver = "bridge"

  ipam_config {
    subnet = var.network_subnet
  }

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  lifecycle {
    ignore_changes = [ipam_config]
  }
}

# When using Dokploy/Coolify's Traefik, reference their existing Docker network.
# Platform services connect to this network so their Traefik labels are discovered.
data "docker_network" "paas_traefik" {
  count = (!local.is_host && !local.rp_standalone) ? 1 : 0
  name  = local.traefik_network_name
}

resource "docker_network" "internal_db" {
  count    = local.is_host ? 0 : 1
  name     = "${var.network_name}_db"
  driver   = "bridge"
  internal = true

  ipam_config {
    subnet = "172.28.0.0/24"
  }

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  lifecycle {
    ignore_changes = [ipam_config]
  }
}

# =============================================================================
# LOCAL DNS - dnsmasq (local mode only)
# =============================================================================
# Resolves *.homelab → server LAN IP so all LAN devices can reach services
# by name without /etc/hosts. User configures router DHCP DNS to point here.

# Stop system DNS services that occupy port 53 before starting our dnsmasq
resource "null_resource" "stop_system_dns" {
  count = var.enable_dnsmasq ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      systemctl stop dnsmasq 2>/dev/null || true
      systemctl disable dnsmasq 2>/dev/null || true
      systemctl stop systemd-resolved 2>/dev/null || true
      systemctl disable systemd-resolved 2>/dev/null || true
      # Ensure /etc/resolv.conf points to a real DNS (not 127.0.0.53)
      if [ -L /etc/resolv.conf ]; then
        rm /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
      fi
    EOT
  }
}

resource "docker_image" "dnsmasq" {
  count = var.enable_dnsmasq ? 1 : 0
  name  = "jpillora/dnsmasq:latest"
}

resource "docker_container" "dnsmasq" {
  count      = var.enable_dnsmasq ? 1 : 0
  depends_on = [docker_network.base_net, null_resource.stop_system_dns]
  name       = "dnsmasq"
  image      = docker_image.dnsmasq[0].image_id
  restart    = "unless-stopped"

  ports {
    internal = 53
    external = 53
    protocol = "tcp"
  }
  ports {
    internal = 53
    external = 53
    protocol = "udp"
  }

  upload {
    content = <<-EOT
      address=/.${var.domain}/${var.server_lan_ip}
      server=8.8.8.8
      server=8.8.4.4
    EOT
    file    = "/etc/dnsmasq.conf"
  }

  labels {
    label = "stackkit.layer"
    value = "1-foundation"
  }
  labels {
    label = "stackkit.service"
    value = "dnsmasq"
  }

  security_opts = ["no-new-privileges:true"]
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

resource "docker_volume" "pocketid_data" {
  count = var.enable_pocketid ? 1 : 0
  name  = "pocketid-data"
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

# Layer 2: Platform (Dockge - low compute tier)
resource "docker_volume" "dockge_data" {
  count = var.enable_dockge ? 1 : 0
  name  = "dockge-data"
  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }
  labels {
    label = "stackkit.backup"
    value = "required"
  }
}

# Layer 3: Applications
resource "docker_volume" "kuma_data" {
  count = var.enable_uptime_kuma ? 1 : 0
  name  = "kuma-data"
  labels {
    label = "stackkit.layer"
    value = "3-application"
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
  name  = "traefik:v3"
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

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
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

  command = concat([
    "--api.dashboard=true",
    "--api.insecure=true",
    "--ping=true",
    "--providers.docker=true",
    "--providers.docker.exposedbydefault=false",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    "--log.level=INFO",
    "--accesslog=true",
  ],
  # HTTP → HTTPS redirect when HTTPS is enabled
  var.enable_https ? [
    "--entrypoints.web.http.redirections.entrypoint.to=websecure",
    "--entrypoints.web.http.redirections.entrypoint.scheme=https",
  ] : [],
  # ACME certificate resolver (only when HTTPS enabled)
  var.enable_https ? [
    "--certificatesresolvers.letsencrypt.acme.email=${var.acme_email}",
    "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json",
  ] : [],
  # TLS-ALPN-01 challenge (default, needs port 443 reachable)
  var.enable_https && var.acme_challenge == "tls" ? [
    "--certificatesresolvers.letsencrypt.acme.tlschallenge=true",
  ] : [],
  # DNS-01 challenge (for wildcard certs, works behind NAT)
  var.enable_https && var.acme_challenge == "dns" ? [
    "--certificatesresolvers.letsencrypt.acme.dnschallenge=true",
    "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${var.dns_provider}",
    "--certificatesresolvers.letsencrypt.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53",
  ] : [],
  # Docker network provider (bridge mode only)
  local.is_host ? [] : [
    "--providers.docker.network=${docker_network.base_net[0].name}",
  ])

  env = concat([
    "TZ=Europe/Berlin",
    "DOCKER_API_VERSION=1.44",
  ],
  # DNS provider API token for DNS-01 challenge (provider-specific env var names)
  # Cloudflare: supports scoped API Token (CF_DNS_API_TOKEN) or Global API Key (CF_API_EMAIL + CF_API_KEY)
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "cloudflare" && var.dns_api_email != "" ? [
    "CF_API_EMAIL=${var.dns_api_email}",
    "CF_API_KEY=${var.dns_api_token}",
  ] : [],
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "cloudflare" && var.dns_api_email == "" ? [
    "CF_DNS_API_TOKEN=${var.dns_api_token}",
  ] : [],
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "hetzner" ? [
    "HETZNER_API_KEY=${var.dns_api_token}",
  ] : [],
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "digitalocean" ? [
    "DO_AUTH_TOKEN=${var.dns_api_token}",
  ] : [],
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "duckdns" ? [
    "DUCKDNS_TOKEN=${var.dns_api_token}",
  ] : [],
  var.enable_https && var.acme_challenge == "dns" && var.dns_provider == "namecheap" ? [
    "NAMECHEAP_API_KEY=${var.dns_api_token}",
    "NAMECHEAP_API_USER=${var.acme_email}",
  ] : [])

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
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.traefik.tls.certresolver"
      value = "letsencrypt"
    }
  }

  labels {
    label = "traefik.http.routers.traefik.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  healthcheck {
    test         = ["CMD", "wget", "-q", "--spider", "http://localhost:8080/ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

# Gate resource: ensures the reverse proxy (whichever backend) is ready before
# platform services start. Services depend on this instead of docker_container.traefik.
resource "null_resource" "reverse_proxy_ready" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for reverse proxy (${var.reverse_proxy_backend})..."
      for i in $(seq 1 60); do
        if [ "${var.reverse_proxy_backend}" = "standalone" ]; then
          docker ps --filter "name=traefik" --filter "status=running" -q | grep -q . && echo "Traefik ready" && exit 0
        elif [ "${var.reverse_proxy_backend}" = "dokploy" ]; then
          docker ps --filter "name=dokploy" --filter "status=running" -q | grep -q . && echo "Dokploy Traefik ready" && exit 0
        elif [ "${var.reverse_proxy_backend}" = "coolify" ]; then
          docker ps --filter "name=coolify-proxy" --filter "status=running" -q | grep -q . && echo "Coolify Traefik ready" && exit 0
        fi
        sleep 3
      done
      echo "WARNING: reverse proxy not detected after 3 minutes, continuing anyway"
    EOT
  }
}

# =============================================================================
# LAYER 1: FOUNDATION - TINYAUTH IDENTITY
# =============================================================================

resource "docker_image" "tinyauth" {
  count = var.enable_tinyauth ? 1 : 0
  name  = "ghcr.io/steveiliop56/tinyauth:v4"
}

resource "docker_container" "tinyauth" {
  count = var.enable_tinyauth ? 1 : 0
  name  = "tinyauth"
  image = docker_image.tinyauth[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
  }

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  # Connect to PAAS Traefik network for label discovery (Dokploy/Coolify backend)
  dynamic "networks_advanced" {
    for_each = (!local.is_host && !local.rp_standalone) ? [1] : []
    content {
      name = data.docker_network.paas_traefik[0].name
    }
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
    "USERS=${var.tinyauth_users}",
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
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.tinyauth.tls.certresolver"
      value = "letsencrypt"
    }
  }

  labels {
    label = "traefik.http.services.tinyauth.loadbalancer.server.port"
    value = "3000"
  }

  # ForwardAuth middleware
  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.address"
    value = local.is_host ? "http://127.0.0.1:${local.host_ports.tinyauth}/api/auth/traefik" : "http://tinyauth:3000/api/auth/traefik"
  }

  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.trustForwardHeader"
    value = "true"
  }

  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders"
    value = "X-User,X-Email"
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget -q -O /dev/null http://localhost:3000/ || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [null_resource.reverse_proxy_ready]
}

# =============================================================================
# LAYER 1: FOUNDATION - POCKET ID (OIDC IDENTITY PROVIDER)
# =============================================================================

resource "random_password" "pocketid_encryption_key" {
  count   = var.enable_pocketid ? 1 : 0
  length  = 32
  special = false
}

resource "docker_image" "pocketid" {
  count = var.enable_pocketid ? 1 : 0
  name  = "ghcr.io/pocket-id/pocket-id:v2"
}

resource "docker_container" "pocketid" {
  count = var.enable_pocketid ? 1 : 0
  name  = "pocketid"
  image = docker_image.pocketid[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  # Connect to PAAS Traefik network for label discovery (Dokploy/Coolify backend)
  dynamic "networks_advanced" {
    for_each = (!local.is_host && !local.rp_standalone) ? [1] : []
    content {
      name = data.docker_network.paas_traefik[0].name
    }
  }

  volumes {
    volume_name    = docker_volume.pocketid_data[0].name
    container_path = "/app/data"
  }

  env = [
    "TZ=Europe/Berlin",
    "APP_URL=${local.proto}://${local.domains.pocketid}",
    "TRUST_PROXY=true",
    "ENCRYPTION_KEY=${random_password.pocketid_encryption_key[0].result}",
    "PORT=1411",
  ]

  labels {
    label = "stackkit.layer"
    value = "1-foundation"
  }

  labels {
    label = "stackkit.service"
    value = "pocketid"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.pocketid.rule"
    value = "Host(`${local.domains.pocketid}`)"
  }

  labels {
    label = "traefik.http.routers.pocketid.entrypoints"
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.pocketid.tls.certresolver"
      value = "letsencrypt"
    }
  }

  labels {
    label = "traefik.http.services.pocketid.loadbalancer.server.port"
    value = "1411"
  }

  healthcheck {
    test         = ["CMD", "/app/pocket-id", "healthcheck"]
    interval     = "90s"
    timeout      = "5s"
    retries      = 2
    start_period = "10s"
  }

  depends_on = [null_resource.reverse_proxy_ready]
}

# =============================================================================
# LAYER 2: PLATFORM - DOKPLOY DATABASE
# =============================================================================

resource "random_password" "dokploy_db_password" {
  count   = var.enable_dokploy ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "kuma_admin" {
  count   = var.enable_uptime_kuma ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "vaultwarden_admin" {
  count   = var.enable_vaultwarden ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "immich_db" {
  count   = var.enable_immich ? 1 : 0
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

  # postgres image handles user switching internally (root → postgres uid)
  # Do NOT set user here — init scripts need root to chmod /var/run/postgresql

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
    add  = ["CHOWN", "SETGID", "SETUID", "DAC_OVERRIDE"]
  }

  # Bridge: reachable only on internal_db network. Host: on host loopback.
  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.internal_db[0].name
    }
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
# LAYER 2: PLATFORM - DOKPLOY REDIS
# =============================================================================

resource "docker_image" "dokploy_redis" {
  count = var.enable_dokploy ? 1 : 0
  name  = "redis:7-alpine"
}

resource "docker_container" "dokploy_redis" {
  count = var.enable_dokploy ? 1 : 0
  name  = "dokploy-redis"
  image = docker_image.dokploy_redis[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  capabilities {
    drop = ["ALL"]
    add  = ["SETUID", "SETGID"]
  }

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.internal_db[0].name
    }
  }

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.service"
    value = "dokploy-redis"
  }

  healthcheck {
    test         = ["CMD", "redis-cli", "ping"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "5s"
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

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.internal_db[0].name
    }
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
    "DATABASE_URL=postgresql://dokploy:${random_password.dokploy_db_password[0].result}@${local.is_host ? "127.0.0.1" : "dokploy-postgres"}:5432/dokploy",
    "REDIS_URL=redis://${local.is_host ? "127.0.0.1" : "dokploy-redis"}:6379",
    "NODE_ENV=production",
    "PORT=${local.is_host ? tostring(local.host_ports.dokploy) : "3000"}",
    "TRPC_PLAYGROUND=false",
    "LETSENCRYPT_EMAIL=${var.acme_email != "" ? var.acme_email : var.admin_email}",
    "TRAEFIK_ENABLED=true",
    "TRAEFIK_NETWORK=${local.is_host ? "" : local.routing_network}",
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
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.dokploy.tls.certresolver"
      value = "letsencrypt"
    }
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
    value = local.is_host ? tostring(local.host_ports.dokploy) : "3000"
  }

  healthcheck {
    test         = ["CMD-SHELL", "curl -s -o /dev/null -w '%%{http_code}' http://localhost:${local.is_host ? local.host_ports.dokploy : 3000}/api/settings | grep -qE '^[2-4]'"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 5
    start_period = "60s"
  }

  depends_on = [
    docker_container.dokploy_postgres,
    docker_container.dokploy_redis,
    null_resource.reverse_proxy_ready
  ]
}

# =============================================================================
# LAYER 2: PLATFORM - DOKPLOY ADMIN INIT
# =============================================================================
# One-shot container that creates the Dokploy admin user via its tRPC API.
# Runs once after Dokploy starts, waits for health, then calls createAdmin.

resource "docker_image" "curl" {
  count = var.enable_dokploy ? 1 : 0
  name  = "curlimages/curl:latest"
}

resource "docker_container" "init_dokploy" {
  count = var.enable_dokploy ? 1 : 0
  name  = "init-dokploy"
  image = docker_image.curl[0].image_id

  restart = "no"
  rm      = true

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  command = [
    "sh", "-c",
    <<-EOT
      DOKPLOY_HOST="${local.is_host ? "127.0.0.1" : "dokploy"}"
      DOKPLOY_PORT="${local.is_host ? local.host_ports.dokploy : 3000}"
      echo "Waiting for Dokploy to be ready..."
      for i in $(seq 1 60); do
        if curl -sf "http://$DOKPLOY_HOST:$DOKPLOY_PORT/api/settings" >/dev/null 2>&1; then
          echo "Dokploy is ready"
          break
        fi
        sleep 2
      done
      echo "Creating admin user..."
      curl -sf -X POST \
        -H "Content-Type: application/json" \
        -d '{"0":{"json":{"email":"${var.admin_email}","password":"${var.admin_password_plaintext}"}}}' \
        "http://$DOKPLOY_HOST:$DOKPLOY_PORT/api/trpc/auth.createAdmin?batch=1" && \
      echo "Dokploy admin created" || echo "Dokploy admin creation skipped (may already exist)"
    EOT
  ]

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.service"
    value = "init-dokploy"
  }

  depends_on = [docker_container.dokploy]
}

# =============================================================================
# LAYER 2: PLATFORM - DOCKGE (LOW COMPUTE TIER)
# =============================================================================
# Lightweight Docker Compose manager — replaces Dokploy when compute tier is low.
# No database required, minimal memory footprint.

resource "null_resource" "dockge_stacks_dir" {
  count = var.enable_dockge ? 1 : 0

  provisioner "local-exec" {
    command = "mkdir -p /opt/stacks"
  }
}

resource "docker_image" "dockge" {
  count = var.enable_dockge ? 1 : 0
  name  = "louislam/dockge:1"
}

resource "docker_container" "dockge" {
  count      = var.enable_dockge ? 1 : 0
  depends_on = [null_resource.dockge_stacks_dir, null_resource.reverse_proxy_ready]
  name       = "dockge"
  image      = docker_image.dockge[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  # Connect to PAAS Traefik network for label discovery (Dokploy/Coolify backend)
  dynamic "networks_advanced" {
    for_each = (!local.is_host && !local.rp_standalone) ? [1] : []
    content {
      name = data.docker_network.paas_traefik[0].name
    }
  }

  volumes {
    volume_name    = docker_volume.dockge_data[0].name
    container_path = "/app/data"
  }

  mounts {
    type      = "bind"
    target    = "/var/run/docker.sock"
    source    = "/var/run/docker.sock"
    read_only = true
  }

  mounts {
    type   = "bind"
    target = "/opt/stacks"
    source = "/opt/stacks"
  }

  env = [
    "DOCKGE_STACKS_DIR=/opt/stacks",
  ]

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.service"
    value = "dockge"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.dockge.rule"
    value = "Host(`${local.domains.dockge}`)"
  }

  labels {
    label = "traefik.http.routers.dockge.entrypoints"
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.dockge.tls.certresolver"
      value = "letsencrypt"
    }
  }

  labels {
    label = "traefik.http.services.dockge.loadbalancer.server.port"
    value = "5001"
  }

  labels {
    label = "traefik.http.routers.dockge.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  memory = 512

  healthcheck {
    test         = ["CMD-SHELL", "curl -sf http://localhost:5001/ > /dev/null || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "15s"
  }
}

# =============================================================================
# LAYER 2: PLATFORM - COOLIFY (ALTERNATIVE PAAS)
# =============================================================================
# Full-featured PAAS with built-in Traefik management. When Coolify is the PAAS,
# it manages its own Traefik instance — platform services attach to Coolify's
# network for routing (ADR-0006: Service URL Matrix).
#
# Note: Coolify is installed via its own installer script, not as a single container.
# This resource runs the Coolify install script and ensures it's ready.

resource "null_resource" "coolify_install" {
  count = var.enable_coolify ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v coolify &> /dev/null && ! docker ps --format '{{"{{"}}.Names{{"}}"}}' | grep -q coolify; then
        echo "Installing Coolify..."
        curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
      else
        echo "Coolify already installed"
      fi
    EOT
  }
}

# Wait for Coolify's Traefik to be ready before deploying platform services
resource "null_resource" "coolify_traefik_ready" {
  count = var.enable_coolify ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Coolify Traefik..."
      for i in $(seq 1 60); do
        if docker ps --filter "name=coolify-proxy" --filter "status=running" -q | grep -q .; then
          echo "Coolify Traefik is ready"
          exit 0
        fi
        sleep 5
      done
      echo "WARNING: Coolify Traefik not detected after 5 minutes"
    EOT
  }

  depends_on = [null_resource.coolify_install]
}

# =============================================================================
# LAYER 2: LINKS DASHBOARD
# =============================================================================

resource "docker_image" "nginx" {
  count = var.enable_dashboard ? 1 : 0
  name  = "nginx:alpine"
}

resource "docker_container" "dashboard" {
  count = var.enable_dashboard ? 1 : 0
  name  = "dashboard"
  image = docker_image.nginx[0].image_id

  restart = "unless-stopped"

  security_opts = ["no-new-privileges:true"]

  network_mode = local.is_host ? "host" : null

  dynamic "networks_advanced" {
    for_each = local.is_host ? [] : [1]
    content {
      name = docker_network.base_net[0].name
    }
  }

  # Connect to PAAS Traefik network for label discovery (Dokploy/Coolify backend)
  dynamic "networks_advanced" {
    for_each = (!local.is_host && !local.rp_standalone) ? [1] : []
    content {
      name = data.docker_network.paas_traefik[0].name
    }
  }

  command = [
    "sh", "-c",
    local.is_host ? "printf '%s' '${base64encode(local.dashboard_html)}' | base64 -d > /usr/share/nginx/html/index.html && sed -i 's/listen.*80/listen       ${local.host_ports.dashboard}/' /etc/nginx/conf.d/default.conf && exec nginx -g 'daemon off;'" : "printf '%s' '${base64encode(local.dashboard_html)}' | base64 -d > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"
  ]

  labels {
    label = "stackkit.layer"
    value = "2-platform"
  }

  labels {
    label = "stackkit.service"
    value = "dashboard"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.dashboard.rule"
    value = "Host(`${local.domains.dashboard}`)"
  }

  labels {
    label = "traefik.http.routers.dashboard.entrypoints"
    value = local.entrypoint
  }

  dynamic "labels" {
    for_each = var.enable_https ? [1] : []
    content {
      label = "traefik.http.routers.dashboard.tls.certresolver"
      value = "letsencrypt"
    }
  }

  labels {
    label = "traefik.http.services.dashboard.loadbalancer.server.port"
    value = local.is_host ? tostring(local.host_ports.dashboard) : "80"
  }

  labels {
    label = "traefik.http.routers.dashboard.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget -q --spider http://127.0.0.1:${local.is_host ? local.host_ports.dashboard : 80}/ || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    docker_container.tinyauth,
  ]
}

# =============================================================================
# LAYER 3: APPLICATIONS - COMPOSE CONFIGS
# =============================================================================
# Docker Compose templates for L3 applications. Deployed independently of PaaS.

resource "local_file" "kuma_compose" {
  count = var.enable_uptime_kuma ? 1 : 0

  filename = "${path.module}/.kuma-compose.yaml"
  content  = local.kuma_compose_content
}

resource "local_file" "whoami_compose" {
  count = 1

  filename = "${path.module}/.whoami-compose.yaml"
  content  = local.whoami_compose_content
}

resource "local_file" "vaultwarden_compose" {
  count = var.enable_vaultwarden ? 1 : 0

  filename = "${path.module}/.vaultwarden-compose.yaml"
  content  = local.vaultwarden_compose_content
}

resource "local_file" "jellyfin_compose" {
  count = var.enable_jellyfin ? 1 : 0

  filename = "${path.module}/.jellyfin-compose.yaml"
  content  = local.jellyfin_compose_content
}

resource "local_file" "immich_compose" {
  count = var.enable_immich ? 1 : 0

  filename = "${path.module}/.immich-compose.yaml"
  content  = local.immich_compose_content
}

# =============================================================================
# LAYER 3 AUTO-DEPLOYMENT
# =============================================================================
# Deploy L3 compose files automatically. Re-triggers when compose content changes.

resource "null_resource" "deploy_kuma" {
  count = var.enable_uptime_kuma ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.kuma_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.kuma_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    docker_container.tinyauth,
    local_file.kuma_compose,
  ]
}

resource "null_resource" "deploy_whoami" {
  count = 1

  triggers = {
    compose_hash = sha256(local_file.whoami_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.whoami_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    docker_container.tinyauth,
    local_file.whoami_compose,
  ]
}

resource "null_resource" "deploy_vaultwarden" {
  count = var.enable_vaultwarden ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.vaultwarden_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.vaultwarden_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    local_file.vaultwarden_compose,
  ]
}

# Jellyfin needs the media directory to exist before compose up
resource "null_resource" "jellyfin_media_dir" {
  count = var.enable_jellyfin ? 1 : 0

  provisioner "local-exec" {
    command = "mkdir -p ${var.media_path}"
  }
}

resource "null_resource" "deploy_jellyfin" {
  count = var.enable_jellyfin ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.jellyfin_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.jellyfin_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    null_resource.jellyfin_media_dir,
    local_file.jellyfin_compose,
  ]
}

resource "null_resource" "deploy_immich" {
  count = var.enable_immich ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.immich_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.immich_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    null_resource.reverse_proxy_ready,
    local_file.immich_compose,
  ]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "network_name" {
  description = "Docker network name (empty in host mode)"
  value       = local.is_host ? "host" : local.routing_network
}

output "domains" {
  description = "Service domain mappings"
  value       = local.domains
}

output "traefik_url" {
  description = "Traefik dashboard URL (Layer 2 Platform)"
  value       = var.enable_traefik ? "${local.proto}://${local.domains.traefik}" : null
}

output "auth_url" {
  description = "TinyAuth login URL (Layer 1 Foundation)"
  value       = var.enable_tinyauth ? "${local.proto}://${local.domains.auth}" : null
}

output "pocketid_url" {
  description = "Pocket ID OIDC provider URL (Layer 1 Foundation)"
  value       = var.enable_pocketid ? "${local.proto}://${local.domains.pocketid}" : null
}

output "dokploy_url" {
  description = "Dokploy UI URL (Layer 2 Platform)"
  value       = var.enable_dokploy ? "${local.proto}://${local.domains.dokploy}" : null
}

output "dockge_url" {
  description = "Dockge UI URL (Layer 2 Platform, low compute tier)"
  value       = var.enable_dockge ? "${local.proto}://${local.domains.dockge}" : null
}

output "coolify_url" {
  description = "Coolify UI URL (Layer 2 Platform)"
  value       = var.enable_coolify ? "${local.proto}://${local.domains.coolify}" : null
}

output "paas_url" {
  description = "PaaS manager URL (Dokploy, Coolify, or Dockge depending on selection)"
  value       = (
    var.enable_dokploy ? "${local.proto}://${local.domains.dokploy}" :
    var.enable_coolify ? "${local.proto}://${local.domains.coolify}" :
    var.enable_dockge ? "${local.proto}://${local.domains.dockge}" :
    null
  )
}

output "reverse_proxy_backend" {
  description = "Which Traefik instance routes platform services"
  value       = var.reverse_proxy_backend
}

output "kuma_url" {
  description = "Uptime Kuma URL (Layer 3 Application)"
  value       = "${local.proto}://${local.domains.kuma}"
}

output "dashboard_url" {
  description = "Homelab links dashboard URL (Layer 2 Platform)"
  value       = var.enable_dashboard ? "${local.proto}://${local.domains.dashboard}" : null
}

output "kuma_admin_password" {
  description = "Uptime Kuma admin password (set by init-kuma on first deploy)"
  value       = random_password.kuma_admin[0].result
  sensitive   = true
}

output "whoami_url" {
  description = "Whoami test URL (Layer 3 Application)"
  value       = "${local.proto}://${local.domains.whoami}"
}

output "vaultwarden_url" {
  description = "Vaultwarden password vault URL (Layer 3 Application)"
  value       = var.enable_vaultwarden ? "${local.proto}://${local.domains.vault}" : null
}

output "vaultwarden_admin_token" {
  description = "Vaultwarden admin panel token"
  value       = var.enable_vaultwarden ? random_password.vaultwarden_admin[0].result : null
  sensitive   = true
}

output "jellyfin_url" {
  description = "Jellyfin media server URL (Layer 3 Application)"
  value       = var.enable_jellyfin ? "${local.proto}://${local.domains.media}" : null
}

output "immich_url" {
  description = "Immich photo management URL (Layer 3 Application)"
  value       = var.enable_immich ? "${local.proto}://${local.domains.photos}" : null
}

output "credentials" {
  description = "Admin credentials"
  value       = var.enable_tinyauth ? "TinyAuth: ${var.admin_email} / <see admin_password output>" : null
  sensitive   = false
}

output "admin_password" {
  description = "Auto-generated admin password"
  value       = var.admin_password_plaintext
  sensitive   = true
}

output "tinyauth_login_url" {
  description = "TinyAuth login URL"
  value       = var.enable_tinyauth ? "${local.proto}://${local.domains.auth}" : null
}

output "dokploy_login_url" {
  description = "Dokploy login URL"
  value       = var.enable_dokploy ? "${local.proto}://${local.domains.dokploy}" : null
}

output "architecture_summary" {
  description = "Base Kit Architecture Summary"
  value       = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║              BASE KIT - SINGLE SERVER DEPLOYMENT                 ║
    ║  Compute: ${var.enable_dockge ? "LOW (Pi-Mode)" : "STANDARD"}${var.enable_dockge ? "                                              " : "                                                   "}║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  Network: ${local.is_host ? "HOST MODE (bridge unavailable)" : "Bridge (isolated Docker networks)"}${local.is_host ? "                       " : "         "}║
    ║                                                                   ║
    ║  LAYER 1 (Foundation):                                             ║
    ║    ${var.enable_pocketid ? "✓" : "✗"} Pocket ID   → ${local.proto}://${local.domains.pocketid}       ║
    ║    ${var.enable_tinyauth ? "✓" : "✗"} TinyAuth    → ${local.proto}://${local.domains.auth}           ║
    ║        Credentials: ${var.admin_email} / <auto-generated>        ║
    ║                                                                   ║
    ║  LAYER 2 (Platform):                                               ║
    ║    Reverse Proxy: ${var.reverse_proxy_backend}                      ║
    ║    ${var.enable_traefik ? "✓" : "✗"} Traefik     → ${local.proto}://${local.domains.traefik}        ║
    ║    ${var.enable_dokploy ? "✓" : "✗"} Dokploy     → ${local.proto}://${local.domains.dokploy}        ║
    ║    ${var.enable_coolify ? "✓" : "✗"} Coolify     → ${local.proto}://${local.domains.coolify}        ║
    ║    ${var.enable_dockge ? "✓" : "✗"} Dockge      → ${local.proto}://${local.domains.dockge}         ║
    ║    ${var.enable_dashboard ? "✓" : "✗"} Dashboard  → ${local.proto}://${local.domains.dashboard}      ║
    ║                                                                   ║
    ║  LAYER 3 (Applications):                                           ║
    ║    ✓ Kuma     → ${local.proto}://${local.domains.kuma}          ║
    ║    ✓ Whoami   → ${local.proto}://${local.domains.whoami}        ║
    ║    ${var.enable_vaultwarden ? "✓" : "✗"} Vault    → ${local.proto}://${local.domains.vault}         ║
    ║    ${var.enable_jellyfin ? "✓" : "✗"} Jellyfin → ${local.proto}://${local.domains.media}         ║
    ║    ${var.enable_immich ? "✓" : "✗"} Immich   → ${local.proto}://${local.domains.photos}        ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  FIRST LOGIN                                                       ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  1. Login: ${local.proto}://${local.domains.auth}                          ║
    ║     Email: ${var.admin_email} / Password: <see output>           ║
    ║  2. Passkey: ${local.proto}://${local.domains.pocketid}/login/setup         ║
    ║  3. PaaS: ${local.proto}://${var.enable_dokploy ? local.domains.dokploy : (var.enable_coolify ? local.domains.coolify : local.domains.dockge)}                          ║
    ║                                                                   ║
    ${var.subdomain_prefix != "" ? "║  DNS: Managed by kombify.me (Cloudflare wildcard)                   ║" : "║  DNS: *.${var.domain} -> ${var.enable_dnsmasq ? var.server_lan_ip : "<server-ip>"}${var.enable_dnsmasq ? "                       " : "                              "}║"}
    ${var.enable_dnsmasq ? "║  Local DNS: dnsmasq running on port 53                              ║" : "║                                                                   ║"}
    ${var.enable_dnsmasq ? "║  Set router DHCP DNS to ${var.server_lan_ip} for auto-resolve       ║" : "║                                                                   ║"}
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
