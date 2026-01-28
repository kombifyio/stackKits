#!/usr/bin/env bash
set -euo pipefail

if [ -f /authorized_keys ] && [ -s /authorized_keys ]; then
  cat /authorized_keys > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

if [ "${AUTHORIZED_KEYS:-}" != "" ]; then
  printf '%s\n' "$AUTHORIZED_KEYS" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

ssh-keygen -A >/dev/null 2>&1 || true

mkdir -p /var/run/sshd

dockerd \
  --host=unix:///var/run/docker.sock \
  --host=tcp://0.0.0.0:2375 \
  >/var/log/dockerd.log 2>&1 &

tries=120
until docker info >/dev/null 2>&1; do
  tries=$((tries - 1))
  if [ "$tries" -le 0 ]; then
    cat /var/log/dockerd.log || true
    exit 1
  fi
  sleep 1
done

exec /usr/sbin/sshd -D -e
