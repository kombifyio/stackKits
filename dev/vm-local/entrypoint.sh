#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# StackKits Local VM Entrypoint — Simulated On-Premises Server
# =============================================================================
# Simulates a local homelab server for the modern-homelab local node.
# Password auth enabled (like a physical machine).
# =============================================================================

LABEL="${VM_LABEL:-vm-local}"
log() { printf '[%s] [%s] %s\n' "$(date -u +%H:%M:%S)" "$LABEL" "$*"; }

DOCKERD_PID=""
cleanup() {
  log "Shutting down..."
  if [ -n "$DOCKERD_PID" ] && kill -0 "$DOCKERD_PID" 2>/dev/null; then
    log "Stopping dockerd (pid=$DOCKERD_PID)..."
    kill -TERM "$DOCKERD_PID" 2>/dev/null || true
    wait "$DOCKERD_PID" 2>/dev/null || true
  fi
  log "Goodbye."
  exit 0
}
trap cleanup SIGTERM SIGINT SIGQUIT

# --- SSH authorized_keys ---
mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -f /authorized_keys ] && [ -s /authorized_keys ]; then
  cat /authorized_keys > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  log "SSH keys loaded from /authorized_keys"
fi

if [ "${AUTHORIZED_KEYS:-}" != "" ]; then
  printf '%s\n' "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  log "SSH keys loaded from AUTHORIZED_KEYS env"
fi

ssh-keygen -A >/dev/null 2>&1 || true
mkdir -p /var/run/sshd

# --- Start Docker daemon ---
rm -f /var/run/docker.pid

log "Starting dockerd..."
dockerd \
  --host=unix:///var/run/docker.sock \
  --host=tcp://0.0.0.0:2375 \
  ${DOCKER_OPTS:-} \
  >>/var/log/dockerd.log 2>&1 &
DOCKERD_PID=$!

MAX_WAIT=120
waited=0
backoff=1
while ! docker info >/dev/null 2>&1; do
  if ! kill -0 "$DOCKERD_PID" 2>/dev/null; then
    log "ERROR: dockerd exited unexpectedly"
    cat /var/log/dockerd.log 2>/dev/null || true
    exit 1
  fi
  if [ "$waited" -ge "$MAX_WAIT" ]; then
    log "ERROR: dockerd did not become ready in ${MAX_WAIT}s"
    cat /var/log/dockerd.log 2>/dev/null || true
    exit 1
  fi
  sleep "$backoff"
  waited=$((waited + backoff))
  backoff=$((backoff < 5 ? backoff + 1 : 5))
done

log "dockerd ready (waited ${waited}s, pid=$DOCKERD_PID)"
log "Starting sshd..."
exec /usr/sbin/sshd -D -e
