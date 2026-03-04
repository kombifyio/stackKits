#!/usr/bin/env bash
# =============================================================================
# Sync curated files from private dev repo to public kombifyio/stackKits
# =============================================================================
# Usage:
#   ./scripts/sync-public.sh                    # sync and push
#   ./scripts/sync-public.sh --dry-run          # show what would change
#   PUBLIC_REPO_TOKEN=ghp_... ./scripts/sync-public.sh  # CI mode
#
# Whitelist approach: only explicitly listed files/dirs are synced.
# New files added to the private repo default to private-only.
# To publish a new file, add it to the INCLUDE array below.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUBLIC_REPO="kombifyio/stackKits"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

# --- Whitelist: only these files/dirs go to the public repo -----------------
# Directories MUST end with /
# Files are listed as-is

INCLUDE=(
  # Go source code (buildable from source)
  cmd/
  internal/
  pkg/
  api/

  # Build files
  go.mod
  go.sum
  Makefile
  Dockerfile
  .gitignore
  .gitattributes
  .mise.toml

  # Kit definitions (the main product)
  base/
  base-kit/
  ha-kit/
  modern-homelab/
  addons/
  modules/
  platforms/
  cue.mod/

  # Documentation and examples
  docs/
  demos/
  README.md
  LICENSE
  CONTRIBUTING.md

  # Installer scripts
  base-install.sh
  install.sh

  # Tests
  tests/

  # Release config (needed for GoReleaser on public repo)
  .goreleaser.yaml
  .golangci.yml
  .env.example

  # CI — only the release workflow (runs on tag push)
  .github/workflows/release.yml
)

# --- Helpers ----------------------------------------------------------------

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m==> %s\033[0m\n' "$*"; }
err()   { printf '\033[1;31m==> %s\033[0m\n' "$*" >&2; }
die()   { err "$*"; exit 1; }

# --- Setup ------------------------------------------------------------------

# Determine auth for public repo
if [ -n "${PUBLIC_REPO_TOKEN:-}" ]; then
  CLONE_URL="https://x-access-token:${PUBLIC_REPO_TOKEN}@github.com/${PUBLIC_REPO}.git"
elif gh auth token >/dev/null 2>&1; then
  TOKEN=$(gh auth token)
  CLONE_URL="https://x-access-token:${TOKEN}@github.com/${PUBLIC_REPO}.git"
else
  die "No authentication available. Set PUBLIC_REPO_TOKEN or run 'gh auth login'."
fi

# Create temp directory for public repo clone
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

info "Cloning public repo: $PUBLIC_REPO"
git clone --depth=1 "$CLONE_URL" "$TMP/public" 2>&1 | grep -v 'x-access-token'

# --- Sync files -------------------------------------------------------------

info "Syncing whitelisted files..."

# Remove everything except .git from public clone
find "$TMP/public" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# Copy whitelisted items preserving directory structure
for item in "${INCLUDE[@]}"; do
  src="$REPO_ROOT/$item"

  if [ ! -e "$src" ]; then
    continue
  fi

  if [[ "$item" == */ ]]; then
    # Directory: copy recursively, preserving path
    mkdir -p "$TMP/public/$item"
    cp -a "$src"/* "$TMP/public/$item/" 2>/dev/null || true
    # Also copy hidden files (dotfiles within the directory)
    cp -a "$src"/.[!.]* "$TMP/public/$item/" 2>/dev/null || true
  else
    # File: create parent dir and copy
    mkdir -p "$TMP/public/$(dirname "$item")"
    cp -a "$src" "$TMP/public/$item"
  fi
done

# --- Check for changes ------------------------------------------------------

cd "$TMP/public"

# Stage everything to see the diff
git add -A

if git diff --cached --quiet; then
  ok "Public repo is already in sync. Nothing to do."
  exit 0
fi

info "Changes detected:"
git diff --cached --stat

if [ "$DRY_RUN" = true ]; then
  info "Dry run — not pushing. Changes above would be applied."
  echo ""
  info "Files that would be on public repo:"
  git ls-files --cached | head -50
  COUNT=$(git ls-files --cached | wc -l)
  if [ "$COUNT" -gt 50 ]; then
    echo "  ... and $((COUNT - 50)) more"
  fi
  exit 0
fi

# --- Commit and push --------------------------------------------------------

# Use the latest commit message from private repo as reference
PRIVATE_HEAD=$(cd "$REPO_ROOT" && git log -1 --format='%H' HEAD)
PRIVATE_MSG=$(cd "$REPO_ROOT" && git log -1 --format='%s' HEAD)

git commit -m "sync: ${PRIVATE_MSG}

Synced from KombiverseLabs/kombify-StackKits@${PRIVATE_HEAD:0:8}
"

git push origin main

ok "Public repo synced successfully."
echo ""
info "View: https://github.com/${PUBLIC_REPO}"
