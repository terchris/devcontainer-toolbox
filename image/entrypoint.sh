#!/bin/bash
# file: image/entrypoint.sh
# Purpose: Container startup script that runs regardless of IDE or tool
# Called by: Docker ENTRYPOINT (runs on every container start)
#
# This replaces postCreateCommand.sh and postStartCommand.sh for non-VS-Code
# environments (VS 2026, Docker CLI, Podman, JetBrains). For VS Code and
# Codespaces, the devcontainer lifecycle hooks still run on top of this.
#
# All output is captured to /tmp/.dct-startup.log so the welcome message
# can stream it to the user when they open the first terminal.
#
# All operations MUST be idempotent — safe to run multiple times.

set -e

DCT_HOME="${DCT_HOME:-/opt/devcontainer-toolbox}"
DCT_WORKSPACE="${DCT_WORKSPACE:-/workspace}"
ADDITIONS_DIR="$DCT_HOME/additions"
INIT_MARKER="/tmp/.dct-initialized"
STARTUP_LOG="/tmp/.dct-startup.log"

# Redirect ALL output (stdout + stderr) to the log file.
# The entrypoint runs as PID 1 before any IDE connects, so stdout is
# invisible anyway. The welcome script streams this file to the user.
: > "$STARTUP_LOG"
exec >> "$STARTUP_LOG" 2>&1

# =============================================================================
# EVERY START — runs on every container start
# =============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DevContainer Toolbox — Starting up"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Mark workspace git folder as safe (depends on mount path)
git config --global --add safe.directory "$DCT_WORKSPACE" 2>/dev/null || true
git config --global core.fileMode false 2>/dev/null || true
git config --global core.hideDotFiles false 2>/dev/null || true

# Ensure .devcontainer.secrets is in .gitignore (issue #40)
if [ -f "$ADDITIONS_DIR/lib/ensure-gitignore.sh" ]; then
    source "$ADDITIONS_DIR/lib/ensure-gitignore.sh"
fi

# Ensure .vscode/extensions.json recommends Dev Containers extension (issue #49)
if [ -f "$ADDITIONS_DIR/lib/ensure-vscode-extensions.sh" ]; then
    source "$ADDITIONS_DIR/lib/ensure-vscode-extensions.sh"
fi

# Ensure Claude Code credentials symlink for persistence across rebuilds (issue #46)
if [ -f "$ADDITIONS_DIR/lib/claude-credential-sync.sh" ]; then
    source "$ADDITIONS_DIR/lib/claude-credential-sync.sh"
fi

# Apply host-captured git identity if available (from initializeCommand).
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
echo ""
echo "🔐 Configuring git identity..."
if [ -f "$ADDITIONS_DIR/config-git.sh" ]; then
    bash "$ADDITIONS_DIR/config-git.sh" --verify || true
fi

# Restore Azure DevOps configuration (non-interactive)
if [ -f "$ADDITIONS_DIR/config-azure-devops.sh" ]; then
    echo ""
    echo "🔐 Restoring Azure DevOps configuration..."
    bash "$ADDITIONS_DIR/config-azure-devops.sh" --verify || true
fi

# Refresh host info
if [ -f "$ADDITIONS_DIR/config-host-info.sh" ]; then
    bash "$ADDITIONS_DIR/config-host-info.sh" --refresh 2>/dev/null || true
fi

# Start supervisord services (checks PID file, won't start twice)
echo ""
echo "🔧 Starting services..."
if [ -f /etc/supervisor/supervisord.conf ]; then
    if [ -f "$ADDITIONS_DIR/lib/tool-installation.sh" ]; then
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

# Auto-sync scripts (quiet, non-blocking, 10s timeout)
if [ -f "$DCT_HOME/manage/dev-sync.sh" ]; then
    echo ""
    echo "🔄 Checking for script updates..."
    timeout 10 bash "$DCT_HOME/manage/dev-sync.sh" --quiet 2>/dev/null || true
fi

# =============================================================================
# FIRST START ONLY — runs once when container is first created
# =============================================================================

if [ ! -f "$INIT_MARKER" ]; then

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 First start — setting up container..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Create .devcontainer.extend/ with template files if it doesn't exist.
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
    echo ""
    echo "🔐 Restoring saved configurations..."
    if [ -f "$ADDITIONS_DIR/lib/component-scanner.sh" ]; then
        source "$ADDITIONS_DIR/lib/component-scanner.sh" 2>/dev/null || true

        while IFS=$'\t' read -r script_basename config_name config_desc config_cat check_cmd; do
            local_config_path="$ADDITIONS_DIR/$script_basename"
            if [ -f "$local_config_path" ] && grep -q '= "--verify"' "$local_config_path" 2>/dev/null; then
                if bash "$local_config_path" --verify 2>/dev/null; then
                    echo "   ✅ $config_name restored"
                fi
            fi
        done < <(scan_config_scripts "$ADDITIONS_DIR" 2>/dev/null) || true
    fi

    # Install non-default tools from enabled-tools.conf
    echo ""
    echo "📦 Installing tools from enabled-tools.conf..."
    if [ -f "$ADDITIONS_DIR/lib/tool-installation.sh" ]; then
        source "$ADDITIONS_DIR/lib/install-common.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/component-scanner.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/prerequisite-check.sh" 2>/dev/null || true
        source "$ADDITIONS_DIR/lib/tool-installation.sh" 2>/dev/null || true
        install_enabled_tools "$ADDITIONS_DIR" \
            "$DCT_WORKSPACE/.devcontainer.extend/enabled-tools.conf" || true
    fi

    # Run project-specific installations
    if [ -f "$DCT_WORKSPACE/.devcontainer.extend/project-installs.sh" ]; then
        echo ""
        echo "🔧 Running project-installs.sh..."
        bash "$DCT_WORKSPACE/.devcontainer.extend/project-installs.sh" || true
    fi

    touch "$INIT_MARKER"
fi

# =============================================================================
# COMPLETION
# =============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Startup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Quick Start:"
echo "   dev-setup       Main menu - install tools, manage services"
echo "   dev-help        Show all available commands"
echo "   dev-check       Configure required settings (Git identity, etc.)"
echo ""

# Check if Git identity is configured
_git_name=$(git config --global user.name 2>/dev/null || echo "")
_git_email=$(git config --global user.email 2>/dev/null || echo "")
if [ -z "$_git_name" ] || [ -z "$_git_email" ] || [[ "$_git_email" == *@localhost ]]; then
    echo "⚠️  Git identity not configured - run 'dev-setup' to set your name and email"
    echo ""
fi

# Check git provider authentication
_git_remote=$(git -C "$DCT_WORKSPACE" config --get remote.origin.url 2>/dev/null || echo "")

if [ -z "$_git_remote" ]; then
    # No repo or no remote - show how to get started
    echo "💡 No code repository found in this folder."
    echo ""
    echo "   To work with GitHub repositories:"
    echo "   1. Run: gh auth login"
    echo "   2. Run: gh repo clone <owner>/<repo-name>"
    echo "      Example: gh repo clone microsoft/vscode"
    echo ""
    echo "   To work with Azure DevOps repositories:"
    echo "   1. Run: dev-setup → Cloud Tools → Azure DevOps CLI"
    echo "   2. Run: dev-setup → Setup & Configuration → Azure DevOps Identity"
    echo "      (This will configure your PAT and offer to clone your repo)"
    echo ""
elif [[ "$_git_remote" == *"github.com"* ]]; then
    # GitHub repo - check if authenticated
    if ! gh auth status &>/dev/null 2>&1; then
        echo "💡 GitHub repository detected but not authenticated."
        echo "   To create pull requests and manage issues, run:"
        echo "   gh auth login"
        echo ""
    fi
elif [[ "$_git_remote" == *"dev.azure.com"* ]] || [[ "$_git_remote" == *"visualstudio.com"* ]]; then
    # Azure DevOps repo - check if CLI installed and PAT configured
    if ! command -v az &>/dev/null; then
        echo "💡 Azure DevOps repository detected but CLI not installed."
        echo "   To create pull requests, run:"
        echo "   dev-setup → Cloud Tools → Azure DevOps CLI"
        echo ""
    elif [ ! -f "$DCT_WORKSPACE/.devcontainer.secrets/env-vars/azure-devops-pat" ]; then
        echo "💡 Azure DevOps repository detected but not authenticated."
        echo "   To create pull requests, run:"
        echo "   dev-setup → Manage Configurations → Azure DevOps Identity"
        echo ""
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# =============================================================================
# HAND OFF — execute whatever was passed as CMD (e.g., "sleep infinity")
# =============================================================================

# Save a permanent copy for dev-log (before we close the file)
cp "$STARTUP_LOG" "${STARTUP_LOG}.saved" 2>/dev/null || true

# Restore stdout/stderr for the CMD process
exec 1>/dev/null 2>/dev/null
exec "$@"
