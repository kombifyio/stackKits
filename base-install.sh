#!/bin/sh
# =============================================================================
# StackKits Base Installer -- installs the CLI and deploys the base-kit.
# =============================================================================
# Usage: curl -sSL base.stackkit.cc | sh
#
# This script:
#   1. Installs the stackkit CLI binary
#   2. Installs Docker and OpenTofu (if missing)
#   3. Initializes the base-kit with default settings
#   4. Deploys the full homelab stack
#
# Requirements: Linux or macOS, root/sudo access
# =============================================================================
set -eu

printf '\033[38;5;208m'
cat <<'BANNER'

     _             _    _    _ _
 ___| |_ __ _  ___| | _| | _(_) |_
/ __| __/ _` |/ __| |/ / |/ / | __|
\__ \ || (_| | (__|   <|   <| | |_
|___/\__\__,_|\___|_|\_\_|\_\_|\__|

BANNER
printf '\033[0m'

REPO="kombifyio/stackKits"
INSTALL_DIR="/usr/local/bin"
HOMELAB_DIR="$HOME/my-homelab"

# --- Admin email prompt (supports env var override) -------------------------

ADMIN_EMAIL="${STACKKIT_ADMIN_EMAIL:-}"
if [ -z "$ADMIN_EMAIL" ]; then
  echo ""
  printf '  Admin email (for login accounts): '
  read -r ADMIN_EMAIL </dev/tty
  echo ""
fi
if [ -z "$ADMIN_EMAIL" ]; then
  warn "No admin email provided — using 'admin' as username"
  ADMIN_EMAIL="admin"
fi

# --- Helpers ----------------------------------------------------------------

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
err()   { printf '\033[1;31m==> %s\033[0m\n' "$*" >&2; }
die()   { err "$*"; exit 1; }

# --- Detect platform ---------------------------------------------------------

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac

case "$OS" in
  linux|darwin) ;;
  *) die "Unsupported OS: $OS" ;;
esac

# --- Step 1: Install stackkit CLI -------------------------------------------

info "Step 1/4 -- Installing stackkit CLI"

LATEST=$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  die "Could not determine latest version. Check https://github.com/$REPO/releases"
fi

info "  Latest version: v${LATEST} (${OS}/${ARCH})"

ARCHIVE="stackkits_${LATEST}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/v${LATEST}/${ARCHIVE}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "  Downloading..."
curl -sSL "$URL" -o "$TMP/$ARCHIVE"
tar xzf "$TMP/$ARCHIVE" -C "$TMP"

if [ "$(id -u)" -eq 0 ]; then
  install -m 755 "$TMP/stackkit" "$INSTALL_DIR/stackkit"
else
  sudo install -m 755 "$TMP/stackkit" "$INSTALL_DIR/stackkit"
fi

ok "  stackkit $(stackkit version 2>/dev/null || echo v${LATEST}) installed"

# --- Step 2: Prepare system (Docker + OpenTofu) -----------------------------

info "Step 2/4 -- Preparing system (Docker + OpenTofu)"

if [ "$(id -u)" -eq 0 ]; then
  stackkit prepare
else
  sudo stackkit prepare
fi

# Ensure Docker daemon is running (prepare installs but may not start it)
if ! docker info >/dev/null 2>&1; then
  info "  Starting Docker..."
  # Check if systemd is actually running (PID 1), not just installed
  if [ -d /run/systemd/system ]; then
    if [ "$(id -u)" -eq 0 ]; then
      systemctl start docker
    else
      sudo systemctl start docker
    fi
  elif command -v service >/dev/null 2>&1; then
    if [ "$(id -u)" -eq 0 ]; then
      service docker start
    else
      sudo service docker start
    fi
  else
    # Direct start as fallback (containers, WSL, etc.)
    if [ "$(id -u)" -eq 0 ]; then
      dockerd &
    else
      sudo dockerd &
    fi
  fi
  # Wait for Docker daemon to become ready (up to 30 seconds)
  DOCKER_WAIT=0
  DOCKER_MAX_WAIT=30
  while [ "$DOCKER_WAIT" -lt "$DOCKER_MAX_WAIT" ]; do
    if docker info >/dev/null 2>&1; then
      break
    fi
    sleep 2
    DOCKER_WAIT=$((DOCKER_WAIT + 2))
    info "  Waiting for Docker daemon... (${DOCKER_WAIT}s/${DOCKER_MAX_WAIT}s)"
  done
  if docker info >/dev/null 2>&1; then
    ok "  Docker started"
  else
    die "  Could not start Docker. Start it manually and re-run: systemctl start docker"
  fi
fi

ok "  System ready"

# --- Step 3: Initialize base-kit --------------------------------------------

info "Step 3/4 -- Initializing base-kit"

mkdir -p "$HOMELAB_DIR"
cd "$HOMELAB_DIR"

stackkit init base-kit --non-interactive --force --admin-email "$ADMIN_EMAIL"

ok "  base-kit initialized in $HOMELAB_DIR"

# --- Step 4: Generate + Deploy ----------------------------------------------

info "Step 4/4 -- Deploying homelab stack"

# Clean stale deploy artifacts from previous runs
rm -rf "$HOMELAB_DIR/deploy"

stackkit generate --force
stackkit apply --auto-approve

# --- Done -------------------------------------------------------------------

# Read domain from spec (defaults to stack.local)
DOMAIN="stack.local"
if [ -f "$HOMELAB_DIR/stack-spec.yaml" ]; then
  _d=$(grep '^domain:' "$HOMELAB_DIR/stack-spec.yaml" | head -1 | awk '{print $2}' || true)
  if [ -n "$_d" ]; then DOMAIN="$_d"; fi
fi

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_SERVER_IP")

# Read generated password from tfvars
ADMIN_PASSWORD=""
if [ -f "$HOMELAB_DIR/deploy/terraform.tfvars.json" ]; then
  ADMIN_PASSWORD=$(grep '"admin_password_plaintext"' "$HOMELAB_DIR/deploy/terraform.tfvars.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)
fi

echo ""
ok "Your homelab is running!"
echo ""
printf '\033[38;5;208m'
echo "  Dashboard:  http://base.${DOMAIN}"
printf '\033[0m'
echo ""
echo "  All services are accessible at <service>.${DOMAIN}:"
echo "    http://base.${DOMAIN}         Dashboard (service overview)"
echo "    http://traefik.${DOMAIN}      Reverse proxy"
echo "    http://dokploy.${DOMAIN}      PaaS controller"
echo "    http://kuma.${DOMAIN}         Uptime monitoring"
echo "    http://auth.${DOMAIN}         Authentication (TinyAuth)"
echo ""
echo "  Login credentials:"
echo "    Email:    ${ADMIN_EMAIL}"
if [ -n "$ADMIN_PASSWORD" ]; then
  echo "    Password: ${ADMIN_PASSWORD}"
fi
echo ""
echo "  Next steps:"
echo "    1. Login at http://auth.${DOMAIN} with the credentials above"
echo "    2. Register a passkey at http://id.${DOMAIN}/login/setup"
echo "    3. Change your auto-generated password"
echo ""
if [ "$DOMAIN" = "stack.local" ]; then
  echo "  DNS setup (add to /etc/hosts on your workstation):"
  echo "    ${SERVER_IP}  base.stack.local traefik.stack.local dokploy.stack.local"
  echo "    ${SERVER_IP}  kuma.stack.local auth.stack.local whoami.stack.local"
  echo "    Or use wildcard: *.stack.local -> ${SERVER_IP}"
  echo ""
fi
echo "  Commands:"
echo "    stackkit status       Check service health"
echo "    stackkit addon list   Available add-ons"
echo "    stackkit destroy      Tear down everything"
echo ""
echo "  Project directory: $HOMELAB_DIR"
echo ""
