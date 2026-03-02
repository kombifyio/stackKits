#!/bin/sh
# =============================================================================
# StackKits CLI Installer
# =============================================================================
# Usage:
#   curl -sSL https://raw.githubusercontent.com/kombifyio/stackKits/main/install.sh | sh
#
# What it does:
#   1. Detects your OS and architecture
#   2. Downloads the latest stackkit binary + kit definitions from GitHub Releases
#   3. Installs the binary to /usr/local/bin (or ~/.local/bin)
#   4. Installs kit definitions to ~/.stackkits/
#
# After install:
#   stackkit init base-kit
#   stackkit apply --auto-approve
# =============================================================================
set -eu

REPO="kombifyio/stackKits"
BINARY_NAME="stackkit"
ARCHIVE_PREFIX="stackkits"
KITS_DIR="${HOME}/.stackkits"

log() { printf '\033[1;36m[stackkit]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[stackkit]\033[0m %s\n' "$*" >&2; exit 1; }

# --- Detect OS and architecture -----------------------------------------------

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)  OS="linux" ;;
  darwin) OS="darwin" ;;
  *)      err "Unsupported OS: $OS (supported: linux, darwin)" ;;
esac

case "$ARCH" in
  x86_64|amd64)  ARCH="amd64" ;;
  aarch64|arm64)  ARCH="arm64" ;;
  *)              err "Unsupported architecture: $ARCH (supported: amd64, arm64)" ;;
esac

log "Detected: ${OS}/${ARCH}"

# --- Determine install directory -----------------------------------------------

if [ "$(id -u)" = "0" ]; then
  INSTALL_DIR="/usr/local/bin"
else
  INSTALL_DIR="${HOME}/.local/bin"
  mkdir -p "$INSTALL_DIR"
fi

# --- Fetch latest release tag -------------------------------------------------

log "Fetching latest release..."
LATEST_TAG=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
  err "Could not determine latest release. Check https://github.com/${REPO}/releases"
fi

VERSION="${LATEST_TAG#v}"
log "Latest version: ${VERSION}"

# --- Download and extract ------------------------------------------------------

ARCHIVE="${ARCHIVE_PREFIX}_${VERSION}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ARCHIVE}"

log "Downloading ${ARCHIVE}..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

HTTP_CODE=$(curl -sSL -w "%{http_code}" -o "${TMP_DIR}/${ARCHIVE}" "$URL")
if [ "$HTTP_CODE" != "200" ]; then
  err "Download failed (HTTP ${HTTP_CODE}): ${URL}"
fi

log "Extracting..."
tar -xzf "${TMP_DIR}/${ARCHIVE}" -C "$TMP_DIR"

if [ ! -f "${TMP_DIR}/${BINARY_NAME}" ]; then
  err "Binary '${BINARY_NAME}' not found in archive"
fi

# --- Install binary ------------------------------------------------------------

log "Installing binary to ${INSTALL_DIR}/${BINARY_NAME}..."
mv "${TMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

# --- Install kit definitions ---------------------------------------------------

log "Installing kit definitions to ${KITS_DIR}/..."
mkdir -p "$KITS_DIR"

# Copy kit directories (base-kit, base schemas) from archive
for kit_dir in "$TMP_DIR"/base-kit "$TMP_DIR"/base; do
  if [ -d "$kit_dir" ]; then
    kit_name=$(basename "$kit_dir")
    rm -rf "${KITS_DIR}/${kit_name}"
    cp -r "$kit_dir" "${KITS_DIR}/${kit_name}"
  fi
done

# --- Verify --------------------------------------------------------------------

log ""
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
  log "stackkit installed successfully!"
  log "  Binary: ${INSTALL_DIR}/${BINARY_NAME}"
  log "  Kits:   ${KITS_DIR}/"
else
  log "stackkit installed to ${INSTALL_DIR}/${BINARY_NAME}"
  if [ "$INSTALL_DIR" = "${HOME}/.local/bin" ]; then
    log ""
    log "  Add to your PATH if not already:"
    log "    export PATH=\"\${HOME}/.local/bin:\${PATH}\""
  fi
fi

log ""
log "Get started:"
log "  stackkit init base-kit"
log "  stackkit apply --auto-approve"
log ""
