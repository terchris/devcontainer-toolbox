#!/bin/bash
# file: .devcontainer/additions/install-dev-ai-claudecode.sh
#
# Installs Claude Code, Anthropic's terminal-based AI coding assistant.
# For usage information, run: ./install-dev-ai-claudecode.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# Script metadata - must be at the very top of the configuration section
SCRIPT_NAME="Claude Code"
SCRIPT_ID="dev-ai-claudecode"
SCRIPT_VER="0.0.2"
SCRIPT_DESCRIPTION="Installs Claude Code, Anthropic's terminal-based AI coding assistant with agentic capabilities and LSP integration"
SCRIPT_CATEGORY="AI_TOOLS"
SCRIPT_CHECK_COMMAND="[ -f /home/vscode/.local/bin/claude ] || command -v claude >/dev/null 2>&1"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="claude anthropic ai coding assistant agentic terminal"
SCRIPT_ABSTRACT="Claude Code - Anthropic's terminal-based AI coding assistant with agentic capabilities."
SCRIPT_LOGO="dev-ai-claudecode-logo.webp"
SCRIPT_WEBSITE="https://claude.ai/code"
SCRIPT_SUMMARY="Claude Code is Anthropic's terminal-based AI coding assistant with agentic capabilities. Features include codebase understanding, multi-file editing, shell command execution, and LSP integration for intelligent code assistance directly in your terminal."
SCRIPT_RELATED="tool-api-dev"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install Claude Code||false|"
    "Action|--uninstall|Uninstall Claude Code||false|"
    "Info|--help|Show help and usage information||false|"
)

#------------------------------------------------------------------------------

# Source auto-enable library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Source logging library
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

# Set up Claude credentials symlink for persistence across rebuilds (issue #46)
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/claude-credential-sync.sh"

#------------------------------------------------------------------------------

# Before running installation, we need to add any required repositories or setup
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
        # Remove native installation
        if [ -f "$HOME/.local/bin/claude" ]; then
            echo "Removing Claude Code native installation..."
            rm -f "$HOME/.local/bin/claude"
        fi
        # Remove npm global installation if exists
        if command -v npm &>/dev/null && npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
            echo "Removing Claude Code npm installation..."
            npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        fi
    else
        echo "🔧 Installing Claude Code using native method (enables auto-updates)..."

        # Ensure ~/.local/bin exists and is in PATH
        mkdir -p "$HOME/.local/bin"
        if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
            echo '' >> "$HOME/.bashrc"
            echo '# Claude Code native installation' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        fi
        export PATH="$HOME/.local/bin:$PATH"

        # Remove any existing npm global installation (causes conflicts)
        if command -v npm &>/dev/null && npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
            echo "Removing existing npm global installation..."
            npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        fi

        # Install using native method (to ~/.local/bin/claude)
        # This allows auto-updates without sudo
        echo "Downloading and installing Claude Code..."
        curl -fsSL https://claude.ai/install.sh | bash

        echo "✅ Claude Code installed to ~/.local/bin/claude (auto-updates enabled)"
    fi
}

# Define package arrays (remove any empty arrays that aren't needed)
PACKAGES_SYSTEM=(
    "curl"
)

# Note: We use native installation instead of npm to enable auto-updates
# See: https://github.com/terchris/devcontainer-toolbox/issues/41
PACKAGES_NODE=()

PACKAGES_PYTHON=()

# Define VS Code extensions (format: "Name (extension-id) - Description")
EXTENSIONS=()

# Define verification commands
VERIFY_COMMANDS=(
    "test -f /home/vscode/.local/bin/claude && echo '✅ Claude Code installed at ~/.local/bin/claude (native)' || echo '❌ Claude Code native installation not found'"
    "command -v claude >/dev/null && echo '✅ Claude Code binary is in PATH' || echo '❌ Claude Code binary not in PATH'"
    "claude --version 2>/dev/null && echo '✅ Claude Code is functional' || echo '⚠️  Claude Code version check failed'"
)

# Post-installation notes
post_installation_message() {

    echo
    echo "🎉 Installation process complete for: $SCRIPT_NAME!"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    echo
    echo "Important Notes:"
    echo "1. Claude Code installed to ~/.local/bin/claude (native installation)"
    echo "2. Auto-updates are enabled (no sudo required)"
    echo "3. Run 'claude doctor' to verify auto-update capability"
    echo
    echo "Quick Start:"
    echo "- Check installation: claude --version"
    echo "- Verify auto-updates: claude doctor"
    echo "- Start coding: claude"
    echo
    echo "Documentation Links:"
    echo "- Claude Code: https://claude.ai/code"
}

# Post-uninstallation notes
post_uninstallation_message() {

    # Remove from auto-enable config
    auto_disable_tool
    echo
    echo "🏁 Uninstallation process complete for: $SCRIPT_NAME!"
    echo
    echo "Additional Notes:"
    echo "1. Claude Code has been removed from ~/.local/bin/"
    echo "2. Configuration in ~/.claude/ remains (delete manually if needed)"
}

#------------------------------------------------------------------------------
# MAIN SCRIPT EXECUTION - Do not modify below this line
#------------------------------------------------------------------------------

# Initialize mode flags
DEBUG_MODE=0
UNINSTALL_MODE=0
FORCE_MODE=0

# Source common installation patterns library (needed for --help)
source "${SCRIPT_DIR}/lib/install-common.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_script_help
            exit 0
            ;;
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        --uninstall)
            UNINSTALL_MODE=1
            shift
            ;;
        --force)
            FORCE_MODE=1
            shift
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Usage: $0 [--help] [--debug] [--uninstall] [--force]" >&2
            echo "Description: $SCRIPT_DESCRIPTION"
            exit 1
            ;;
    esac
done

# Export mode flags for core scripts
export DEBUG_MODE
export UNINSTALL_MODE
export FORCE_MODE

# Source all core installation scripts
source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-node.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"
source "${SCRIPT_DIR}/lib/core-install-pwsh.sh"
source "${SCRIPT_DIR}/lib/core-install-python.sh"

# Note: lib/install-common.sh already sourced earlier (needed for --help)

# Function to process installations
process_installations() {
    # Process standard installations (packages and extensions)
    process_standard_installations
}



# Main execution
if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    show_install_header "uninstall"
    pre_installation_setup
    process_installations
    post_uninstallation_message

    # Remove from auto-enable config
    auto_disable_tool
else
    show_install_header
    pre_installation_setup
    process_installations
    verify_installations
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool
fi
