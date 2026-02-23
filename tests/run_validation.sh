#!/bin/bash
# =============================================================================
# VALIDATION TEST RUNNER
# =============================================================================
# Runs all CUE validation tests for the 3-layer architecture
#
# Usage: ./tests/run_validation.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   StackKits 3-Layer Validation Tests  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track test results
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_file="$2"
    
    echo -n "Testing: $test_name... "
    
    if cue vet "$test_file" 2>/dev/null; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
        # Show error details
        echo -e "${YELLOW}Error details:${NC}"
        cue vet "$test_file" 2>&1 | head -20
        echo ""
    fi
}

# Function to run eval test (check output)
run_eval_test() {
    local test_name="$1"
    local test_expr="$2"
    
    echo -n "Testing: $test_name... "
    
    if cue eval "$test_expr" >/dev/null 2>&1; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
    fi
}

cd "$PROJECT_ROOT"

# =============================================================================
# LAYER 1 (CORE) TESTS
# =============================================================================
echo -e "\n${YELLOW}Layer 1 - CORE Tests${NC}"
echo "-------------------------------------------"

run_test "Base schema" "base/stackkit.cue"
run_test "Security schema" "base/security.cue"
run_test "Network schema" "base/network.cue"
run_test "Observability schema" "base/observability.cue"
run_test "System schema" "base/system.cue"

# =============================================================================
# LAYER 2 (PLATFORM) TESTS
# =============================================================================
echo -e "\n${YELLOW}Layer 2 - PLATFORM Tests${NC}"
echo "-------------------------------------------"

run_test "Docker platform schema" "platforms/docker/platform.cue"

# =============================================================================
# LAYER 3 (STACKKIT) TESTS
# =============================================================================
echo -e "\n${YELLOW}Layer 3 - STACKKIT Tests${NC}"
echo "-------------------------------------------"

run_test "base-homelab stackfile" "stackkits/base-homelab/stackfile.cue"

# Check if old location still exists (backward compatibility)
if [ -f "base-homelab/stackfile.cue" ]; then
    run_test "base-homelab (legacy location)" "base-homelab/stackfile.cue"
fi

# =============================================================================
# INTEGRATION TESTS
# =============================================================================
echo -e "\n${YELLOW}Integration Tests${NC}"
echo "-------------------------------------------"

run_test "Full validation suite" "tests/validation_test.cue"

# =============================================================================
# TEMPLATE SYNTAX TESTS
# =============================================================================
echo -e "\n${YELLOW}Template Syntax Tests${NC}"
echo "-------------------------------------------"

# Check Terraform templates for basic syntax (HCL)
check_template() {
    local template="$1"
    local name=$(basename "$template")
    
    echo -n "Checking: $name... "
    
    # Basic check: ensure file exists and has content
    if [ -f "$template" ] && [ -s "$template" ]; then
        # Check for basic Terraform constructs
        if grep -q -E '(variable|resource|output|locals)' "$template"; then
            echo -e "${GREEN}OK${NC}"
            ((PASSED++))
        else
            echo -e "${YELLOW}WARNING: No Terraform constructs found${NC}"
        fi
    else
        echo -e "${RED}MISSING${NC}"
        ((FAILED++))
    fi
}

# Layer 1 templates
check_template "base/bootstrap/_bootstrap.tf.tmpl"
check_template "base/security/_firewall.tf.tmpl"
check_template "base/security/_ssh.tf.tmpl"
check_template "base/security/_fail2ban.tf.tmpl"
check_template "base/observability/_health.tf.tmpl"

# Layer 2 templates
check_template "platforms/docker/_docker.tf.tmpl"
check_template "platforms/docker/_traefik.tf.tmpl"

# Layer 3 templates
check_template "stackkits/base-homelab/templates/services/_dokploy.tf.tmpl"
check_template "stackkits/base-homelab/templates/services/_uptimekuma.tf.tmpl"
check_template "stackkits/base-homelab/templates/services/_beszel.tf.tmpl"
check_template "stackkits/base-homelab/templates/services/_minimal.tf.tmpl"

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}              Test Summary              ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total Passed: ${GREEN}$PASSED${NC}"
echo -e "Total Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    exit 1
fi
