#!/bin/bash
# file: image/entrypoint.sh
# Purpose: Container startup script that runs regardless of IDE or tool
# Called by: Docker ENTRYPOINT (runs on every container start)
#
# This replaces postCreateCommand.sh and postStartCommand.sh for non-VS-Code
# environments (VS 2026, Docker CLI, Podman, JetBrains). For VS Code and
# Codespaces, the devcontainer lifecycle hooks still run on top of this.
#
# All operations MUST be idempotent — safe to run multiple times.

set -e

DCT_HOME="${DCT_HOME:-/opt/devcontainer-toolbox}"
DCT_WORKSPACE="${DCT_WORKSPACE:-/workspace}"
ADDITIONS_DIR="$DCT_HOME/additions"
INIT_MARKER="/tmp/.dct-initialized"
STARTUP_LOG="/tmp/.dct-startup.log"

# Logging helper — writes to both stdout (Docker logs) and the startup log file
: > "$STARTUP_LOG"  # truncate log file
log() { echo "$@" | tee -a "$STARTUP_LOG"; }

# =============================================================================
# EVERY START — runs on every container start
# =============================================================================

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "DevContainer Toolbox — Starting up"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Mark workspace git folder as safe (depends on mount path)
git config --global --add safe.directory "$DCT_WORKSPACE" 2>/dev/null || true
git config --global core.fileMode false 2>/dev/null || true
git config --global core.hideDotFiles false 2>/dev/null || true

# Apply host-captured git identity (written by initializeCommand on the host).
# These files contain the developer's real name/email from the host machine.
# Setting git config here ensures config-git.sh --verify finds correct values.
HOST_GIT_NAME_FILE="$DCT_WORKSPACE/.devcontainer.secrets/env-vars/.git-host-name"
HOST_GIT_EMAIL_FILE="$DCT_WORKSPACE/.devcontainer.secrets/env-vars/.git-host-email"

if [ -f "$HOST_GIT_NAME_FILE" ]; then
    _host_name=$(cat "$HOST_GIT_NAME_FILE" 2>/dev/null | tr -d '\n\r')
    if [ -n "$_host_name" ]; then
        git config --global user.name "$_host_name" 2>/dev/null || true
    fi
fi
if [ -f "$HOST_GIT_EMAIL_FILE" ]; then
    _host_email=$(cat "$HOST_GIT_EMAIL_FILE" 2>/dev/null | tr -d '\n\r')
    if [ -n "$_host_email" ]; then
        git config --global user.email "$_host_email" 2>/dev/null || true
    fi
fi

# Refresh git identity (non-interactive)
log "  Configuring git identity..."
if [ -f "$ADDITIONS_DIR/config-git.sh" ]; then
    bash "$ADDITIONS_DIR/config-git.sh" --verify 2>/dev/null || true
fi

# Refresh host info
if [ -f "$ADDITIONS_DIR/config-host-info.sh" ]; then
    bash "$ADDITIONS_DIR/config-host-info.sh" --refresh 2>/dev/null || true
fi

# Start supervisord services (checks PID file, won't start twice)
log "  Starting services..."
if [ -f /etc/supervisor/supervisord.conf ]; then
    # Source tool-installation.sh if available (has start_supervisor_services)
    if [ -f "$ADDITIONS_DIR/lib/tool-installation.sh" ]; then
        # Source required dependencies
        source "$ADDITIONS_DIR/lib/install-common.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/component-scanner.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/prerequisite-check.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/tool-installation.sh" 2>/dev/null || true
        start_supervisor_services "$ADDITIONS_DIR" 2>/dev/null || true
    else
        sudo supervisord -c /etc/supervisor/supervisord.conf 2>/dev/null || true
    fi
fi

# Start OTel monitoring if enabled
if [ -f "$ADDITIONS_DIR/service-otel-monitoring.sh" ]; then
    if [ -f "$DCT_WORKSPACE/.devcontainer.extend/enabled-tools.conf" ]; then
        if grep -q "^service-otel-monitoring" "$DCT_WORKSPACE/.devcontainer.extend/enabled-tools.conf" 2>/dev/null; then
            bash "$ADDITIONS_DIR/service-otel-monitoring.sh" --start 2>/dev/null || true
        fi
    fi
fi

# Send startup event if OTel is running
if [ -f "$ADDITIONS_DIR/otel/scripts/send-event-notification.sh" ]; then
    if pgrep -f "otelcol-contrib" > /dev/null 2>&1; then
        bash "$ADDITIONS_DIR/otel/scripts/send-event-notification.sh" \
            --event-type "devcontainer.started" \
            --message "Devcontainer started" \
            --quiet 2>/dev/null || true
    fi
fi

# Send tool inventory if OTel is running
if [ -f "$ADDITIONS_DIR/otel/scripts/send-tools-inventory.sh" ]; then
    if pgrep -f "otelcol-contrib" > /dev/null 2>&1; then
        bash "$ADDITIONS_DIR/otel/scripts/send-tools-inventory.sh" --quiet 2>/dev/null || true
    fi
fi

# =============================================================================
# FIRST START ONLY — runs once when container is first created
# =============================================================================

if [ ! -f "$INIT_MARKER" ]; then

    log ""
    log "  First start — setting up container..."

    # Create .devcontainer.extend/ with template files if it doesn't exist.
    # In copy mode this directory is part of the toolbox files.
    # In image mode we create it so dev-setup and tool auto-install work.
    EXTEND_DIR="$DCT_WORKSPACE/.devcontainer.extend"
    if [ ! -d "$EXTEND_DIR" ]; then
        mkdir -p "$EXTEND_DIR"
    fi
    if [ ! -f "$EXTEND_DIR/enabled-tools.conf" ]; then
        cat > "$EXTEND_DIR/enabled-tools.conf" <<'TOOLS_EOF'
# Enabled Tools for Auto-Install
# Tools listed here will automatically install when the container is created/rebuilt
# Format: One tool identifier per line (matches SCRIPT_ID in install-*.sh)
#
# Available tools: run 'dev-setup' to see and install tools interactively
# Installed tools are automatically added here
#
# Example:
#   dev-golang          # Will run install-dev-golang.sh if not already installed
TOOLS_EOF
    fi
    if [ ! -f "$EXTEND_DIR/enabled-services.conf" ]; then
        cat > "$EXTEND_DIR/enabled-services.conf" <<'SERVICES_EOF'
# Enabled Services for Auto-Start
# Services listed here will automatically start when the container starts
# Format: One service identifier per line (matches SCRIPT_ID in service-*.sh)
#
# Management:
#   dev-services enable <service>   - Enable a service
#   dev-services disable <service>  - Disable a service
#   dev-services list-enabled       - Show enabled services
SERVICES_EOF
    fi
    if [ ! -f "$EXTEND_DIR/project-installs.sh" ]; then
        cat > "$EXTEND_DIR/project-installs.sh" <<'PROJECT_EOF'
#!/bin/bash
# File: .devcontainer.extend/project-installs.sh
# Purpose: Project-specific custom installations
# This script runs AFTER all standard tools from enabled-tools.conf are installed.
#
# Use this for:
#   - Project-specific npm/pip/cargo packages
#   - Database setup scripts
#   - Custom configuration

set -e

# ADD YOUR CUSTOM INSTALLATIONS BELOW
# Example: pip install -r requirements.txt
# Example: npm install

exit 0
PROJECT_EOF
        chmod +x "$EXTEND_DIR/project-installs.sh"
    fi

    # Restore configurations from .devcontainer.secrets (non-interactive)
    log "  Restoring saved configurations..."
    if [ -f "$ADDITIONS_DIR/lib/component-scanner.sh" ]; then
        source "$ADDITIONS_DIR/lib/component-scanner.sh" 2>/dev/null || true

        while IFS=$'\t' read -r script_basename config_name config_desc config_cat check_cmd; do
            local_config_path="$ADDITIONS_DIR/$script_basename"
            if [ -f "$local_config_path" ] && grep -q '= "--verify"' "$local_config_path" 2>/dev/null; then
                bash "$local_config_path" --verify 2>/dev/null || true
            fi
        done < <(scan_config_scripts "$ADDITIONS_DIR" 2>/dev/null) || true
    fi

    # Install non-default tools from enabled-tools.conf
    # Default tools are baked into the image. Any extra tools the developer
    # added via dev-setup are listed in enabled-tools.conf and must be
    # re-installed when a new container is created (e.g., after dev-update).
    log "  Installing tools from enabled-tools.conf..."
    if [ -f "$ADDITIONS_DIR/lib/tool-installation.sh" ]; then
        source "$ADDITIONS_DIR/lib/install-common.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/component-scanner.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/prerequisite-check.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/tool-installation.sh" 2>/dev/null || true
        install_enabled_tools "$ADDITIONS_DIR" \
            "$DCT_WORKSPACE/.devcontainer.extend/enabled-tools.conf" 2>/dev/null || true
    fi

    # Run project-specific installations
    if [ -f "$DCT_WORKSPACE/.devcontainer.extend/project-installs.sh" ]; then
        log "  Running project-installs.sh..."
        bash "$DCT_WORKSPACE/.devcontainer.extend/project-installs.sh" 2>/dev/null || true
    fi

    touch "$INIT_MARKER"
    log "  First-start setup complete."
fi

log ""
log "  Startup complete. Type 'dev-help' for available commands."
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# =============================================================================
# HAND OFF — execute whatever was passed as CMD (e.g., "sleep infinity")
# =============================================================================
exec "$@"
