#!/bin/bash
# =============================================================================
# Dev Homelab E2E Test Script
# =============================================================================
# Purpose: Validate full CLI workflow and contract compliance
# Usage: ./tests/e2e_test.sh
# 
# Environment Variables:
#   STACKKIT_BIN  - Path to stackkit binary (default: stackkit)
#   TIMEOUT       - Max wait time in seconds (default: 300)
#   WHOAMI_PORT   - Port for whoami service (default: 9080)
#   KEEP_ON_FAIL  - Keep resources on failure for debugging (default: false)
#   CI            - Set to 'true' in CI environments
#
# Exit Codes:
#   0 - All tests passed
#   1 - One or more tests failed
# =============================================================================

set -e

# Colors (disabled in CI if no TTY)
if [ -t 1 ] && [ -z "$CI" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Configuration
STACKKIT_BIN="${STACKKIT_BIN:-stackkit}"
TIMEOUT="${TIMEOUT:-300}"
WHOAMI_PORT="${WHOAMI_PORT:-9080}"
KEEP_ON_FAIL="${KEEP_ON_FAIL:-false}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$(mktemp -d)}"

# Test results
PASSED=0
FAILED=0
START_TIME=$(date +%s)

# =============================================================================
# HELPERS
# =============================================================================

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

cleanup() {
    echo -e "\n${YELLOW}[CLEANUP]${NC} Running destroy..."
    $STACKKIT_BIN destroy --auto-approve 2>/dev/null || true
}

trap cleanup EXIT

# =============================================================================
# TESTS
# =============================================================================

echo "═══════════════════════════════════════════════════════════════════"
echo "                    DEV HOMELAB E2E TESTS"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Test 1: Init
log_test "stackkit init creates valid stack-spec.yaml"
if $STACKKIT_BIN init dev-homelab --non-interactive; then
    if [ -f "stack-spec.yaml" ]; then
        log_pass "stack-spec.yaml created"
    else
        log_fail "stack-spec.yaml not found"
    fi
else
    log_fail "stackkit init failed"
fi

# Test 2: Validate
log_test "stackkit validate passes CUE validation"
if $STACKKIT_BIN validate; then
    log_pass "CUE validation passed"
else
    log_fail "CUE validation failed"
fi

# Test 3: Plan
log_test "stackkit plan generates valid OpenTofu plan"
if $STACKKIT_BIN plan; then
    log_pass "OpenTofu plan succeeded"
else
    log_fail "OpenTofu plan failed"
fi

# Test 4: Apply
log_test "stackkit apply deploys without errors"
if $STACKKIT_BIN apply --auto-approve; then
    log_pass "Deployment succeeded"
else
    log_fail "Deployment failed"
fi

# Test 5: Service Health
log_test "whoami service responds at localhost:$WHOAMI_PORT"
sleep 5  # Wait for container to start
if curl -sf "http://localhost:$WHOAMI_PORT" > /dev/null; then
    log_pass "whoami service healthy"
else
    log_fail "whoami service not responding"
fi

# Test 6: Status
log_test "stackkit status shows healthy service"
if $STACKKIT_BIN status | grep -q "healthy\|running"; then
    log_pass "Status shows healthy"
else
    log_fail "Status does not show healthy"
fi

# Test 7: Destroy
log_test "stackkit destroy removes all resources"
trap - EXIT  # Remove cleanup trap, we're testing destroy
if $STACKKIT_BIN destroy --auto-approve; then
    log_pass "Destroy succeeded"
else
    log_fail "Destroy failed"
fi

# Test 8: Verify Cleanup
log_test "No containers remain after destroy"
if ! docker ps -a | grep -q "whoami"; then
    log_pass "Container cleaned up"
else
    log_fail "Container still exists"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "                         TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════════"
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo -e "${BLUE}Duration:${NC} ${DURATION}s"
echo "═══════════════════════════════════════════════════════════════════"

# Clean up work directory if tests passed
if [ $FAILED -eq 0 ]; then
    rm -rf "$WORK_DIR"
elif [ "$KEEP_ON_FAIL" = "true" ]; then
    echo -e "${YELLOW}Work directory preserved:${NC} $WORK_DIR"
fi

if [ $FAILED -gt 0 ]; then
    exit 1
fi

exit 0
