#!/bin/bash
# =============================================================================
# StackKit Base Kit - VM Deployment Script (Robust Version)
# =============================================================================
# This script automates the correct deployment flow with comprehensive
# validation, error handling, and recovery mechanisms.
#
# Architecture:
#   - VM runs Ubuntu with Docker daemon exposed on port 2375
#   - StackKit CLI deploys services INTO the VM (not on host)
#   - All validation happens before deployment
#
# Usage:
#   ./deploy-to-vm.sh [options]
#
# Options:
#   --skip-build      Skip building the CLI
#   --skip-vm         Skip VM startup (assume already running)
#   --with-dns        Start DNS service for .stack.local domains
#   --force           Force redeployment even if services exist
#   --validate-only   Only run validation, don't deploy
#   --fix-ports       Auto-adjust ports if conflicts detected
# =============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Flags
SKIP_BUILD=false
SKIP_VM=false
WITH_DNS=false
FORCE=false
VALIDATE_ONLY=false
FIX_PORTS=false

# Configuration (with defaults)
DOMAIN="${DOMAIN:-stack.local}"
VM_SSH_PORT="${VM_SSH_PORT:-2222}"
VM_DOCKER_PORT="${VM_DOCKER_PORT:-2375}"
VM_HTTP_PORT="${VM_HTTP_PORT:-10080}"
VM_HTTPS_PORT="${VM_HTTPS_PORT:-10443}"
VM_TRAEFIK_PORT="${VM_TRAEFIK_PORT:-19080}"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-build) SKIP_BUILD=true ;;
        --skip-vm) SKIP_VM=true ;;
        --with-dns) WITH_DNS=true ;;
        --force) FORCE=true ;;
        --validate-only) VALIDATE_ONLY=true ;;
        --fix-ports) FIX_PORTS=true ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-build      Skip building the CLI"
            echo "  --skip-vm         Skip VM startup (assume already running)"
            echo "  --with-dns        Start DNS service for .stack.local domains"
            echo "  --force           Force redeployment even if services exist"
            echo "  --validate-only   Only run validation, don't deploy"
            echo "  --fix-ports       Auto-adjust ports if conflicts detected"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
    esac
done

# =============================================================================
# Logging Functions
# =============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  STEP $1: $2${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# =============================================================================
# Validation Functions
# =============================================================================

# Check if a port is already in use on the host
check_port_conflict() {
    local port=$1
    local name=$2

    if netstat -an 2>/dev/null | grep -q ":${port} "; then
        log_error "Port conflict detected: $name port $port is already in use"
        return 1
    fi

    # Try to bind to the port to verify it's available
    if command -v python3 >/dev/null 2>&1; then
        if ! timeout 1 python3 -c "
import socket
import sys
try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('0.0.0.0', ${port}))
    s.close()
    sys.exit(0)
except socket.error:
    sys.exit(1)
" 2>/dev/null; then
            log_error "Port conflict detected: $name port $port cannot be bound"
            return 1
        fi
    fi

    return 0
}

# Validate all configured ports
validate_ports() {
    log_info "Validating port configuration..."

    local failed=0
    local conflicts=()

    # Check each port
    if ! check_port_conflict "$VM_SSH_PORT" "SSH"; then
        conflicts+=("VM_SSH_PORT=$VM_SSH_PORT")
        failed=1
    fi

    if ! check_port_conflict "$VM_DOCKER_PORT" "Docker daemon"; then
        conflicts+=("VM_DOCKER_PORT=$VM_DOCKER_PORT")
        failed=1
    fi

    if ! check_port_conflict "$VM_HTTP_PORT" "HTTP"; then
        conflicts+=("VM_HTTP_PORT=$VM_HTTP_PORT")
        failed=1
    fi

    if ! check_port_conflict "$VM_HTTPS_PORT" "HTTPS"; then
        conflicts+=("VM_HTTPS_PORT=$VM_HTTPS_PORT")
        failed=1
    fi

    if ! check_port_conflict "$VM_TRAEFIK_PORT" "Traefik dashboard"; then
        conflicts+=("VM_TRAEFIK_PORT=$VM_TRAEFIK_PORT")
        failed=1
    fi

    if [ $failed -eq 1 ]; then
        log_error "Port validation failed!"
        echo ""
        echo "Conflicting configuration:"
        for conflict in "${conflicts[@]}"; do
            echo "  - $conflict"
        done
        echo ""

        if [ "$FIX_PORTS" = true ]; then
            log_info "Auto-fixing port conflicts..."
            auto_adjust_ports
            return 0
        else
            echo "Options:"
            echo "  1. Edit .env file and change the conflicting ports"
            echo "  2. Run with --fix-ports to auto-adjust"
            echo "  3. Stop the services using these ports"
            echo ""
            return 1
        fi
    fi

    log_success "All ports are available"
    return 0
}

# Auto-adjust ports to avoid conflicts
auto_adjust_ports() {
    log_info "Finding available ports starting from 20000..."

    local base_port=20000
    local port_offset=0

    # Find next available port range
    while true; do
        local test_port=$((base_port + port_offset))
        if check_port_conflict "$test_port" "test" 2>/dev/null; then
            if check_port_conflict "$((test_port + 1))" "test" 2>/dev/null; then
                if check_port_conflict "$((test_port + 2))" "test" 2>/dev/null; then
                    if check_port_conflict "$((test_port + 3))" "test" 2>/dev/null; then
                        if check_port_conflict "$((test_port + 4))" "test" 2>/dev/null; then
                            break
                        fi
                    fi
                fi
            fi
        fi
        port_offset=$((port_offset + 10))
        if [ $port_offset -gt 10000 ]; then
            log_error "Could not find available port range"
            return 1
        fi
    done

    # Update configuration
    VM_HTTP_PORT=$((base_port + port_offset))
    VM_HTTPS_PORT=$((base_port + port_offset + 1))
    VM_TRAEFIK_PORT=$((base_port + port_offset + 2))

    log_info "Adjusted ports:"
    log_info "  VM_HTTP_PORT=$VM_HTTP_PORT"
    log_info "  VM_HTTPS_PORT=$VM_HTTPS_PORT"
    log_info "  VM_TRAEFIK_PORT=$VM_TRAEFIK_PORT"

    # Update .env file
    if [ -f ".env" ]; then
        cp ".env" ".env.backup.$(date +%Y%m%d%H%M%S)"
        sed -i "s/^VM_HTTP_PORT=.*/VM_HTTP_PORT=$VM_HTTP_PORT/" ".env"
        sed -i "s/^VM_HTTPS_PORT=.*/VM_HTTPS_PORT=$VM_HTTPS_PORT/" ".env"
        sed -i "s/^VM_TRAEFIK_PORT=.*/VM_TRAEFIK_PORT=$VM_TRAEFIK_PORT/" ".env"
        log_success "Updated .env file with new ports"
    fi
}

# Validate Docker is installed
validate_docker() {
    log_info "Checking Docker installation..."

    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running or not accessible"
        return 1
    fi

    log_success "Docker is installed and running"
    return 0
}

# Validate Go is installed (for building CLI)
validate_go() {
    if [ "$SKIP_BUILD" = true ]; then
        return 0
    fi

    log_info "Checking Go installation..."

    if ! command -v go >/dev/null 2>&1; then
        log_error "Go is not installed or not in PATH"
        log_info "Install Go from https://golang.org/dl/"
        return 1
    fi

    local go_version
    go_version=$(go version | grep -oP '\d+\.\d+')
    log_success "Go version: $go_version"
    return 0
}

# Validate VM health
validate_vm() {
    log_info "Checking VM health..."

    if ! docker compose ps vm | grep -q "healthy"; then
        log_error "VM is not healthy"
        return 1
    fi

    log_success "VM is healthy"
    return 0
}

# =============================================================================
# Deployment Steps
# =============================================================================

step_build() {
    if [ "$SKIP_BUILD" = true ]; then
        log_info "Skipping CLI build (--skip-build)"
        return 0
    fi

    log_step "1" "Build StackKit CLI"

    if [ ! -f "go.mod" ]; then
        log_error "Not in project root directory. Please run from StackKits root."
        exit 1
    fi

    log_info "Building StackKit CLI..."
    go build -o stackkit.exe ./cmd/stackkit

    log_success "CLI built successfully: ./stackkit.exe"
}

step_start_vm() {
    if [ "$SKIP_VM" = true ]; then
        log_info "Skipping VM startup (--skip-vm)"
        return 0
    fi

    log_step "2" "Start Ubuntu VM (Docker-in-Docker)"

    # Check if VM already exists
    if docker compose ps vm | grep -q "running"; then
        log_warn "VM is already running"
        if [ "$FORCE" != true ]; then
            log_info "Use --force to recreate VM"
            return 0
        fi
        log_info "Force flag set - stopping existing VM..."
        docker compose down vm
    fi

    # Clean up any conflicting containers from previous runs
    log_info "Cleaning up conflicting containers..."
    local conflicting=("traefik" "tinyauth" "dokploy" "dokploy-postgres" "dokploy-redis")
    for container in "${conflicting[@]}"; do
        if docker ps -q -f "name=$container" | grep -q .; then
            log_warn "Stopping conflicting container: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done

    # Start ONLY the VM
    log_info "Starting VM container..."
    docker compose up -d vm

    # Wait for VM to be healthy
    log_info "Waiting for VM to be ready..."
    local max_retries=60
    local retry=0

    until docker compose ps vm | grep -q "healthy"; do
        retry=$((retry + 1))
        if [ $retry -ge $max_retries ]; then
            log_error "VM failed to become healthy"
            docker compose logs vm --tail 50
            exit 1
        fi
        echo -n "."
        sleep 2
    done
    echo ""

    log_success "VM is healthy and ready"

    # Verify Docker daemon is accessible
    log_info "Verifying Docker daemon in VM..."
    if docker compose exec -T vm docker info >/dev/null 2>&1; then
        log_success "Docker daemon is accessible inside VM"
    else
        log_error "Docker daemon not accessible inside VM"
        exit 1
    fi
}

step_start_dns() {
    if [ "$WITH_DNS" = false ]; then
        return 0
    fi

    log_step "3" "Start DNS Service"

    log_info "Starting DNS service for .stack.local domains..."
    docker compose up -d dns

    sleep 3

    log_success "DNS service started"
}

step_init_stackkit() {
    log_step "4" "Initialize StackKit INSIDE the VM"

    log_info "Running: stackkit init base-kit --non-interactive"
    log_info "Target: DOCKER_HOST=tcp://vm:2375"

    docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli \
        ./stackkit init base-kit --non-interactive

    log_success "StackKit initialized in VM"
}

step_apply() {
    log_step "5" "Deploy Services INSIDE the VM"

    log_info "Running: stackkit apply --auto-approve"
    log_info "This deploys Traefik, TinyAuth, Dokploy, etc. INTO the VM"

    docker compose run --rm -e DOCKER_HOST=tcp://vm:2375 cli \
        ./stackkit apply --auto-approve

    log_success "Services deployed to VM"
}

step_verify() {
    log_step "6" "Verify VM-Only Deployment"

    echo -e "${BOLD}Checking Windows Host (should ONLY show VM):${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || true

    echo ""
    echo -e "${BOLD}Checking VM (should show ALL services):${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    docker compose exec -T vm docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" 2>/dev/null || true

    echo ""

    # Count containers
    local host_count=$(docker ps -q 2>/dev/null | wc -l)
    local vm_count=$(docker compose exec -T vm docker ps -q 2>/dev/null | wc -l || echo "0")

    log_info "Containers on Windows Host: $host_count (should be 1 - just the VM)"
    log_info "Containers inside VM: $vm_count (should be 4+ for all services)"

    if [ "$host_count" -le 2 ] && [ "$vm_count" -ge 4 ]; then
        log_success "✓ Deployment verified: Services are running INSIDE the VM"
        return 0
    else
        log_warn "⚠ Deployment verification shows unexpected container distribution"
        log_info "This may be OK if you have other containers running"
        return 1
    fi
}

step_show_credentials() {
    log_step "7" "First Login Credentials"

    echo ""
    echo -e "${BOLD}🔐 TinyAuth (Identity Provider)${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  URL:      ${CYAN}http://auth.${DOMAIN}${NC}"
    echo -e "  (Access via: ${CYAN}http://localhost:${VM_HTTP_PORT}${NC})"
    echo -e "  Username: ${CYAN}admin${NC}"
    echo -e "  Password: ${CYAN}admin123${NC}"
    echo ""
    echo -e "  ${YELLOW}⚠️  IMPORTANT: Change the password immediately after first login!${NC}"
    echo ""

    echo -e "${BOLD}🔐 Dokploy (PAAS Controller)${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  URL: ${CYAN}http://dokploy.${DOMAIN}${NC}"
    echo -e "  (Access via: ${CYAN}http://localhost:${VM_HTTP_PORT}${NC})"
    echo "  Authentication: Via TinyAuth SSO"
    echo ""

    echo -e "${BOLD}🌐 Other Services${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  Traefik Dashboard: ${CYAN}http://traefik.${DOMAIN}${NC}"
    echo -e "  Uptime Kuma:       ${CYAN}http://kuma.${DOMAIN}${NC}"
    echo -e "  Whoami Test:       ${CYAN}http://whoami.${DOMAIN}${NC}"
    echo ""

    echo -e "${BOLD}📊 Port Mappings (Host → VM)${NC}"
    echo "────────────────────────────────────────────────────────────────────"
    echo -e "  HTTP:       localhost:${VM_HTTP_PORT} → VM:80"
    echo -e "  HTTPS:      localhost:${VM_HTTPS_PORT} → VM:443"
    echo -e "  Traefik:    localhost:${VM_TRAEFIK_PORT} → VM:8080"
    echo -e "  Docker:     localhost:${VM_DOCKER_PORT} → VM:2375"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BOLD}StackKit Base Kit - VM Deployment${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "Deployment target: Ubuntu VM (not Windows host)"
    log_info "Docker daemon: tcp://vm:2375"
    echo ""

    # Pre-deployment validation
    log_step "0" "Pre-Deployment Validation"

    validate_docker || exit 1
    validate_go || exit 1
    validate_ports || exit 1

    if [ "$VALIDATE_ONLY" = true ]; then
        log_success "Validation passed!"
        exit 0
    fi

    # Execute deployment steps
    step_build
    step_start_vm
    step_start_dns
    step_init_stackkit
    step_apply
    step_verify
    step_show_credentials

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}Deployment Complete!${NC}                                         ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   All services are running INSIDE the Ubuntu VM.               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   Start with TinyAuth: http://localhost:${VM_HTTP_PORT}        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "To verify services are in VM:"
    echo "  docker ps                           # Host: should show only 'stackkits-vm'"
    echo "  docker compose exec vm docker ps    # VM: should show all services"
    echo ""
}

# Run main
main "$@"
