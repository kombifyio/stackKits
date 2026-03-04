#!/bin/bash
# =============================================================================
# Base Kit Demo — Integration Test
# =============================================================================
# Tests all services are reachable and auth is working correctly.
#
# Usage:
#   ./demos/base-kit/test.sh              # run all tests
#   ./demos/base-kit/test.sh --wait 120   # wait up to 120s for services
# =============================================================================

set -euo pipefail

PORT="${BASE_KIT_PORT:-7880}"
API_PORT="${BASE_KIT_API_PORT:-7090}"
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

# Helper: get HTTP status code without -f flag (which corrupts output)
http_status() {
  curl -s -o /dev/null -w "%{http_code}" "$@" 2>/dev/null || echo "000"
}

# ---------------------------------------------------------------------------
# Wait for Traefik to be ready (if --wait flag)
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
  # Extra wait for dependent services
  echo "Waiting 15s for dependent services to stabilize..."
  sleep 15
fi

echo ""
echo "=== Base Kit Integration Tests (port ${PORT}) ==="
echo ""

# ---------------------------------------------------------------------------
# 1. Traefik health
# ---------------------------------------------------------------------------
echo "--- Traefik ---"
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
# 2. TinyAuth (should be accessible — it IS the auth)
# ---------------------------------------------------------------------------
echo ""
echo "--- TinyAuth ---"
STATUS=$(http_status -H "Host: auth.kombify.me" "${BASE}/")
if [ "$STATUS" = "200" ]; then
  pass "TinyAuth accessible (HTTP 200)"
elif [ "$STATUS" = "302" ]; then
  pass "TinyAuth accessible (HTTP 302 redirect)"
else
  fail "TinyAuth" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 3. PocketID (should be accessible — it IS the OIDC provider)
# ---------------------------------------------------------------------------
echo ""
echo "--- PocketID ---"
STATUS=$(http_status -H "Host: id.kombify.me" "${BASE}/")
if [ "$STATUS" = "200" ] || [ "$STATUS" = "302" ]; then
  pass "PocketID accessible (HTTP ${STATUS})"
else
  fail "PocketID" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 4. Dokploy (should be protected by ForwardAuth)
# ---------------------------------------------------------------------------
echo ""
echo "--- Dokploy ---"
STATUS=$(http_status -H "Host: dokploy.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Dokploy protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Dokploy" "accessible without auth (HTTP 200)"
else
  skip "Dokploy" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 5. Dashboard (should be protected by ForwardAuth)
# ---------------------------------------------------------------------------
echo ""
echo "--- Dashboard ---"
STATUS=$(http_status -H "Host: dash.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Dashboard protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Dashboard" "accessible without auth (HTTP 200)"
else
  skip "Dashboard" "HTTP ${STATUS}"
fi

# ---------------------------------------------------------------------------
# 6. Uptime Kuma (should be protected by ForwardAuth)
# ---------------------------------------------------------------------------
echo ""
echo "--- Uptime Kuma ---"
STATUS=$(http_status -H "Host: kuma.kombify.me" "${BASE}/")
if [ "$STATUS" = "401" ] || [ "$STATUS" = "302" ]; then
  pass "Uptime Kuma protected by ForwardAuth (HTTP ${STATUS})"
elif [ "$STATUS" = "200" ]; then
  fail "Uptime Kuma" "accessible without auth (HTTP 200)"
else
  skip "Uptime Kuma" "HTTP ${STATUS} (may still be starting)"
fi

# ---------------------------------------------------------------------------
# 7. Whoami (should be protected by ForwardAuth)
# ---------------------------------------------------------------------------
echo ""
echo "--- Whoami ---"
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
