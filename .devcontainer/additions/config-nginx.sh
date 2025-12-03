#!/bin/bash
# File: .devcontainer/additions/config-nginx.sh
#
# DESCRIPTION: Configure nginx reverse proxy LiteLLM backend URL
# PURPOSE: Sets up the backend URL for LiteLLM (docker, local WiFi, Tailscale, etc.)
#
# Usage:
#   bash config-nginx.sh        # Run normally
#   bash config-nginx.sh --verify   # Non-interactive validation
#
# Interactive script - will prompt for LiteLLM backend configuration
#
#------------------------------------------------------------------------------
# CONFIGURATION - Metadata for dev-setup.sh discovery
#------------------------------------------------------------------------------

CONFIG_NAME="Backend Infrastructure"
CONFIG_VER="0.0.1"
CONFIG_DESCRIPTION="Configure backend URL and ports for nginx reverse proxy (LiteLLM, OTEL, etc.)"
CONFIG_CATEGORY="INFRA_CONFIG"
CHECK_CONFIGURED_COMMAND="[ -f ~/.nginx-backend-config ] && grep -q '^export BACKEND_URL=' ~/.nginx-backend-config"

#------------------------------------------------------------------------------

set -euo pipefail

# Source logging library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Files
ENV_FILE="$HOME/.nginx-backend-config"
NGINX_LITELLM_TEMPLATE="${SCRIPT_DIR}/nginx/litellm-proxy.conf.template"
NGINX_OTEL_TEMPLATE="${SCRIPT_DIR}/nginx/otel-proxy.conf.template"
NGINX_OPENWEBUI_TEMPLATE="${SCRIPT_DIR}/nginx/openwebui-proxy.conf.template"
NGINX_LITELLM_CONFIG="/etc/nginx/sites-available/litellm-proxy.conf"
NGINX_OTEL_CONFIG="/etc/nginx/sites-available/otel-proxy.conf"
NGINX_OPENWEBUI_CONFIG="/etc/nginx/sites-available/openwebui-proxy.conf"

# Persistent storage paths
PERSISTENT_DIR="/workspace/.devcontainer.secrets/nginx-config"
PERSISTENT_FILE="$PERSISTENT_DIR/.nginx-backend-config"

#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

check_if_already_configured() {
    if [ -f "$ENV_FILE" ]; then
        echo ""
        log_warning "Backend infrastructure already configured!"
        echo ""
        echo "Current configuration:"
        if [ -r "$ENV_FILE" ]; then
            # Source it temporarily to show values
            (
                # shellcheck source=/dev/null
                source "$ENV_FILE" 2>/dev/null
                echo "   Backend URL:      ${BACKEND_URL:-<not set>}"
                echo "   Backend Type:     ${BACKEND_TYPE:-<not set>}"
                echo "   LiteLLM Port:     ${NGINX_LITELLM_PORT:-<not set>}"
                echo "   OTEL Port:        ${NGINX_OTEL_PORT:-<not set>}"
                echo "   Open WebUI Port:  ${NGINX_OPENWEBUI_PORT:-<not set>}"
            )
        fi
        echo ""
        read -p "Do you want to reconfigure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            log_info "Keeping existing configuration"
            exit 0
        fi
        echo ""
        log_info "Reconfiguring nginx backend..."
    fi
}

prompt_for_backend_type() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Select Backend Infrastructure Type"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Choose how nginx should reach the backend infrastructure (LiteLLM, OTEL, etc.):"
    echo ""
    echo "1) Docker Internal (host.docker.internal)"
    echo "   • Use when infrastructure runs on host K8s/Docker"
    echo "   • Default for local development"
    echo "   • URL: http://host.docker.internal"
    echo ""
    echo "2) Local WiFi/Network"
    echo "   • Use when infrastructure is on another machine in local network"
    echo "   • For home/office testing"
    echo "   • Example: http://192.168.1.100 or http://myserver.local"
    echo ""
    echo "3) Tailscale VPN"
    echo "   • Use when infrastructure is on Tailscale network"
    echo "   • For secure remote access"
    echo "   • Example: http://100.64.1.5 or http://mymachine.tailscale.net"
    echo ""
    echo "4) Custom URL"
    echo "   • Any other URL/endpoint"
    echo "   • Example: http://backend.example.com"
    echo ""
    read -p "Select option (1-4): " -n 1 -r BACKEND_TYPE
    echo
    echo ""

    case $BACKEND_TYPE in
        1)
            BACKEND_URL="http://host.docker.internal"
            BACKEND_TYPE="docker-internal"
            log_success "Selected: Docker Internal"
            ;;
        2)
            BACKEND_TYPE="local-wifi"
            prompt_for_custom_url "Enter local network URL (e.g., http://192.168.1.100)"
            ;;
        3)
            BACKEND_TYPE="tailscale"
            prompt_for_custom_url "Enter Tailscale URL (e.g., http://100.64.1.5 or http://machine.tailscale.net)"
            ;;
        4)
            BACKEND_TYPE="custom"
            prompt_for_custom_url "Enter custom backend URL"
            ;;
        *)
            log_error "Invalid selection"
            exit 1
            ;;
    esac
}

prompt_for_ports() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔌 Configure Nginx Proxy Ports"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Configure local ports for nginx proxies (press Enter for defaults):"
    echo ""

    # LiteLLM port
    read -p "LiteLLM proxy port [8080]: " input_litellm_port
    NGINX_LITELLM_PORT="${input_litellm_port:-8080}"

    # OTEL port
    read -p "OTEL proxy port [8081]: " input_otel_port
    NGINX_OTEL_PORT="${input_otel_port:-8081}"

    # Open WebUI port
    read -p "Open WebUI proxy port [8082]: " input_openwebui_port
    NGINX_OPENWEBUI_PORT="${input_openwebui_port:-8082}"

    echo ""
    log_success "Ports configured: LiteLLM=$NGINX_LITELLM_PORT, OTEL=$NGINX_OTEL_PORT, Open WebUI=$NGINX_OPENWEBUI_PORT"
}

prompt_for_custom_url() {
    local prompt_message="$1"

    echo "$prompt_message:"
    read -r BACKEND_URL

    # Trim whitespace
    BACKEND_URL=$(echo "$BACKEND_URL" | tr -d '[:space:]')

    if [ -z "$BACKEND_URL" ]; then
        log_error "No URL provided"
        exit 1
    fi

    # Basic URL validation (starts with http:// or https://)
    if [[ ! "$BACKEND_URL" =~ ^https?:// ]]; then
        log_warning "URL doesn't start with http:// or https://"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    log_success "URL accepted: $BACKEND_URL"
}

create_config_file() {
    log_info "Creating backend infrastructure configuration..."

    # Ensure persistent directory exists
    mkdir -p "$PERSISTENT_DIR"

    # Create the configuration file
    cat > "$PERSISTENT_FILE" <<EOF
# Backend Infrastructure Configuration
# Generated by config-nginx.sh on $(date)
# This file is used by start-nginx.sh to generate nginx configurations
# and by OTEL collectors to route telemetry

# Backend URL (serves LiteLLM, OTEL, Open WebUI, etc. via Traefik)
export BACKEND_URL="$BACKEND_URL"

# Backend type (for reference/documentation)
export BACKEND_TYPE="$BACKEND_TYPE"

# Nginx proxy ports
export NGINX_LITELLM_PORT="$NGINX_LITELLM_PORT"
export NGINX_OTEL_PORT="$NGINX_OTEL_PORT"
export NGINX_OPENWEBUI_PORT="$NGINX_OPENWEBUI_PORT"
EOF

    # Set permissions (readable only by user)
    chmod 600 "$PERSISTENT_FILE"

    log_success "Configuration file created: $PERSISTENT_FILE"
}

setup_persistent_storage() {
    log_info "Setting up persistent storage..."

    # Create symlink (force overwrite if exists)
    ln -sf "$PERSISTENT_FILE" "$ENV_FILE"

    log_success "Symlink created: $ENV_FILE → $PERSISTENT_FILE"
}

generate_nginx_config() {
    log_info "Generating nginx configurations..."

    # Source the config file
    # shellcheck source=/dev/null
    source "$ENV_FILE"

    # Generate LiteLLM proxy config
    if [ -f "$NGINX_LITELLM_TEMPLATE" ]; then
        sudo sed -e "s|BACKEND_URL|${BACKEND_URL}|g" \
                 -e "s|NGINX_LITELLM_PORT|${NGINX_LITELLM_PORT}|g" \
                 "$NGINX_LITELLM_TEMPLATE" | \
            sudo tee "$NGINX_LITELLM_CONFIG" >/dev/null
        log_success "LiteLLM proxy config generated: $NGINX_LITELLM_CONFIG"
    else
        log_warning "LiteLLM template not found: $NGINX_LITELLM_TEMPLATE"
    fi

    # Generate OTEL proxy config
    if [ -f "$NGINX_OTEL_TEMPLATE" ]; then
        sudo sed -e "s|BACKEND_URL|${BACKEND_URL}|g" \
                 -e "s|NGINX_OTEL_PORT|${NGINX_OTEL_PORT}|g" \
                 "$NGINX_OTEL_TEMPLATE" | \
            sudo tee "$NGINX_OTEL_CONFIG" >/dev/null
        log_success "OTEL proxy config generated: $NGINX_OTEL_CONFIG"
    else
        log_warning "OTEL template not found: $NGINX_OTEL_TEMPLATE (will be created later)"
    fi

    # Generate Open WebUI proxy config
    if [ -f "$NGINX_OPENWEBUI_TEMPLATE" ]; then
        sudo sed -e "s|{{BACKEND_URL}}|${BACKEND_URL}|g" \
                 -e "s|8082|${NGINX_OPENWEBUI_PORT}|g" \
                 "$NGINX_OPENWEBUI_TEMPLATE" | \
            sudo tee "$NGINX_OPENWEBUI_CONFIG" >/dev/null
        log_success "Open WebUI proxy config generated: $NGINX_OPENWEBUI_CONFIG"
    else
        log_warning "Open WebUI template not found: $NGINX_OPENWEBUI_TEMPLATE"
    fi
}

test_configuration() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Testing Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Source the config file for testing
    # shellcheck source=/dev/null
    source "$ENV_FILE"

    # Test 1: Check configuration variables are set
    log_info "Test 1: Configuration variables"
    if [ -n "$BACKEND_URL" ] && [ -n "$BACKEND_TYPE" ]; then
        log_success "Configuration variables are set"
    else
        log_error "Some configuration variables are missing"
        return 1
    fi

    # Test 2: Check nginx configuration syntax (if nginx is installed)
    if command -v nginx >/dev/null 2>&1; then
        log_info "Test 2: Nginx configuration syntax"
        if sudo nginx -t 2>&1 | grep -q "syntax is ok"; then
            log_success "Nginx configuration is valid"
        else
            log_warning "Nginx configuration has errors (you may need to restart nginx)"
            sudo nginx -t 2>&1 || true
        fi
    else
        log_info "Test 2: Nginx not installed (skipping syntax check)"
    fi

    # Test 3: Test connectivity to backend (basic check)
    log_info "Test 3: Backend connectivity"
    if command -v curl >/dev/null 2>&1; then
        # Extract host from URL for ping test
        BACKEND_HOST=$(echo "$BACKEND_URL" | sed -E 's|^https?://([^:/]+).*|\1|')

        if [ "$BACKEND_HOST" = "host.docker.internal" ]; then
            # Special case for docker internal
            if ping -c 1 -W 2 "$BACKEND_HOST" >/dev/null 2>&1; then
                log_success "Can reach $BACKEND_HOST"
            else
                log_warning "Cannot ping $BACKEND_HOST (this is normal if host doesn't respond to ping)"
            fi
        else
            # Try HTTP request to backend
            if curl -s -m 5 -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" 2>/dev/null | grep -q "200"; then
                log_success "Backend is responding (health check passed)"
            else
                log_warning "Could not reach backend at $BACKEND_URL"
                echo "   This is normal if infrastructure is not running yet"
            fi
        fi
    else
        log_info "curl not available, skipping connectivity check"
    fi

    echo ""
}

show_completion() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 Configuration Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_success "Backend infrastructure configuration saved"
    echo ""
    echo "📋 Configuration Details:"
    echo ""
    echo "• Config file: ~/.nginx-backend-config"
    echo "  (Symlink to: $PERSISTENT_FILE)"
    echo "  Persists across container rebuilds"
    echo ""
    echo "• Backend URL:      $BACKEND_URL"
    echo "• Backend Type:     $BACKEND_TYPE"
    echo "• LiteLLM Port:     $NGINX_LITELLM_PORT"
    echo "• OTEL Port:        $NGINX_OTEL_PORT"
    echo "• Open WebUI Port:  $NGINX_OPENWEBUI_PORT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🚀 Next Steps:"
    echo ""
    echo "1. Restart nginx to apply changes:"
    echo "   dev-services restart nginx-reverse-proxy"
    echo ""
    echo "2. Test nginx is working:"
    echo "   curl http://localhost:8080/nginx-health"
    echo ""
    echo "3. Test backend connectivity:"
    echo "   curl http://localhost:8080/health"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

#------------------------------------------------------------------------------
# VERIFY MODE - Non-interactive validation for container rebuild
#------------------------------------------------------------------------------

verify_environment() {
    # Silent mode - no prompts, just validate

    # Always set up symlink first (in case container was rebuilt)
    mkdir -p "$PERSISTENT_DIR"
    ln -sf "$PERSISTENT_FILE" "$ENV_FILE"

    # Check if config file exists
    if [ ! -f "$ENV_FILE" ]; then
        # File doesn't exist - this is expected on first container creation
        # Exit silently without error
        return 0
    fi

    # File exists - validate it has required variables
    # shellcheck source=/dev/null
    source "$ENV_FILE" 2>/dev/null || return 1

    local missing_vars=()
    [ -z "${BACKEND_URL:-}" ] && missing_vars+=("BACKEND_URL")
    [ -z "${BACKEND_TYPE:-}" ] && missing_vars+=("BACKEND_TYPE")
    [ -z "${NGINX_LITELLM_PORT:-}" ] && missing_vars+=("NGINX_LITELLM_PORT")
    [ -z "${NGINX_OTEL_PORT:-}" ] && missing_vars+=("NGINX_OTEL_PORT")

    # Open WebUI port is optional (for backwards compatibility)
    if [ -z "${NGINX_OPENWEBUI_PORT:-}" ]; then
        NGINX_OPENWEBUI_PORT="8082"  # Default value
    fi

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "⚠️  Backend config exists but is incomplete. Missing: ${missing_vars[*]}"
        echo "   Run: bash .devcontainer/additions/config-nginx.sh"
        return 1
    fi

    # Regenerate nginx configs if templates exist
    if [ -f "$NGINX_LITELLM_TEMPLATE" ]; then
        sudo sed -e "s|BACKEND_URL|${BACKEND_URL}|g" \
                 -e "s|NGINX_LITELLM_PORT|${NGINX_LITELLM_PORT}|g" \
                 "$NGINX_LITELLM_TEMPLATE" | \
            sudo tee "$NGINX_LITELLM_CONFIG" >/dev/null 2>&1 || true
    fi

    # Regenerate Open WebUI proxy config if template exists
    if [ -f "$NGINX_OPENWEBUI_TEMPLATE" ]; then
        sudo sed -e "s|{{BACKEND_URL}}|${BACKEND_URL}|g" \
                 -e "s|8082|${NGINX_OPENWEBUI_PORT}|g" \
                 "$NGINX_OPENWEBUI_TEMPLATE" | \
            sudo tee "$NGINX_OPENWEBUI_CONFIG" >/dev/null 2>&1 || true
    fi

    # Configuration is valid
    echo "✅ Backend infrastructure configured: $BACKEND_TYPE ($BACKEND_URL)"
    return 0
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    # Handle --verify flag for non-interactive validation
    if [ "${1:-}" = "--verify" ]; then
        verify_environment
        exit $?
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 Backend Infrastructure Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This script configures the backend infrastructure URL and nginx proxy ports."
    echo "Services using nginx: LiteLLM (Claude Code), OTEL (telemetry), Open WebUI (chat interface)"
    echo ""

    # Check if already configured
    check_if_already_configured

    # Prompt for backend type and URL
    prompt_for_backend_type

    # Prompt for proxy ports
    prompt_for_ports

    # Setup persistent storage
    setup_persistent_storage

    # Create configuration file
    create_config_file

    # Generate nginx configs from templates
    generate_nginx_config

    # Test configuration
    test_configuration

    # Show completion
    show_completion
}

# Run main
main "$@"
