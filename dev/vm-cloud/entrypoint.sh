#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# StackKits Cloud VM Entrypoint — Simulated Azure/Cloud VPS
# =============================================================================
# Simulates a cloud VPS (Azure, Hetzner, etc.) for the modern-homelab cloud
# node. Identical capabilities to a real cloud VM: Docker, SSH, public-facing.
#
# Environment:
#   VM_LABEL            — label for logs (default: vm-cloud)
#   CLOUD_PROVIDER_SIM  — simulated provider name (default: azure)
#   CLOUD_REGION_SIM    — simulated region (default: westeurope)
#   DOCKER_OPTS         — extra dockerd args
# =============================================================================

LABEL="${VM_LABEL:-vm-cloud}"
PROVIDER="${CLOUD_PROVIDER_SIM:-azure}"
REGION="${CLOUD_REGION_SIM:-westeurope}"
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

# --- Metadata endpoint (simulates Azure IMDS / cloud metadata) ---
mkdir -p /var/run/kombify-sim
cat > /var/run/kombify-sim/metadata.json << EOF
{
  "provider": "$PROVIDER",
  "region": "$REGION",
  "instance_type": "${CLOUD_INSTANCE_TYPE:-Standard_B2s}",
  "instance_id": "sim-$(hostname)",
  "public_ip": "$(hostname -i 2>/dev/null | awk '{print $1}' || echo '10.0.0.1')",
  "private_ip": "$(hostname -i 2>/dev/null | awk '{print $1}' || echo '10.0.0.1')",
  "simulated": true,
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
log "Cloud VM simulation: provider=$PROVIDER region=$REGION"

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

# --- Simple metadata HTTP endpoint on port 8169 (like Azure IMDS on 169.254.169.254) ---
# Serves /metadata as a simple health + info endpoint
while true; do
  echo -ne "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n$(cat /var/run/kombify-sim/metadata.json)" \
    | nc -l -p 8169 -q 1 >/dev/null 2>&1 || true
done &
METADATA_PID=$!
log "Metadata endpoint on :8169/metadata (pid=$METADATA_PID)"

# --- Start SSH daemon (foreground) ---
log "Starting sshd..."
exec /usr/sbin/sshd -D -e
