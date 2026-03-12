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

ADMIN_EMAIL="${STACKKIT_ADMIN_EMAIL:-${KOMBIFY_USER_EMAIL:-}}"
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

ARCHIVE="stackkits-base-kit_${LATEST}_${OS}_${ARCH}.tar.gz"
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

# Install bundled kit definitions so stackkit init can find them
STACKKITS_DIR="$HOME/.stackkits"
mkdir -p "$STACKKITS_DIR"
if [ -d "$TMP/base-kit" ]; then
  cp -r "$TMP/base-kit" "$STACKKITS_DIR/"
  info "  Installed base-kit to $STACKKITS_DIR/base-kit"
fi
if [ -d "$TMP/base" ]; then
  cp -r "$TMP/base" "$STACKKITS_DIR/"
  # Also place inside base-kit/ so CUE module resolution finds it
  # (CUE module root is base-kit/, so it looks for "base" at base-kit/base/)
  cp -r "$TMP/base" "$STACKKITS_DIR/base-kit/"
fi

ok "  stackkit $(stackkit version 2>/dev/null || echo v${LATEST}) installed"

# --- Step 2: Prepare system (Docker + OpenTofu) -----------------------------

info "Step 2/4 -- Preparing system (Docker + OpenTofu)"

if [ "$(id -u)" -eq 0 ]; then
  stackkit prepare || die "System preparation failed. Check errors above."
else
  sudo stackkit prepare || die "System preparation failed. Check errors above."
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

# Read subdomain prefix from tfvars (for kombify.me mode)
SUBDOMAIN_PREFIX=""
if [ -f "$HOMELAB_DIR/deploy/terraform.tfvars.json" ]; then
  SUBDOMAIN_PREFIX=$(grep '"subdomain_prefix"' "$HOMELAB_DIR/deploy/terraform.tfvars.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)
fi

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR_SERVER_IP")

# Read generated password from tfvars
ADMIN_PASSWORD=""
if [ -f "$HOMELAB_DIR/deploy/terraform.tfvars.json" ]; then
  ADMIN_PASSWORD=$(grep '"admin_password_plaintext"' "$HOMELAB_DIR/deploy/terraform.tfvars.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)
fi

# Detect network environment: is this a public server or a home network?
# A public server has its public IP directly on an interface.
NETWORK_ENV="unknown"
PUBLIC_IP=$(curl -sSL --max-time 5 https://ifconfig.me/ip 2>/dev/null || true)
if [ -n "$PUBLIC_IP" ]; then
  if ip addr 2>/dev/null | grep -qF "$PUBLIC_IP"; then
    NETWORK_ENV="vps"
  else
    NETWORK_ENV="home"
  fi
fi

# Check if deployed via kombify Cloud
if [ "${KOMBIFY_CONTEXT:-}" = "cloud" ] || [ -f /etc/kombify/context ] && [ "$(cat /etc/kombify/context 2>/dev/null)" = "cloud" ]; then
  NETWORK_ENV="cloud"
fi

# Warn if local domain on a VPS — services won't be reachable
if [ "$NETWORK_ENV" = "vps" ] || [ "$NETWORK_ENV" = "cloud" ]; then
  case "$DOMAIN" in
    *.local|*.lab|*.lan|*.home|*.internal|*.test|stack.local|home.lab|homelab)
      echo ""
      warn "WARNING: Local domain '$DOMAIN' is not reachable on a public server!"
      echo ""
      echo "  Your server has a public IP ($PUBLIC_IP) but services are configured with"
      echo "  a local domain that only works on home networks with dnsmasq."
      echo ""
      echo "  To fix: edit $HOMELAB_DIR/stack-spec.yaml and set:"
      echo "    domain: kombify.me     (free public subdomain via kombify.me)"
      echo "    domain: yourdomain.com (your own domain with DNS configured)"
      echo ""
      echo "  Then re-deploy:"
      echo "    cd $HOMELAB_DIR && stackkit generate --force && stackkit apply --auto-approve"
      echo ""
      ;;
  esac
fi

# Build service URLs based on domain mode
if [ -n "$SUBDOMAIN_PREFIX" ] && [ "$DOMAIN" = "kombify.me" ]; then
  # kombify.me flat naming mode
  PROTO="https"
  DASH_URL="${PROTO}://${SUBDOMAIN_PREFIX}-dash.${DOMAIN}"
  TRAEFIK_URL="${PROTO}://${SUBDOMAIN_PREFIX}-traefik.${DOMAIN}"
  DOKPLOY_URL="${PROTO}://${SUBDOMAIN_PREFIX}-dokploy.${DOMAIN}"
  KUMA_URL="${PROTO}://${SUBDOMAIN_PREFIX}-kuma.${DOMAIN}"
  AUTH_URL="${PROTO}://${SUBDOMAIN_PREFIX}-tinyauth.${DOMAIN}"
  ID_URL="${PROTO}://${SUBDOMAIN_PREFIX}-id.${DOMAIN}"
  URL_PATTERN="<service> at ${SUBDOMAIN_PREFIX}-<service>.${DOMAIN}"
else
  # Standard nested naming mode
  PROTO="http"
  DASH_URL="${PROTO}://base.${DOMAIN}"
  TRAEFIK_URL="${PROTO}://traefik.${DOMAIN}"
  DOKPLOY_URL="${PROTO}://dokploy.${DOMAIN}"
  KUMA_URL="${PROTO}://kuma.${DOMAIN}"
  AUTH_URL="${PROTO}://auth.${DOMAIN}"
  ID_URL="${PROTO}://id.${DOMAIN}"
  URL_PATTERN="<service>.${DOMAIN}"
fi

echo ""
ok "Your homelab is running!"
echo ""
printf '\033[38;5;208m'
echo "  Dashboard:  ${DASH_URL}"
printf '\033[0m'
echo ""
echo "  All services are accessible at ${URL_PATTERN}:"
echo "    ${DASH_URL}         Dashboard (service overview)"
echo "    ${TRAEFIK_URL}      Reverse proxy"
echo "    ${DOKPLOY_URL}      PaaS controller"
echo "    ${KUMA_URL}         Uptime monitoring"
echo "    ${AUTH_URL}         Authentication (TinyAuth)"
echo ""
echo "  Login credentials:"
echo "    Email:    ${ADMIN_EMAIL}"
if [ -n "$ADMIN_PASSWORD" ]; then
  echo "    Password: ${ADMIN_PASSWORD}"
fi
echo ""
echo "  Next steps:"
echo "    1. Login at ${AUTH_URL} with the credentials above"
echo "    2. Register a passkey at ${ID_URL}/login/setup"
echo "    3. Change your auto-generated password"
echo ""
if [ "$DOMAIN" = "kombify.me" ] && [ -n "$SUBDOMAIN_PREFIX" ]; then
  echo "  DNS: Managed by kombify.me (Cloudflare wildcard)"
  echo ""
elif [ "$DOMAIN" = "stack.local" ] || [ "$DOMAIN" = "home.lab" ]; then
  echo "  DNS setup (add to /etc/hosts on your workstation):"
  echo "    ${SERVER_IP}  base.${DOMAIN} traefik.${DOMAIN} dokploy.${DOMAIN}"
  echo "    ${SERVER_IP}  kuma.${DOMAIN} auth.${DOMAIN} whoami.${DOMAIN}"
  echo "    Or use wildcard: *.${DOMAIN} -> ${SERVER_IP}"
  echo ""
fi
echo "  Commands:"
echo "    stackkit status       Check service health"
echo "    stackkit addon list   Available add-ons"
echo "    stackkit remove       Tear down everything"
echo ""
echo "  Project directory: $HOMELAB_DIR"
echo ""
