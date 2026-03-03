#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# StackKits VM Management Script
# =============================================================================
# Robust start/stop/status for all VM profiles.
#
# Usage:
#   ./dev/manage-vms.sh start [profile]    Start VMs for a profile
#   ./dev/manage-vms.sh stop  [profile]    Stop VMs for a profile
#   ./dev/manage-vms.sh status             Show all VM statuses
#   ./dev/manage-vms.sh test  [profile]    Health-check all VMs in a profile
#
# Profiles:
#   base-kit        — default (vm only, no profile flag needed)
#   persistent      — persistent VM with password auth
#   modern-homelab  — cloud + local nodes (2-node hybrid)
#   all             — everything
# =============================================================================

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
cd "$(dirname "$0")/.."

log()  { printf '\033[1;34m[manage-vms]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m  ✗\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

# --- Detect port env vars to avoid conflicts ---
detect_ports() {
  # Check if common ports are in use and set overrides
  for port_var in "ORCHESTRATOR_PORT:9000:9002" "PORTAL_PORT:9001:9003"; do
    IFS=: read -r var default alt <<< "$port_var"
    if [ -z "${!var:-}" ]; then
      if ss -tlnp 2>/dev/null | grep -q ":${default} " || \
         netstat -tlnp 2>/dev/null | grep -q ":${default} "; then
        export "$var=$alt"
        warn "Port $default in use, using $alt for $var"
      fi
    fi
  done
}

# --- Wait for a container to be healthy ---
wait_healthy() {
  local container="$1"
  local timeout="${2:-120}"
  local elapsed=0

  while [ "$elapsed" -lt "$timeout" ]; do
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "not_found")
    case "$health" in
      healthy) ok "$container is healthy (${elapsed}s)"; return 0 ;;
      unhealthy) fail "$container is unhealthy"; return 1 ;;
      not_found) ;;  # container not started yet
    esac
    sleep 3
    elapsed=$((elapsed + 3))
  done
  fail "$container did not become healthy in ${timeout}s"
  docker logs --tail 20 "$container" 2>&1 || true
  return 1
}

# --- Commands ---

cmd_start() {
  local profile="${1:-base-kit}"
  detect_ports
  log "Starting profile: $profile"

  case "$profile" in
    base-kit)
      docker compose up -d vm orchestrator portal
      wait_healthy stackkits-vm 120
      ;;
    persistent)
      docker compose --profile persistent up -d vm-persistent
      wait_healthy stackkits-vm-persistent 120
      ;;
    modern-homelab)
      docker compose --profile modern-homelab up -d vm-cloud vm-local
      log "Waiting for cloud node..."
      wait_healthy stackkits-vm-cloud 120
      log "Waiting for local node..."
      wait_healthy stackkits-vm-local 120
      ;;
    all)
      docker compose --profile persistent --profile modern-homelab up -d
      wait_healthy stackkits-vm 120
      wait_healthy stackkits-vm-persistent 120 || true
      wait_healthy stackkits-vm-cloud 120 || true
      wait_healthy stackkits-vm-local 120 || true
      ;;
    *)
      fail "Unknown profile: $profile"
      echo "Valid profiles: base-kit, persistent, modern-homelab, all"
      exit 1
      ;;
  esac

  log "Profile '$profile' started successfully"
}

cmd_stop() {
  local profile="${1:-base-kit}"
  log "Stopping profile: $profile"

  case "$profile" in
    base-kit)
      docker compose stop vm orchestrator portal
      ;;
    persistent)
      docker compose --profile persistent stop vm-persistent
      ;;
    modern-homelab)
      docker compose --profile modern-homelab stop vm-cloud vm-local
      ;;
    all)
      docker compose --profile persistent --profile modern-homelab stop
      ;;
    *)
      fail "Unknown profile: $profile"
      exit 1
      ;;
  esac

  ok "Profile '$profile' stopped"
}

cmd_status() {
  log "VM Status Overview"
  echo ""
  printf '%-28s %-12s %-15s %s\n' "CONTAINER" "STATE" "HEALTH" "PORTS"
  printf '%-28s %-12s %-15s %s\n' "─────────" "─────" "──────" "─────"

  for container in stackkits-vm stackkits-vm-persistent stackkits-vm-cloud stackkits-vm-local; do
    local state health ports
    state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_created")
    health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "$container" 2>/dev/null || echo "-")
    ports=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{(index $conf 0).HostPort}}/{{$p}} {{end}}{{end}}' "$container" 2>/dev/null || echo "-")
    printf '%-28s %-12s %-15s %s\n' "$container" "$state" "$health" "${ports:-none}"
  done
  echo ""
}

cmd_test() {
  local profile="${1:-all}"
  local failures=0
  log "Testing VMs for profile: $profile"

  test_vm() {
    local container="$1" label="$2"
    local state
    state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    if [ "$state" != "running" ]; then
      warn "$label ($container): not running (state=$state)"
      return 0  # not a failure if it's not supposed to be running
    fi

    # Check health
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
    if [ "$health" = "healthy" ]; then
      ok "$label: healthy"
    else
      fail "$label: unhealthy (health=$health)"
      failures=$((failures + 1))
    fi

    # Check Docker inside the VM
    if docker exec "$container" docker info >/dev/null 2>&1; then
      ok "$label: dockerd responsive"
    else
      fail "$label: dockerd not responsive"
      failures=$((failures + 1))
    fi

    # Check SSH
    if docker exec "$container" pgrep -x sshd >/dev/null 2>&1; then
      ok "$label: sshd running"
    else
      fail "$label: sshd not running"
      failures=$((failures + 1))
    fi
  }

  case "$profile" in
    base-kit)      test_vm stackkits-vm "Base Kit VM" ;;
    persistent)    test_vm stackkits-vm-persistent "Persistent VM" ;;
    modern-homelab)
      test_vm stackkits-vm-cloud "Cloud Node (Azure sim)"
      test_vm stackkits-vm-local "Local Node"
      ;;
    all)
      test_vm stackkits-vm "Base Kit VM"
      test_vm stackkits-vm-persistent "Persistent VM"
      test_vm stackkits-vm-cloud "Cloud Node (Azure sim)"
      test_vm stackkits-vm-local "Local Node"
      ;;
  esac

  echo ""
  if [ "$failures" -gt 0 ]; then
    fail "$failures test(s) failed"
    exit 1
  else
    ok "All tests passed"
  fi
}

# --- Main ---
case "${1:-}" in
  start)  cmd_start "${2:-base-kit}" ;;
  stop)   cmd_stop  "${2:-base-kit}" ;;
  status) cmd_status ;;
  test)   cmd_test  "${2:-all}" ;;
  *)
    echo "Usage: $0 {start|stop|status|test} [profile]"
    echo ""
    echo "Profiles: base-kit, persistent, modern-homelab, all"
    exit 1
    ;;
esac
