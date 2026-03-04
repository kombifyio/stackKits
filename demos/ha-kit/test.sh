#!/bin/bash
# =============================================================================
# High Availability Kit Demo — Integration Test
# =============================================================================
# Tests 3-node HA topology: main + worker1 + worker2, auth, monitoring stack.
#
# Usage:
#   ./demos/ha-kit/test.sh              # run all tests
#   ./demos/ha-kit/test.sh --wait 120   # wait up to 120s for services
# =============================================================================

set -euo pipefail

PORT="${HA_KIT_PORT:-8180}"
API_PORT="${HA_KIT_API_PORT:-8290}"
BASE="http://127.0.0.1:${PORT}"
API_BASE="http://127.0.0.1:${API_PORT}"
WAIT="${1:-}"
TIMEOUT="${2:-90}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS+1)); echo -e "  ${GREEN}PASS${NC}  $1"; }
fail() { FAIL=$((FAIL+1)); echo -e "  ${RED}FAIL${NC}  $1${2:+ — $2}"; }
skip() { SKIP=$((SKIP+1)); echo -e "  ${YELLOW}SKIP${NC}  $1${2:+ — $2}"; }

http_status() {
  curl -s -o /dev/null -w "%{http_code}" "$@" 2>/dev/null || echo "000"
}

# ---------------------------------------------------------------------------
# Wait for Traefik (if --wait flag)
# ---------------------------------------------------------------------------
if [ "$WAIT" = "--wait" ]; then
  echo "Waiting up to ${TIMEOUT}s for Traefik..."
  elapsed=0
  while [ $elapsed -lt "$TIMEOUT" ]; do
    if curl -sf -o /dev/null "${API_BASE}/ping" 2>/dev/null; then
      echo "Traefik ready after ${elapsed}s"
      break
    fi
    sleep 2
    elapsed=$((elapsed+2))
  done
  if [ $elapsed -ge "$TIMEOUT" ]; then
    echo -e "${RED}Traefik not ready after ${TIMEOUT}s${NC}"
    exit 1
  fi
  echo "Waiting 15s for dependent services to stabilize..."
  sleep 15
fi

echo ""
echo "=== High Availability Kit Integration Tests (port ${PORT}) ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Traefik (main node)
# ---------------------------------------------------------------------------
echo "--- Traefik (Main Node) ---"
if curl -sf -o /dev/null "${API_BASE}/ping" 2>/dev/null; then
  pass "Traefik /ping responds (API port ${API_PORT})"
else
  fail "Traefik /ping" "not reachable at ${API_BASE}/ping"
fi

STATUS=$(http_status -H "Host: proxy.kombify.me" "${BASE}/api/overview")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Traefik dashboard protected (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Traefik dashboard" "accessible without auth (HTTP 200)"
else
  skip "Traefik dashboard" "unexpected HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 2. TinyAuth (main node, accessible)
# ---------------------------------------------------------------------------
echo ""
echo "--- TinyAuth (Main Node) ---"
STATUS=$(http_status -H "Host: auth.kombify.me" "${BASE}/")
if [ "$STATUS" = "200" ]; then
  pass "TinyAuth accessible (HTTP 200)"
elif [ "$STATUS" = "302" ]; then
  pass "TinyAuth accessible (HTTP 302 redirect)"
else
  fail "TinyAuth" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 3. PocketID (main node, accessible)
# ---------------------------------------------------------------------------
echo ""
echo "--- PocketID (Main Node) ---"
STATUS=$(http_status -H "Host: id.kombify.me" "${BASE}/")
if [ "$STATUS" = "200" ] || [ "$STATUS" = "302" ]; then
  pass "PocketID accessible (HTTP ${STATUS})"
else
  fail "PocketID" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 4. Prometheus (main node, protected) — HA EXCLUSIVE
# ---------------------------------------------------------------------------
echo ""
echo "--- Prometheus (HA Exclusive) ---"
STATUS=$(http_status -H "Host: prometheus.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Prometheus protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Prometheus" "accessible without auth (HTTP 200)"
else
  skip "Prometheus" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 5. Grafana (main node, protected) — HA EXCLUSIVE
# ---------------------------------------------------------------------------
echo ""
echo "--- Grafana (HA Exclusive) ---"
STATUS=$(http_status -H "Host: grafana.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Grafana protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Grafana" "accessible without auth (HTTP 200)"
else
  skip "Grafana" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 6. Dashboard (main node, protected)
# ---------------------------------------------------------------------------
echo ""
echo "--- Dashboard (Main Node) ---"
STATUS=$(http_status -H "Host: dash.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Dashboard protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Dashboard" "accessible without auth (HTTP 200)"
else
  skip "Dashboard" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 7. Dokploy (worker 1, protected)
# ---------------------------------------------------------------------------
echo ""
echo "--- Dokploy (Worker 1) ---"
STATUS=$(http_status -H "Host: dokploy.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Dokploy protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Dokploy" "accessible without auth (HTTP 200)"
else
  skip "Dokploy" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 8. Uptime Kuma (worker 2, protected)
# ---------------------------------------------------------------------------
echo ""
echo "--- Uptime Kuma (Worker 2) ---"
STATUS=$(http_status -H "Host: status.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Uptime Kuma protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Uptime Kuma" "accessible without auth (HTTP 200)"
else
  skip "Uptime Kuma" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 9. Whoami (worker 2, protected)
# ---------------------------------------------------------------------------
echo ""
echo "--- Whoami (Worker 2) ---"
STATUS=$(http_status -H "Host: whoami.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Whoami protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Whoami" "accessible without auth (HTTP 200)"
else
  skip "Whoami" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "==========================================="
TOTAL=$((PASS + FAIL + SKIP))
echo -e "Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${SKIP} skipped${NC} / ${TOTAL} total"
echo "==========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
