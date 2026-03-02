#!/bin/sh
# =============================================================================
# kombify Base Kit — One-Line Installer
# =============================================================================
# Usage:
#   curl -sSL https://raw.githubusercontent.com/kombifyio/stackKits/main/install.sh | sh
#
# What it does:
#   1. Checks Docker is installed
#   2. Downloads Base Kit compose + dashboard to ./kombify-base-kit/
#   3. Starts all services (Traefik, TinyAuth, PocketID, Dokploy, Uptime Kuma, ...)
#   4. Prints the dashboard URL
#
# Requirements:
#   - Docker 24.0+ with compose plugin
#   - 2+ CPU cores, 4+ GB RAM
#
# Credentials:
#   TinyAuth: admin / admin123
# =============================================================================
set -eu

REPO="kombifyio/stackKits"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
DIR="kombify-base-kit"

log() { printf '\033[1;36m[kombify]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[kombify]\033[0m %s\n' "$*" >&2; exit 1; }

# --- Pre-flight checks -------------------------------------------------------

command -v docker >/dev/null 2>&1 || err "Docker is not installed. Install it first: https://docs.docker.com/engine/install/"
docker compose version >/dev/null 2>&1 || err "Docker Compose plugin not found. Install it: https://docs.docker.com/compose/install/"

log "kombify Base Kit Installer"
log ""

# --- Download files -----------------------------------------------------------

if [ -d "$DIR" ]; then
  log "Directory $DIR already exists — updating files..."
else
  log "Creating $DIR/..."
  mkdir -p "$DIR"
fi

log "Downloading Base Kit..."
curl -sSL "${RAW}/demos/base-kit/docker-compose.yml" -o "${DIR}/docker-compose.yml"
curl -sSL "${RAW}/demos/dashboard.sh" -o "${DIR}/dashboard.sh"
chmod +x "${DIR}/dashboard.sh"

# Fix dashboard.sh path (compose expects ../dashboard.sh, we flatten to ./)
sed -i.bak 's|\.\./dashboard\.sh|./dashboard.sh|g' "${DIR}/docker-compose.yml" 2>/dev/null \
  || sed -i '' 's|\.\./dashboard\.sh|./dashboard.sh|g' "${DIR}/docker-compose.yml"
rm -f "${DIR}/docker-compose.yml.bak"

# --- Start services -----------------------------------------------------------

log "Starting Base Kit services..."
cd "$DIR"
docker compose up -d

# --- Wait for Traefik health --------------------------------------------------

log "Waiting for services to start..."
RETRIES=30
while [ "$RETRIES" -gt 0 ]; do
  if docker compose ps --format '{{.Health}}' 2>/dev/null | grep -q "healthy"; then
    break
  fi
  RETRIES=$((RETRIES - 1))
  sleep 2
done

# --- Detect server IP ---------------------------------------------------------

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
if [ -z "$SERVER_IP" ]; then
  SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "your-server-ip")
fi

# --- Done ---------------------------------------------------------------------

log ""
log "Base Kit is running!"
log ""
log "  Dashboard:   http://dash.stack.local:7880"
log "  TinyAuth:    http://auth.stack.local:7880"
log "  PocketID:    http://id.stack.local:7880"
log "  Dokploy:     http://dokploy.stack.local:7880"
log "  Uptime Kuma: http://kuma.stack.local:7880"
log "  Traefik:     http://proxy.stack.local:7880"
log ""
log "  Credentials: admin / admin123"
log ""
if [ "$SERVER_IP" != "your-server-ip" ]; then
  log "  LAN access (from any device):"
  log "    http://dash.${SERVER_IP}.sslip.io:7880"
  log ""
fi
log "  Stop:    cd $DIR && docker compose down"
log "  Restart: cd $DIR && docker compose up -d"
log ""
