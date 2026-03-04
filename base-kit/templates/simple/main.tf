# =============================================================================
# Base Kit - Single Server Deployment
# =============================================================================
# Architecture: Platform services via OpenTofu, Apps via Dokploy
#
# Layer 1 (FOUNDATION) - Managed by OpenTofu:
#   ├── Pocket ID (identity)        - OIDC provider with passkey auth
#   └── TinyAuth (ForwardAuth)      - Middleware proxy backed by Pocket ID
#
# Layer 2 (PLATFORM) - Managed by OpenTofu:
#   ├── Traefik (reverse proxy)     - CRITICAL infrastructure
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

# =============================================================================
# LOCALS
# =============================================================================

locals {
  domains = {
    dokploy   = "dokploy.${var.domain}"
    traefik   = "traefik.${var.domain}"
    kuma      = "kuma.${var.domain}"
    whoami    = "whoami.${var.domain}"
    auth      = "auth.${var.domain}"
    dashboard = "base.${var.domain}"
    pocketid  = "id.${var.domain}"
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
        <a class="nav-kuma" href="http://kuma.${var.domain}" target="_blank">&#9650; Status</a>
      </nav>
      <main>
        <div class="hdr">
          <h1>Service <span class="accent">Dashboard</span></h1>
          <p>Running on <code style="font-family:monospace">${var.domain}</code> &middot; Managed by StackKits</p>
        </div>
        <section class="section">
          <div class="slabel">Platform</div>
          <div class="grid">
            <a class="card" href="http://id.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128100;</div><div class="cmeta"><div class="cname">Pocket ID</div><span class="cbadge">L1 &middot; IdP</span></div><div class="cstatus"></div></div>
              <p class="cdesc">OIDC identity provider with passkey authentication. Manage users and SSO clients.</p>
              <div class="curl">id.${var.domain}</div>
            </a>
            <a class="card" href="http://auth.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128274;</div><div class="cmeta"><div class="cname">TinyAuth</div><span class="cbadge">L1 &middot; ForwardAuth</span></div><div class="cstatus"></div></div>
              <p class="cdesc">ForwardAuth gateway. Protects all services via TinyAuth middleware backed by Pocket ID.</p>
              <div class="curl">auth.${var.domain}</div>
            </a>
            <a class="card" href="http://traefik.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#9889;</div><div class="cmeta"><div class="cname">Traefik</div><span class="cbadge">L2 &middot; Reverse Proxy</span></div><div class="cstatus"></div></div>
              <p class="cdesc">Routes all traffic across services. View active routes, middlewares, and upstreams.</p>
              <div class="curl">traefik.${var.domain}</div>
            </a>
            <a class="card" href="http://dokploy.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128640;</div><div class="cmeta"><div class="cname">Dokploy</div><span class="cbadge">L2 &middot; PaaS</span></div><div class="cstatus"></div></div>
              <p class="cdesc">Deploy and manage applications. Your self-hosted Heroku for services and compose stacks.</p>
              <div class="curl">dokploy.${var.domain}</div>
            </a>
          </div>
        </section>
        <section class="section">
          <div class="slabel">Applications</div>
          <div class="grid">
            <a class="card" href="http://kuma.${var.domain}" target="_blank">
              <div class="chead"><div class="cicon">&#128202;</div><div class="cmeta"><div class="cname">Uptime Kuma</div><span class="cbadge">L3 &middot; Monitoring</span></div><div class="cstatus"></div></div>
              <p class="cdesc">Service uptime monitoring and status pages for all homelab services.</p>
              <div class="curl">kuma.${var.domain}</div>
            </a>
          </div>
        </section>
        <section class="section">
          <div class="slabel">Getting Started</div>
          <div style="background:var(--surface);border:1px solid var(--border);border-radius:var(--r);padding:24px 28px;">
            <ol style="margin:0;padding-left:20px;font-size:13px;color:var(--dim);line-height:2.2;">
              <li>Login to <a href="http://auth.${var.domain}" style="color:var(--brand);text-decoration:none;">TinyAuth</a> with your admin email + generated password</li>
              <li>Register a passkey at <a href="http://id.${var.domain}/login/setup" style="color:var(--brand);text-decoration:none;font-family:monospace;">id.${var.domain}/login/setup</a> for passwordless login</li>
              <li>Access <a href="http://dokploy.${var.domain}" style="color:var(--brand);text-decoration:none;">Dokploy</a> to deploy and manage applications (protected by TinyAuth)</li>
              <li>Check <a href="http://kuma.${var.domain}" style="color:var(--brand);text-decoration:none;">Uptime Kuma</a> for service monitoring</li>
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

resource "docker_network" "internal_db" {
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

# Layer 3: Applications (managed by Dokploy)
# These volumes are created by OpenTofu but managed by Dokploy
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

  networks_advanced {
    name = docker_network.base_net.name
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
    "--providers.docker.network=${docker_network.base_net.name}",
    "--entrypoints.web.address=:80",
    "--entrypoints.websecure.address=:443",
    "--certificatesresolvers.local.acme.tlschallenge=true",
    "--certificatesresolvers.local.acme.email=admin@stack.local",
    "--certificatesresolvers.local.acme.storage=/letsencrypt/acme.json",
    "--log.level=INFO",
    "--accesslog=true",
  ]

  env = [
    "TZ=Europe/Berlin",
    "DOCKER_API_VERSION=1.44",
  ]

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

  networks_advanced {
    name = docker_network.base_net.name
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
    value = "web"
  }

  labels {
    label = "traefik.http.services.tinyauth.loadbalancer.server.port"
    value = "3000"
  }

  # ForwardAuth middleware
  labels {
    label = "traefik.http.middlewares.tinyauth.forwardauth.address"
    value = "http://tinyauth:3000/api/auth/traefik"
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

  depends_on = [docker_container.traefik]
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

  networks_advanced {
    name = docker_network.base_net.name
  }

  volumes {
    volume_name    = docker_volume.pocketid_data[0].name
    container_path = "/app/data"
  }

  env = [
    "TZ=Europe/Berlin",
    "APP_URL=http://${local.domains.pocketid}",
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
    value = "web"
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

resource "random_password" "kuma_admin" {
  count   = var.enable_dokploy_apps ? 1 : 0
  length  = 16
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

  # No external ports - only reachable on internal_db network
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

  networks_advanced {
    name = docker_network.internal_db.name
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

  networks_advanced {
    name = docker_network.base_net.name
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
    "REDIS_URL=redis://dokploy-redis:6379",
    "NODE_ENV=production",
    "PORT=3000",
    "TRPC_PLAYGROUND=false",
    "LETSENCRYPT_EMAIL=admin@stack.local",
    "TRAEFIK_ENABLED=true",
    "TRAEFIK_NETWORK=${docker_network.base_net.name}",
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
    test         = ["CMD-SHELL", "curl -s -o /dev/null -w '%%{http_code}' http://localhost:3000/api/settings | grep -qE '^[2-4]'"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 5
    start_period = "60s"
  }

  depends_on = [
    docker_container.dokploy_postgres,
    docker_container.dokploy_redis,
    docker_container.traefik
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

  networks_advanced {
    name = docker_network.base_net.name
  }

  command = [
    "sh", "-c",
    <<-EOT
      echo "Waiting for Dokploy to be ready..."
      for i in $(seq 1 60); do
        if curl -sf http://dokploy:3000/api/settings >/dev/null 2>&1; then
          echo "Dokploy is ready"
          break
        fi
        sleep 2
      done
      echo "Creating admin user..."
      curl -sf -X POST \
        -H "Content-Type: application/json" \
        -d '{"0":{"json":{"email":"${var.admin_email}","password":"${var.admin_password_plaintext}"}}}' \
        "http://dokploy:3000/api/trpc/auth.createAdmin?batch=1" && \
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

  networks_advanced {
    name = docker_network.base_net.name
  }

  command = [
    "sh", "-c",
    "printf '%s' '${base64encode(local.dashboard_html)}' | base64 -d > /usr/share/nginx/html/index.html && exec nginx -g 'daemon off;'"
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
    value = "web"
  }

  labels {
    label = "traefik.http.services.dashboard.loadbalancer.server.port"
    value = "80"
  }

  labels {
    label = "traefik.http.routers.dashboard.middlewares"
    value = var.enable_tinyauth ? "tinyauth@docker" : ""
  }

  healthcheck {
    test         = ["CMD-SHELL", "wget -q --spider http://127.0.0.1:80/ || exit 1"]
    interval     = "30s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }

  depends_on = [
    docker_container.traefik,
    docker_container.tinyauth,
  ]
}

# =============================================================================
# LAYER 3: APPLICATIONS - DOKPLOY COMPOSE CONFIGS
# =============================================================================
# These are Docker Compose templates that Dokploy will use to deploy
# Layer 3 applications. They are NOT deployed by OpenTofu directly.

resource "local_file" "kuma_compose" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  filename = "${path.module}/.kuma-compose.yaml"
  content  = <<-EOT
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
          - "traefik.http.routers.kuma.rule=Host(`kuma.${var.domain}`)"
          - "traefik.http.routers.kuma.entrypoints=web"
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
          KUMA_PASS: "${var.enable_dokploy_apps ? random_password.kuma_admin[0].result : "admin"}"
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
                ("Traefik Dashboard", f"http://traefik.{domain}"),
                ("TinyAuth",          f"http://auth.{domain}"),
                ("Dokploy",           f"http://dokploy.{domain}"),
                ("Dashboard",         f"http://base.{domain}"),
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
          - dokploy-network

    volumes:
      kuma-data:

    networks:
      dokploy-network:
        external: true
        name: ${var.network_name}
  EOT
}

resource "local_file" "whoami_compose" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  filename = "${path.module}/.whoami-compose.yaml"
  content  = <<-EOT
    services:
      whoami:
        image: traefik/whoami:latest
        container_name: whoami
        restart: unless-stopped
        networks:
          - dokploy-network
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.whoami.rule=Host(`whoami.${var.domain}`)"
          - "traefik.http.routers.whoami.entrypoints=web"
          - "traefik.http.services.whoami.loadbalancer.server.port=80"
          - "traefik.http.routers.whoami.middlewares=tinyauth@docker"

    networks:
      dokploy-network:
        external: true
        name: ${var.network_name}
  EOT
}

# =============================================================================
# LAYER 3 AUTO-DEPLOYMENT
# =============================================================================
# Deploy L3 compose files automatically. Re-triggers when compose content changes.

resource "null_resource" "deploy_kuma" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.kuma_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.kuma_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    docker_container.dokploy,
    docker_container.traefik,
    docker_container.tinyauth,
    local_file.kuma_compose,
  ]
}

resource "null_resource" "deploy_whoami" {
  count = var.enable_dokploy && var.enable_dokploy_apps ? 1 : 0

  triggers = {
    compose_hash = sha256(local_file.whoami_compose[0].content)
  }

  provisioner "local-exec" {
    command     = "docker compose -f ${local_file.whoami_compose[0].filename} up -d --wait"
    working_dir = path.module
  }

  depends_on = [
    docker_container.traefik,
    docker_container.tinyauth,
    local_file.whoami_compose,
  ]
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "network_name" {
  description = "Docker network name"
  value       = docker_network.base_net.name
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

output "pocketid_url" {
  description = "Pocket ID OIDC provider URL (Layer 1 Foundation)"
  value       = var.enable_pocketid ? "http://${local.domains.pocketid}" : null
}

output "dokploy_url" {
  description = "Dokploy UI URL (Layer 2 Platform)"
  value       = var.enable_dokploy ? "http://${local.domains.dokploy}" : null
}

output "kuma_url" {
  description = "Uptime Kuma URL (Layer 3 Application)"
  value       = var.enable_dokploy_apps ? "http://${local.domains.kuma}" : null
}

output "dashboard_url" {
  description = "Homelab links dashboard URL (Layer 2 Platform)"
  value       = var.enable_dashboard ? "http://${local.domains.dashboard}" : null
}

output "kuma_admin_password" {
  description = "Uptime Kuma admin password (set by init-kuma on first deploy)"
  value       = var.enable_dokploy_apps ? random_password.kuma_admin[0].result : null
  sensitive   = true
}

output "whoami_url" {
  description = "Whoami test URL (Layer 3 Application)"
  value       = var.enable_dokploy_apps ? "http://${local.domains.whoami}" : null
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
  value       = var.enable_tinyauth ? "http://${local.domains.auth}" : null
}

output "dokploy_login_url" {
  description = "Dokploy login URL"
  value       = var.enable_dokploy ? "http://${local.domains.dokploy}" : null
}

output "architecture_summary" {
  description = "Base Kit Architecture Summary"
  value       = <<-EOT
    ╔═══════════════════════════════════════════════════════════════════╗
    ║              BASE KIT - SINGLE SERVER DEPLOYMENT                 ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  ALL SERVICES RUN ON THE TARGET SERVER                            ║
    ║                                                                   ║
    ║  LAYER 1 (Foundation) - Managed by OpenTofu:                      ║
    ║    ${var.enable_pocketid ? "✓" : "✗"} Pocket ID   → http://${local.domains.pocketid}       ║
    ║        Purpose: OIDC Identity Provider (passkey auth)            ║
    ║                                                                   ║
    ║    ${var.enable_tinyauth ? "✓" : "✗"} TinyAuth    → http://${local.domains.auth}           ║
    ║        Purpose: ForwardAuth proxy (backed by Pocket ID)          ║
    ║        Credentials: ${var.admin_email} / <auto-generated>        ║
    ║                                                                   ║
    ║  LAYER 2 (Platform) - Managed by OpenTofu:                        ║
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
    ║    ${var.enable_dashboard ? "✓" : "✗"} Dashboard  → http://${local.domains.dashboard}      ║
    ║        Purpose: Service links & navigation                       ║
    ║                                                                   ║
    ║  LAYER 3 (Applications) - Auto-deployed via Compose:              ║
    ║    ${var.enable_dokploy_apps ? "✓" : "✗"} Kuma     → http://${local.domains.kuma}          ║
    ║        Uptime monitoring with pre-configured monitors           ║
    ║                                                                   ║
    ║    ${var.enable_dokploy_apps ? "✓" : "✗"} Whoami   → http://${local.domains.whoami}        ║
    ║        Network diagnostic endpoint                              ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  FIRST LOGIN FLOW                                                 ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  Step 1: Login to TinyAuth                                        ║
    ║    URL: http://${local.domains.auth}                             ║
    ║    Email: ${var.admin_email}                                     ║
    ║    Password: <auto-generated, see terraform output>              ║
    ║                                                                   ║
    ║  Step 1b: Register passkey at Pocket ID                           ║
    ║    URL: http://${local.domains.pocketid}/login/setup              ║
    ║    Enables passwordless login via WebAuthn                        ║
    ║                                                                   ║
    ║  Step 2: Access Dokploy (via TinyAuth SSO)                        ║
    ║    URL: http://${local.domains.dokploy}                          ║
    ║    You'll be redirected to TinyAuth for authentication            ║
    ║                                                                   ║
    ║  Step 3: Layer 3 Applications (auto-deployed)                     ║
    ║    Kuma and Whoami are deployed automatically                    ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  DNS SETUP (add to /etc/hosts on your client or use dnsmasq)      ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  <server-ip>  id.stack.local       (Pocket ID)                     ║
    ║  <server-ip>  auth.stack.local    (TinyAuth)                      ║
    ║  <server-ip>  traefik.stack.local                                 ║
    ║  <server-ip>  dokploy.stack.local                                 ║
    ║  <server-ip>  base.stack.local    (dashboard)                     ║
    ║  <server-ip>  kuma.stack.local                                    ║
    ║                                                                   ║
    ║  Or wildcard:  *.stack.local -> <server-ip>                       ║
    ║                                                                   ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║  VERIFICATION                                                     ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                   ║
    ║  ssh user@server docker ps    # Should show all services          ║
    ║  curl http://auth.stack.local # Should return TinyAuth login      ║
    ║                                                                   ║
    ╚═══════════════════════════════════════════════════════════════════╝
  EOT
}
