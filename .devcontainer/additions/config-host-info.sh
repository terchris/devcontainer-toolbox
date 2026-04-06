#!/bin/bash
# File: .devcontainer/additions/config-host-info.sh
# Purpose: Detect and save host machine information for OTEL monitoring
# Usage: bash config-host-info.sh [--verify]

#------------------------------------------------------------------------------
# CONFIG METADATA - For dev-setup.sh integration
#------------------------------------------------------------------------------

SCRIPT_ID="config-host-info"
SCRIPT_NAME="Host Information"
SCRIPT_VER="0.0.1"
SCRIPT_DESCRIPTION="Detect host OS, user, and architecture for telemetry monitoring"
SCRIPT_CATEGORY="INFRA_CONFIG"
SCRIPT_CHECK_COMMAND="[ -f /workspace/.devcontainer.secrets/env-vars/.host-info ]"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="host system telemetry monitoring architecture"
SCRIPT_ABSTRACT="Detect and save host machine information for OTEL telemetry and monitoring."
SCRIPT_LOGO="config-host-info-logo.webp"
SCRIPT_SUMMARY="Configuration script that detects host OS, username, and architecture information for OpenTelemetry monitoring. Stores host metadata in .devcontainer.secrets for inclusion in telemetry data and Grafana dashboards."
SCRIPT_RELATED="srv-otel config-devcontainer-identity"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Detect and save host information||false|"
    "Action|--show|Display current host information||false|"
    "Action|--verify|Refresh host information||false|"
    "Info|--help|Show help information||false|"
)

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

#TODO: should use existing function from lib files
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

# Parse OneDrive path to extract organization name and determine machine ownership
# OneDrive path examples:
#   "OneDrive - Norges Røde Kors" -> corporate
#   "OneDrive - Personal" -> personal
#   "OneDrive - Acme Consulting" -> external_consultant
parse_organization_from_onedrive() {
    local onedrive_path="$1"
    local logonserver="$2"

    # Extract organization name from OneDrive path (after "OneDrive - ")
    if [[ "$onedrive_path" == *"OneDrive - "* ]]; then
        ORGANIZATION_NAME="${onedrive_path##*OneDrive - }"
    else
        ORGANIZATION_NAME=""
    fi

    # Extract organization prefix from LOGONSERVER (e.g., \\NRX-PC -> NRX)
    if [[ -n "$logonserver" ]]; then
        # Remove leading backslashes and extract prefix before hyphen
        local cleaned="${logonserver#\\\\}"
        cleaned="${cleaned#\\}"
        ORGANIZATION_PREFIX="${cleaned%%-*}"
    else
        ORGANIZATION_PREFIX=""
    fi

    # Determine machine ownership based on OneDrive org name
    if [[ -z "$ORGANIZATION_NAME" ]]; then
        ORGANIZATION_MACHINE_OWNERSHIP=""
    elif [[ "$ORGANIZATION_NAME" == "Personal" ]]; then
        ORGANIZATION_MACHINE_OWNERSHIP="personal"
    elif [[ -n "$ORGANIZATION_PREFIX" ]]; then
        # Has a corporate prefix like NRX -> corporate machine
        ORGANIZATION_MACHINE_OWNERSHIP="corporate"
    else
        # Has org name but no prefix -> likely external consultant
        ORGANIZATION_MACHINE_OWNERSHIP="external_consultant"
    fi

    export ORGANIZATION_NAME
    export ORGANIZATION_PREFIX
    export ORGANIZATION_MACHINE_OWNERSHIP
}

#------------------------------------------------------------------------------
# SHARED DETECTION — reads DEV_HOST_* (new), falls back to DEV_MAC_*/DEV_WIN_*/DEV_LINUX_* (legacy)
#------------------------------------------------------------------------------

_detect_host_vars() {
    # New DEV_HOST_* variables (from devcontainer-user-template.json remoteEnv)
    if [ "${DEV_HOST_OS:-}" = "Windows_NT" ]; then
        export HOST_OS="Windows"
        export HOST_USER="${DEV_HOST_USERNAME:-${DEV_HOST_USER:-unknown}}"
        export HOST_HOSTNAME="${DEV_HOST_COMPUTERNAME:-${DEV_HOST_HOSTNAME:-devcontainer}}"
        export HOST_DOMAIN="none"
        export HOST_ARCH="${DEV_HOST_PROCESSOR_ARCHITECTURE:-}"
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        parse_organization_from_onedrive "${DEV_HOST_ONEDRIVE:-}" ""
    elif [[ "${DEV_HOST_HOME:-}" == /Users/* ]]; then
        export HOST_OS="macOS"
        export HOST_USER="${DEV_HOST_USER:-unknown}"
        export HOST_HOSTNAME="${DEV_HOST_HOSTNAME:-devcontainer}"
        export HOST_DOMAIN="none"
        export HOST_ARCH=""
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        export ORGANIZATION_NAME=""
        export ORGANIZATION_PREFIX=""
        export ORGANIZATION_MACHINE_OWNERSHIP=""
    elif [ -n "${DEV_HOST_USER:-}" ]; then
        export HOST_OS="Linux"
        export HOST_USER="$DEV_HOST_USER"
        export HOST_HOSTNAME="${DEV_HOST_HOSTNAME:-devcontainer}"
        export HOST_DOMAIN="none"
        export HOST_ARCH=""
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        export ORGANIZATION_NAME=""
        export ORGANIZATION_PREFIX=""
        export ORGANIZATION_MACHINE_OWNERSHIP=""
    # Legacy fallback: DEV_MAC_* / DEV_WIN_* / DEV_LINUX_* (from dev devcontainer build.args)
    elif [ -n "${DEV_MAC_USER:-}" ]; then
        export HOST_OS="macOS"
        export HOST_USER="$DEV_MAC_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
        export HOST_ARCH=""
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        export ORGANIZATION_NAME=""
        export ORGANIZATION_PREFIX=""
        export ORGANIZATION_MACHINE_OWNERSHIP=""
    elif [ -n "${DEV_LINUX_USER:-}" ]; then
        export HOST_OS="Linux"
        export HOST_USER="$DEV_LINUX_USER"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
        export HOST_ARCH=""
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        export ORGANIZATION_NAME=""
        export ORGANIZATION_PREFIX=""
        export ORGANIZATION_MACHINE_OWNERSHIP=""
    elif [ -n "${DEV_WIN_USERNAME:-}" ]; then
        export HOST_OS="Windows"
        export HOST_USER="$DEV_WIN_USERNAME"
        export HOST_HOSTNAME="${DEV_WIN_COMPUTERNAME:-devcontainer}"
        export HOST_DOMAIN="${DEV_WIN_USERDOMAIN:-none}"
        export HOST_ARCH="${DEV_WIN_PROCESSOR_ARCHITECTURE:-}"
        export HOST_CPU_MODEL_NAME="${DEV_WIN_PROCESSOR_IDENTIFIER:-}"
        export HOST_CPU_LOGICAL_COUNT="${DEV_WIN_NUMBER_OF_PROCESSORS:-}"
        parse_organization_from_onedrive "${DEV_WIN_ONEDRIVE:-}" "${DEV_WIN_LOGONSERVER:-}"
    else
        export HOST_OS="unknown"
        export HOST_USER="unknown"
        export HOST_HOSTNAME="devcontainer"
        export HOST_DOMAIN="none"
        export HOST_ARCH=""
        export HOST_CPU_MODEL_NAME=""
        export HOST_CPU_LOGICAL_COUNT=""
        export ORGANIZATION_NAME=""
        export ORGANIZATION_PREFIX=""
        export ORGANIZATION_MACHINE_OWNERSHIP=""
    fi

    export HOST_CPU_ARCH="$(get_architecture)"
    get_docker_server_stats
}

_print_host_summary() {
    echo "  OS: $HOST_OS"
    echo "  User: $HOST_USER"
    echo "  Hostname: $HOST_HOSTNAME"
    [ -n "$HOST_DOMAIN" ] && [ "$HOST_DOMAIN" != "none" ] && echo "  Domain: $HOST_DOMAIN"
    echo "  Architecture: $HOST_CPU_ARCH"
    [ -n "$HOST_CPU_LOGICAL_COUNT" ] && echo "  Processors: $HOST_CPU_LOGICAL_COUNT"
    [ -n "$HOST_ARCH" ] && echo "  Processor Arch: $HOST_ARCH"
    [ -n "$ORGANIZATION_NAME" ] && echo "  Organization: $ORGANIZATION_NAME"
    [ -n "$ORGANIZATION_PREFIX" ] && echo "  Org Prefix: $ORGANIZATION_PREFIX"
    [ -n "$ORGANIZATION_MACHINE_OWNERSHIP" ] && echo "  Machine Type: $ORGANIZATION_MACHINE_OWNERSHIP"
    echo "  Docker Server:"
    echo "    Containers: $DOCKER_CONTAINERS_TOTAL (Running: $DOCKER_CONTAINERS_RUNNING, Stopped: $DOCKER_CONTAINERS_STOPPED, Paused: $DOCKER_CONTAINERS_PAUSED)"
    echo "    Images: $DOCKER_IMAGES_TOTAL"
}

detect_host_info() {
    log_info "Detecting host information for telemetry..."
    echo ""

    _detect_host_vars
    save_host_info_to_env

    _print_host_summary
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

# Windows extended variables - using OTel semantic conventions (empty on Mac/Linux)
export HOST_ARCH="${HOST_ARCH:-}"
export HOST_CPU_MODEL_NAME="${HOST_CPU_MODEL_NAME:-}"
export HOST_CPU_LOGICAL_COUNT="${HOST_CPU_LOGICAL_COUNT:-}"

# Organization detection (parsed from Windows OneDrive/LOGONSERVER)
export ORGANIZATION_NAME="${ORGANIZATION_NAME:-}"
export ORGANIZATION_PREFIX="${ORGANIZATION_PREFIX:-}"
export ORGANIZATION_MACHINE_OWNERSHIP="${ORGANIZATION_MACHINE_OWNERSHIP:-}"

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
# SHOW CONFIG - Display current configuration
#------------------------------------------------------------------------------

show_config() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Current Configuration: $SCRIPT_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ ! -f "$PERSISTENT_FILE" ]; then
        echo "❌ Not configured"
        echo ""
        echo "Run: bash $0"
        return 1
    fi

    # Source and display
    # shellcheck source=/dev/null
    source "$PERSISTENT_FILE" 2>/dev/null

    echo "Config file: $PERSISTENT_FILE"
    echo ""
    echo "Host Information:"
    echo "  HOST_OS:       ${HOST_OS:-<not set>}"
    echo "  HOST_USER:     ${HOST_USER:-<not set>}"
    echo "  HOST_HOSTNAME: ${HOST_HOSTNAME:-<not set>}"
    echo "  HOST_DOMAIN:   ${HOST_DOMAIN:-<not set>}"
    echo "  HOST_CPU_ARCH: ${HOST_CPU_ARCH:-<not set>}"
    echo ""
    echo "Docker Statistics:"
    echo "  Containers:    ${DOCKER_CONTAINERS_TOTAL:-0} (Running: ${DOCKER_CONTAINERS_RUNNING:-0})"
    echo "  Images:        ${DOCKER_IMAGES_TOTAL:-0}"
    echo ""

    return 0
}

#------------------------------------------------------------------------------
# VERIFY MODE - Non-interactive validation for container rebuild
#------------------------------------------------------------------------------

verify_host_info() {
    # Silent mode - just detect and save
    setup_persistent_storage
    _detect_host_vars
    save_host_info_to_env
    return 0
}

refresh_host_info() {
    # Re-detect from current env vars, save, and show result
    setup_persistent_storage
    _detect_host_vars
    save_host_info_to_env

    echo ""
    echo "🔄 Host information refreshed:"
    echo ""
    _print_host_summary
    echo ""
    log_success "Saved to $PERSISTENT_FILE"
    echo ""
}

#------------------------------------------------------------------------------
# SHOW HOST ENV - Display all DEV_HOST_* environment variables
#------------------------------------------------------------------------------

show_host_env() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🖥️  Host Environment Variables (from devcontainer.json remoteEnv)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local found=0
    while IFS='=' read -r name value; do
        if [[ "$name" == DEV_HOST_* ]]; then
            if [ -n "$value" ]; then
                printf "  %-30s %s\n" "$name" "$value"
            else
                printf "  %-30s %s\n" "$name" "(empty)"
            fi
            found=$((found + 1))
        fi
    done < <(env | sort)

    if [ $found -eq 0 ]; then
        echo "  No DEV_HOST_* variables found."
        echo ""
        echo "  These are set in .devcontainer/devcontainer.json remoteEnv."
        echo "  Run 'dev-update' to get the latest template with host variables."
    fi

    echo ""

    return 0
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    # Handle flags
    case "${1:-}" in
        --show)
            show_config
            exit $?
            ;;
        --env)
            show_host_env
            exit $?
            ;;
        --refresh)
            refresh_host_info
            exit $?
            ;;
        --verify)
            verify_host_info
            exit $?
            ;;
        --help)
            echo "Usage: config-host-info [--show|--env|--refresh|--verify|--help]"
            echo ""
            echo "  (no args)  Detect and save host information (interactive)"
            echo "  --show     Display saved host information (from .host-info file)"
            echo "  --env      Display all DEV_HOST_* environment variables from host"
            echo "  --refresh  Re-detect from current env vars, save, and show result"
            echo "  --verify   Silent re-detect and save (used by entrypoint on startup)"
            echo "  --help     Show this help"
            exit 0
            ;;
    esac

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
