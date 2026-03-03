#!/usr/bin/env bash
set -euo pipefail
# =============================================================================
# Start a bare Ubuntu 24.04 VM with SSH on port 7456
# Usage: ./dev/start-bare-vm.sh [start|stop|reset|status|ssh]
# SSH:   ssh root@localhost -p 7456   (password: hallo123)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="stackkits-bare-vm"
SSH_PORT="${BARE_VM_PORT:-7456}"
IMAGE_NAME="stackkits-bare-vm:latest"

log() { printf '[bare-vm] %s\n' "$*"; }

cmd_start() {
  # Already running — nothing to do
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Already running on port ${SSH_PORT}"
    log "SSH: ssh root@localhost -p ${SSH_PORT}"
    return 0
  fi

  # Exists but stopped — resume it (preserves state)
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Resuming stopped VM..."
    docker start "$CONTAINER_NAME" >/dev/null
  else
    # First time — build and create
    log "Building bare VM image..."
    docker build -t "$IMAGE_NAME" "$SCRIPT_DIR/vm-bare" -q

    log "Starting bare Ubuntu VM (SSH port ${SSH_PORT})..."
    docker run -d \
      --name "$CONTAINER_NAME" \
      --hostname bare-vm \
      -p "${SSH_PORT}:22" \
      --restart unless-stopped \
      "$IMAGE_NAME" >/dev/null
  fi

  log "Waiting for SSH..."
  local waited=0
  while ! docker exec "$CONTAINER_NAME" pgrep -x sshd >/dev/null 2>&1; do
    if [ "$waited" -ge 30 ]; then
      log "ERROR: sshd did not start in 30s"
      docker logs "$CONTAINER_NAME" --tail 20
      exit 1
    fi
    sleep 1
    waited=$((waited + 1))
  done

  log "VM ready (${waited}s)"
  log ""
  log "  SSH:   ssh root@localhost -p ${SSH_PORT}"
  log "  Pass:  hallo123"
  log ""
}

cmd_stop() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Stopping VM (state preserved)..."
    docker stop "$CONTAINER_NAME" >/dev/null
    log "Stopped. Run 'start' to resume."
  else
    log "Not running."
  fi
}

cmd_reset() {
  log "Resetting VM (all state will be lost)..."
  docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
  log "Removed. Run 'start' to create a fresh VM."
}

cmd_status() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "Running"
    docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Status}}\t{{.Ports}}"
  else
    log "Not running"
  fi
}

cmd_ssh() {
  exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p "$SSH_PORT"
}

case "${1:-start}" in
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  reset)  cmd_reset ;;
  status) cmd_status ;;
  ssh)    cmd_ssh ;;
  *)
    echo "Usage: $0 [start|stop|reset|status|ssh]"
    echo ""
    echo "  start   Start or resume the VM (preserves state)"
    echo "  stop    Stop the VM (state preserved)"
    echo "  reset   Remove the VM completely (fresh start)"
    echo "  status  Show VM status"
    echo "  ssh     SSH into the VM"
    exit 1
    ;;
esac
