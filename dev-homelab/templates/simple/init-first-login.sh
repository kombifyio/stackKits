#!/bin/bash
# =============================================================================
# Dev Homelab - First Login Initialization
# =============================================================================
# This script helps users complete the first login flow and verifies
# the deployment is working correctly.
#
# Usage:
#   ./init-first-login.sh [--check-only]
#
# Options:
#   --check-only    Only verify services, don't show login instructions
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
DOMAIN="${DOMAIN:-stack.local}"
TINYAUTH_URL="http://auth.${DOMAIN}"
DOKPLOY_URL="http://dokploy.${DOMAIN}"
TRAEFIK_URL="http://traefik.${DOMAIN}"
KUMA_URL="http://kuma.${DOMAIN}"
WHOAMI_URL="http://whoami.${DOMAIN}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
}

# Check if a service is accessible
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    if curl -sf -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "$expected_status"; then
        echo -e "  ${GREEN}✓${NC} $name: $url"
        return 0
    else
        echo -e "  ${RED}✗${NC} $name: $url (not accessible)"
        return 1
    fi
}

# Check if running inside VM or targeting VM
verify_docker_host() {
    log_info "Checking Docker daemon target..."
    
    if [ -n "${DOCKER_HOST:-}" ]; then
        log_info "DOCKER_HOST is set to: $DOCKER_HOST"
        if echo "$DOCKER_HOST" | grep -q "2375"; then
            log_success "Docker is targeting the VM (port 2375)"
            return 0
        else
            log_warn "DOCKER_HOST set but may not be targeting VM"
        fi
    fi
    
    # Check if we're inside the VM container
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        log_info "Running inside a container"
    fi
    
    return 0
}

# Check all services
check_services() {
    log_header "SERVICE STATUS CHECK"
    
    local all_ok=true
    
    echo ""
    echo -e "${BOLD}Checking Layer 1 (Foundation):${NC}"
    check_service "TinyAuth" "$TINYAUTH_URL/api/health" || all_ok=false
    
    echo ""
    echo -e "${BOLD}Checking Layer 2 (Platform):${NC}"
    check_service "Traefik Dashboard" "$TRAEFIK_URL/dashboard/" || all_ok=false
    check_service "Dokploy" "$DOKPLOY_URL/api/settings" || all_ok=false
    
    echo ""
    echo -e "${BOLD}Checking Layer 3 (Applications):${NC}"
    check_service "Kuma" "$KUMA_URL" || all_ok=false
    check_service "Whoami" "$WHOAMI_URL" || all_ok=false
    
    echo ""
    if [ "$all_ok" = true ]; then
        log_success "All services are accessible!"
        return 0
    else
        log_warn "Some services are not yet accessible"
        return 1
    fi
}

# Show first login instructions
show_first_login() {
    log_header "FIRST LOGIN INSTRUCTIONS"
    
    echo ""
    echo -e "${BOLD}Step 1: Login to TinyAuth (Identity Provider)${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  URL:      ${CYAN}$TINYAUTH_URL${NC}"
    echo -e "  Username: ${CYAN}admin${NC}"
    echo -e "  Password: ${CYAN}admin123${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠️  IMPORTANT: Change the password immediately after first login!${NC}"
    echo ""
    
    echo -e "${BOLD}Step 2: Access Dokploy (via TinyAuth SSO)${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  URL: ${CYAN}$DOKPLOY_URL${NC}"
    echo ""
    echo "  You'll be automatically redirected to TinyAuth for authentication."
    echo "  After logging in, you'll be redirected back to Dokploy."
    echo ""
    
    echo -e "${BOLD}Step 3: Access Other Services${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  Traefik Dashboard: ${CYAN}$TRAEFIK_URL${NC}"
    echo -e "  Uptime Kuma:       ${CYAN}$KUMA_URL${NC}"
    echo -e "  Whoami Test:       ${CYAN}$WHOAMI_URL${NC}"
    echo ""
    echo "  All services are protected by TinyAuth SSO."
    echo ""
}

# Show verification commands
show_verification() {
    log_header "VERIFICATION COMMANDS"
    
    echo ""
    echo -e "${BOLD}Verify VM-Only Deployment:${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo "  # On Windows host - should show ONLY the VM container:"
    echo -e "  ${CYAN}docker ps${NC}"
    echo ""
    echo "  # Inside the VM - should show ALL services:"
    echo -e "  ${CYAN}docker compose exec vm docker ps${NC}"
    echo ""
    echo "  # Or using DOCKER_HOST:"
    echo -e "  ${CYAN}DOCKER_HOST=tcp://localhost:2375 docker ps${NC}"
    echo ""
}

# Main execution
main() {
    local check_only=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --check-only)
                check_only=true
                shift
                ;;
        esac
    done
    
    log_header "DEV HOMELAB - FIRST LOGIN SETUP"
    
    verify_docker_host
    
    if [ "$check_only" = false ]; then
        show_first_login
    fi
    
    check_services
    
    if [ "$check_only" = false ]; then
        show_verification
        
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  Setup complete! Access your services at the URLs above.${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
        echo ""
    fi
}

# Run main
main "$@"
