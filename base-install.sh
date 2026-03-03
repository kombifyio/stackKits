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

REPO="kombifyio/stackKits"
INSTALL_DIR="/usr/local/bin"
HOMELAB_DIR="$HOME/my-homelab"

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

ok "  System ready"

# --- Step 3: Initialize base-kit --------------------------------------------

info "Step 3/4 -- Initializing base-kit"

mkdir -p "$HOMELAB_DIR"
cd "$HOMELAB_DIR"

stackkit init base-kit --non-interactive

ok "  base-kit initialized in $HOMELAB_DIR"

# --- Step 4: Deploy ---------------------------------------------------------

info "Step 4/4 -- Deploying homelab stack"

stackkit apply --auto-approve

# --- Done -------------------------------------------------------------------

echo ""
ok "Your homelab is running!"
echo ""
echo "  Directory:  $HOMELAB_DIR"
echo "  Status:     stackkit status"
echo "  Add-ons:    stackkit addon list"
echo "  Tear down:  stackkit destroy"
echo ""
echo "  Customize:  Edit $HOMELAB_DIR/stack-spec.yaml, then run stackkit apply"
echo ""
