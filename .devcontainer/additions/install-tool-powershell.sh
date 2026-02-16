#!/bin/bash
# file: .devcontainer/additions/install-tool-powershell.sh
#
# Installs PowerShell 7 with PSScriptAnalyzer for script development and linting.
# Lightweight alternative to install-tool-azure-ops.sh (no Azure CLI or heavy modules).
# For usage information, run: ./install-tool-powershell.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# --- Core Metadata (required for dev-setup.sh) ---
SCRIPT_ID="tool-powershell"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="PowerShell"
SCRIPT_DESCRIPTION="Installs PowerShell 7 with PSScriptAnalyzer for script development and linting"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command -v pwsh >/dev/null 2>&1 || [ -f /usr/bin/pwsh ]"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="powershell pwsh intune linting scripting"
SCRIPT_ABSTRACT="PowerShell 7 with PSScriptAnalyzer for script development and linting."
SCRIPT_WEBSITE="https://learn.microsoft.com/en-us/powershell/"
SCRIPT_RELATED="tool-azure-ops"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install PowerShell||false|"
    "Action|--uninstall|Uninstall PowerShell||false|"
    "Info|--help|Show help and usage information||false|"
)

#------------------------------------------------------------------------------

# Source auto-enable library for automatic addition to enabled-tools.conf
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Source logging library for automatic logging to /tmp/devcontainer-install/
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

#------------------------------------------------------------------------------
# VERSION CONFIGURATION
#------------------------------------------------------------------------------

DEFAULT_VERSION="7.5.4"  # PowerShell 7.5.4 (latest stable as of October 2025)
TARGET_VERSION=""        # Actual version to install (can be overridden with --version)

#------------------------------------------------------------------------------

# Custom PowerShell installation function
install_powershell() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🗑️  Removing PowerShell installation..."

        # Remove symbolic links
        if [ -L "/usr/local/bin/pwsh" ]; then
            sudo rm -f /usr/local/bin/pwsh
            echo "✅ Removed /usr/local/bin/pwsh symlink"
        fi
        if [ -L "/usr/bin/pwsh" ]; then
            sudo rm -f /usr/bin/pwsh
            echo "✅ Removed /usr/bin/pwsh symlink"
        fi

        # Remove PowerShell installation directory
        if [ -d "/opt/microsoft/powershell" ]; then
            sudo rm -rf /opt/microsoft/powershell
            echo "✅ Removed PowerShell installation directory"
        fi

        # Remove PowerShell modules directory
        if [ -d "$HOME/.local/share/powershell" ]; then
            rm -rf "$HOME/.local/share/powershell"
            echo "✅ Removed PowerShell modules directory"
        fi

        return
    fi

    # Check if PowerShell is already installed
    if command -v pwsh >/dev/null 2>&1; then
        local current_version=$(pwsh -Version 2>&1 | head -n 1)
        echo "✅ PowerShell is already installed (${current_version})"
        return
    fi

    echo "📦 Installing PowerShell from GitHub releases..."

    # PowerShell version to install
    local powershell_version="${TARGET_VERSION:-${DEFAULT_VERSION}}"

    # Detect architecture using lib function
    local system_arch=$(detect_architecture)
    local ps_arch
    local ps_package_url

    # Map to PowerShell naming convention
    case "$system_arch" in
        amd64)
            ps_arch="x64"
            ps_package_url="https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-linux-x64.tar.gz"
            ;;
        arm64)
            ps_arch="arm64"
            ps_package_url="https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-linux-arm64.tar.gz"
            ;;
        *)
            echo "❌ Unsupported architecture: $system_arch"
            return 1
            ;;
    esac

    echo "🖥️  Detected architecture: $system_arch (PowerShell: $ps_arch)"

    echo "⬇️  Downloading PowerShell v${powershell_version} for $ps_arch..."
    local temp_tarball="/tmp/powershell.tar.gz"

    if ! curl -L -o "$temp_tarball" "$ps_package_url" 2>/dev/null; then
        echo "❌ Failed to download PowerShell from $ps_package_url"
        return 1
    fi

    echo "📦 Installing PowerShell..."
    # Create PowerShell installation directory
    sudo mkdir -p /opt/microsoft/powershell/7

    # Extract PowerShell to installation directory
    sudo tar zxf "$temp_tarball" -C /opt/microsoft/powershell/7

    # Set executable permissions
    sudo chmod +x /opt/microsoft/powershell/7/pwsh

    # Create symbolic links for maximum compatibility
    # Link to /usr/local/bin (preferred for user-installed software)
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh
    # Link to /usr/bin (system-wide availability)
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

    # Clean up
    rm -f "$temp_tarball"

    echo "✅ PowerShell installed successfully"

    # Verify installation
    if command -v pwsh >/dev/null 2>&1; then
        echo "✅ PowerShell is now available: $(pwsh -Version 2>&1 | head -n 1)"
    else
        echo "❌ PowerShell installation failed - not found in PATH"
        return 1
    fi
}

#------------------------------------------------------------------------------

# System packages (PowerShell installed via install_powershell, not apt)
PACKAGES_SYSTEM=()

# PowerShell modules
PACKAGES_PWSH=(
    "PSScriptAnalyzer"  # PowerShell script analysis and linting
)

# VS Code extensions
EXTENSIONS=(
    "PowerShell (ms-vscode.powershell) - PowerShell language support and debugging"
)

#------------------------------------------------------------------------------

# --- Pre-installation/Uninstallation Setup ---
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."

        # Check if PowerShell is already installed
        if command -v pwsh >/dev/null 2>&1; then
            echo "✅ PowerShell is already installed (version: $(pwsh -Version 2>&1 | head -n 1))"
        fi

        echo "✅ Pre-installation setup complete"
    fi
}

#------------------------------------------------------------------------------

# --- Post-installation/Uninstallation Messages ---
post_installation_message() {
    local pwsh_version
    pwsh_version=$(pwsh -Version 2>&1 | head -n 1 || echo "not found")

    echo
    echo "🎉 Installation complete!"
    echo "   PowerShell: $pwsh_version"
    echo
    echo "Installed tools:"
    echo "  - PowerShell 7 - Cross-platform automation and scripting"
    echo "  - PSScriptAnalyzer - PowerShell script analysis and linting"
    echo
    echo "Quick start:"
    echo "  - Launch PowerShell:      pwsh"
    echo "  - Analyze a script:       pwsh -Command \"Invoke-ScriptAnalyzer -Path ./script.ps1\""
    echo "  - Check version:          pwsh -Version"
    echo
    echo "Docs:"
    echo "  - PowerShell:             https://learn.microsoft.com/powershell/"
    echo "  - PSScriptAnalyzer:       https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/overview"
    echo
    echo "Note: For Azure CLI and Az/Graph modules, use install-tool-azure-ops.sh instead."
    echo
}

post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation complete!"
    echo "   ✅ PowerShell removed from /opt/microsoft/powershell"
    echo "   ✅ PowerShell modules removed from ~/.local/share/powershell"
    echo "   ✅ Symbolic links removed from /usr/local/bin and /usr/bin"
    echo "   ✅ VS Code extension uninstalled"
    echo
    echo "Note: Run 'hash -r' or start a new shell to clear the command hash table"
    echo
}

#------------------------------------------------------------------------------
# ARGUMENT PARSING
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

# Export mode flags
export DEBUG_MODE
export UNINSTALL_MODE
export FORCE_MODE

#------------------------------------------------------------------------------
# SOURCE CORE SCRIPTS
#------------------------------------------------------------------------------

# Source core installation scripts
source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-node.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"
source "${SCRIPT_DIR}/lib/core-install-pwsh.sh"
source "${SCRIPT_DIR}/lib/core-install-python.sh"

# Note: lib/install-common.sh already sourced earlier (needed for --help)

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to process installations
process_installations() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        # During uninstall: process VS Code extensions first
        if [ ${#EXTENSIONS[@]} -gt 0 ]; then
            process_extensions "EXTENSIONS"
        fi
        # Remove PowerShell runtime and all its modules
        install_powershell
    else
        # During install: install PowerShell runtime first
        install_powershell
        # Then install modules and extensions (now that PowerShell is available)
        process_standard_installations
    fi
}

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------

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
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool
fi

echo "✅ Script execution finished."
exit 0
