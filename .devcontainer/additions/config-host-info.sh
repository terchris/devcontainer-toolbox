#!/bin/bash
# File: .devcontainer/additions/config-host-info.sh
# Purpose: Detect and save host machine information for OTEL monitoring
# Usage: bash config-host-info.sh [--verify]

#------------------------------------------------------------------------------
# CONFIG METADATA - For dev-setup.sh integration
#------------------------------------------------------------------------------

CONFIG_NAME="Host Information"
CONFIG_DESCRIPTION="Detect host OS, user, and architecture for telemetry monitoring"
CONFIG_CATEGORY="INFRA_CONFIG"
CHECK_CONFIGURED_COMMAND="[ -f /workspace/.devcontainer.secrets/env-vars/.host-info ]"

#------------------------------------------------------------------------------

set -e

# Source logging library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Persistent storage paths
PERSISTENT_DIR="/workspace/.devcontainer.secrets/env-vars"
PERSISTENT_FILE="$PERSISTENT_DIR/.host-info"

#------------------------------------------------------------------------------
# PERSISTENT STORAGE FUNCTIONS
#------------------------------------------------------------------------------

setup_persistent_storage() {
    mkdir -p "$PERSISTENT_DIR"
}

get_architecture() {
    # Normalize architecture names
    local arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l) echo "arm32" ;;
        *) echo "$arch" ;;
    esac
}

get_host_hostname() {
    # For devcontainer environments, the hostname is the container ID
    # Use a generic identifier since we're in a virtualized environment
    echo "devcontainer"
}

get_docker_server_stats() {
    # Get Docker server statistics if Docker is available
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        local docker_info=$(docker info 2>/dev/null)

        # Extract statistics
        local total=$(echo "$docker_info" | grep "^ Containers:" | awk '{print $2}')
        local running=$(echo "$docker_info" | grep "^  Running:" | awk '{print $2}')
        local stopped=$(echo "$docker_info" | grep "^  Stopped:" | awk '{print $2}')
        local paused=$(echo "$docker_info" | grep "^  Paused:" | awk '{print $2}')
        local images=$(echo "$docker_info" | grep "^ Images:" | awk '{print $2}')

        # Export for later use
        export DOCKER_CONTAINERS_TOTAL="${total:-0}"
        export DOCKER_CONTAINERS_RUNNING="${running:-0}"
        export DOCKER_CONTAINERS_STOPPED="${stopped:-0}"
        export DOCKER_CONTAINERS_PAUSED="${paused:-0}"
        export DOCKER_IMAGES_TOTAL="${images:-0}"
        return 0
    fi

    # Set defaults if Docker not available
    export DOCKER_CONTAINERS_TOTAL="0"
    export DOCKER_CONTAINERS_RUNNING="0"
    export DOCKER_CONTAINERS_STOPPED="0"
    export DOCKER_CONTAINERS_PAUSED="0"
    export DOCKER_IMAGES_TOTAL="0"
    return 1
}

detect_host_info() {
    log_info "Detecting host information for telemetry..."
    echo ""

    # Detect OS and user from environment variables
    if [ -n "$DEV_MAC_USER" ]; then
        export HOST_OS="macOS"
        export HOST_USER="$DEV_MAC_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    elif [ -n "$DEV_LINUX_USER" ]; then
        export HOST_OS="Linux"
        export HOST_USER="$DEV_LINUX_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    elif [ -n "$DEV_WIN_USERNAME" ]; then
        export HOST_OS="Windows"
        export HOST_USER="$DEV_WIN_USERNAME"
        export HOST_HOSTNAME="${DEV_WIN_COMPUTERNAME:-devcontainer}"
        export HOST_DOMAIN="${DEV_WIN_USERDOMAIN:-none}"
    else
        export HOST_OS="unknown"
        export HOST_USER="unknown"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    fi

    # Get architecture using helper function
    export HOST_CPU_ARCH="$(get_architecture)"

    # Get Docker server statistics
    get_docker_server_stats

    # Save to environment file for persistence
    save_host_info_to_env

    # Display summary
    echo "  OS: $HOST_OS"
    echo "  User: $HOST_USER"
    echo "  Hostname: $HOST_HOSTNAME"
    [ -n "$HOST_DOMAIN" ] && echo "  Domain: $HOST_DOMAIN"
    echo "  Architecture: $HOST_CPU_ARCH"
    echo "  Docker Server:"
    echo "    Containers: $DOCKER_CONTAINERS_TOTAL (Running: $DOCKER_CONTAINERS_RUNNING, Stopped: $DOCKER_CONTAINERS_STOPPED, Paused: $DOCKER_CONTAINERS_PAUSED)"
    echo "    Images: $DOCKER_IMAGES_TOTAL"
    echo ""
    log_success "Host information detected"
}

save_host_info_to_env() {
    # Create environment file for host info
    setup_persistent_storage

    cat > "$PERSISTENT_FILE" <<EOF
# Host information - managed by config-host-info.sh
# This file is generated on container creation and sourced for OTEL
export HOST_OS="$HOST_OS"
export HOST_USER="$HOST_USER"
export HOST_HOSTNAME="$HOST_HOSTNAME"
export HOST_DOMAIN="$HOST_DOMAIN"
export HOST_CPU_ARCH="$HOST_CPU_ARCH"

# Docker server statistics
export DOCKER_CONTAINERS_TOTAL="$DOCKER_CONTAINERS_TOTAL"
export DOCKER_CONTAINERS_RUNNING="$DOCKER_CONTAINERS_RUNNING"
export DOCKER_CONTAINERS_STOPPED="$DOCKER_CONTAINERS_STOPPED"
export DOCKER_CONTAINERS_PAUSED="$DOCKER_CONTAINERS_PAUSED"
export DOCKER_IMAGES_TOTAL="$DOCKER_IMAGES_TOTAL"
EOF

    chmod 600 "$PERSISTENT_FILE"
}

#------------------------------------------------------------------------------
# VERIFY MODE - Non-interactive validation for container rebuild
#------------------------------------------------------------------------------

verify_host_info() {
    # Silent mode - just detect and save
    setup_persistent_storage

    # Always detect fresh (host info can change if user switches machines)
    if [ -n "$DEV_MAC_USER" ]; then
        export HOST_OS="macOS"
        export HOST_USER="$DEV_MAC_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    elif [ -n "$DEV_LINUX_USER" ]; then
        export HOST_OS="Linux"
        export HOST_USER="$DEV_LINUX_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    elif [ -n "$DEV_WIN_USERNAME" ]; then
        export HOST_OS="Windows"
        export HOST_USER="$DEV_WIN_USERNAME"
        export HOST_HOSTNAME="${DEV_WIN_COMPUTERNAME:-devcontainer}"
        export HOST_DOMAIN="${DEV_WIN_USERDOMAIN:-none}"
    else
        export HOST_OS="unknown"
        export HOST_USER="unknown"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
    fi

    # Get architecture using helper function
    export HOST_CPU_ARCH="$(get_architecture)"

    # Get Docker server statistics
    get_docker_server_stats

    save_host_info_to_env

    return 0
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    # Handle --verify flag for non-interactive validation
    if [ "${1:-}" = "--verify" ]; then
        verify_host_info
        exit $?
    fi

    # Interactive mode - show detailed info
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🖥️  Host Information Detection"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    detect_host_info

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Host Information Saved"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Information stored in: $PERSISTENT_FILE"
    echo "   This will be included in all OTEL telemetry"
    echo ""
}

# Run main
main "$@"
