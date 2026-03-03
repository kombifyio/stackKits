#!/bin/sh
# StackKits installer — installs the stackkit CLI binary.
# Usage: curl -sSL install.kombify.me | sh
set -eu

REPO="kombifyio/stackKits"
INSTALL_DIR="/usr/local/bin"

# --- Detect platform ---------------------------------------------------------

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Error: unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
  linux|darwin) ;;
  *) echo "Error: unsupported OS: $OS" >&2; exit 1 ;;
esac

# --- Resolve latest version ---------------------------------------------------

echo "Resolving latest stackkit release..."
LATEST=$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "Error: could not determine latest version." >&2
  echo "Check https://github.com/$REPO/releases" >&2
  exit 1
fi

echo "  -> v${LATEST} (${OS}/${ARCH})"

# --- Download and install stackkit --------------------------------------------

ARCHIVE="stackkits_${LATEST}_${OS}_${ARCH}.tar.gz"
URL="https://github.com/$REPO/releases/download/v${LATEST}/${ARCHIVE}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading ${URL}..."
curl -sSL "$URL" -o "$TMP/$ARCHIVE"
tar xzf "$TMP/$ARCHIVE" -C "$TMP"

if [ "$(id -u)" -eq 0 ]; then
  install -m 755 "$TMP/stackkit" "$INSTALL_DIR/stackkit"
else
  echo "  -> Need sudo to install to $INSTALL_DIR"
  sudo install -m 755 "$TMP/stackkit" "$INSTALL_DIR/stackkit"
fi

# --- Done ---------------------------------------------------------------------

echo ""
stackkit version
echo ""
echo "Ready. Next:"
echo "  stackkit init base-kit && stackkit apply --auto-approve"
