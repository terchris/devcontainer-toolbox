#!/bin/bash
# file: .devcontainer/additions/install-fwk-hugo.sh
#
# For usage information, run: ./install-fwk-hugo.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Hugo Extended static site generator
#------------------------------------------------------------------------------

# --- Core Metadata (required for dev-setup.sh) ---
SCRIPT_ID="fwk-hugo"
SCRIPT_VER="0.0.1"
SCRIPT_NAME="Hugo Extended"
SCRIPT_DESCRIPTION="Installs Hugo Extended static site generator with SCSS/SASS support."
SCRIPT_CATEGORY="FRAMEWORKS"
SCRIPT_CHECK_COMMAND="[ -f /usr/local/bin/hugo ] || command -v hugo >/dev/null 2>&1"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="hugo static-site-generator ssg framework web"
SCRIPT_ABSTRACT="Hugo Extended static site generator with SCSS/SASS support."
SCRIPT_LOGO="fwk-hugo-logo.webp"
SCRIPT_WEBSITE="https://gohugo.io"
SCRIPT_SUMMARY="Hugo Extended static site generator — the world's fastest framework for building websites. Includes SCSS/SASS compilation, image processing, and VS Code language support. Supports version pinning for theme compatibility."
SCRIPT_RELATED=""

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install Hugo Extended with default version||false|"
    "Action|--version|Install specific Hugo version||true|Enter Hugo version (e.g., 0.157.0)"
    "Action|--uninstall|Uninstall Hugo Extended||false|"
    "Info|--help|Show help and usage information||false|"
)

# System packages (none needed — Hugo is a self-contained binary)
PACKAGES_SYSTEM=()

# VS Code extensions
EXTENSIONS=(
    "Hugo Language and Syntax Support (budparr.language-hugo-vscode) - Hugo template language support"
)

#------------------------------------------------------------------------------

# Source auto-enable library
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Source logging library
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"

#------------------------------------------------------------------------------

# --- Default Configuration ---
DEFAULT_VERSION="0.157.0"  # Default version to install if --version not specified
TARGET_VERSION=""           # Actual version to install (set by --version flag or defaults to DEFAULT_VERSION)

# Hugo install location
HUGO_INSTALL_PATH="/usr/local/bin/hugo"

# --- Utility Functions ---
get_installed_hugo_version() {
    if command -v hugo > /dev/null 2>&1; then
        hugo version 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+'
    else
        echo ""
    fi
}

# --- Pre-installation/Uninstallation Setup ---
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for Hugo uninstallation..."
        local current_version
        current_version=$(get_installed_hugo_version)
        if [ -n "$current_version" ]; then
            echo "ℹ️ Detected Hugo version $current_version for uninstallation."
        else
            echo "ℹ️ Could not detect Hugo version, will remove $HUGO_INSTALL_PATH if present."
        fi
    else
        echo "🔧 Performing pre-installation setup for Hugo..."
        SYSTEM_ARCH=$(detect_architecture)
        echo "🖥️ Detected system architecture: $SYSTEM_ARCH"

        if [ -z "$TARGET_VERSION" ]; then
            TARGET_VERSION="$DEFAULT_VERSION"
            echo "ℹ️ No --version specified, using default: $TARGET_VERSION"
        else
            echo "ℹ️ Target Hugo version specified: $TARGET_VERSION"
        fi

        local current_version
        current_version=$(get_installed_hugo_version)
        if [[ "$current_version" == "$TARGET_VERSION" ]]; then
            echo "✅ Hugo $TARGET_VERSION is already installed."
        elif [ -n "$current_version" ]; then
            echo "⚠️ Hugo version $current_version is installed. This script will replace it with $TARGET_VERSION."
        fi
    fi
}

# --- Post-installation/Uninstallation Messages ---
post_installation_message() {
    local hugo_version
    hugo_version=$(get_installed_hugo_version)

    if [ -z "$hugo_version" ]; then
        hugo_version="not found"
    fi

    echo
    echo "🎉 Installation complete!"
    echo "   Hugo Extended: $hugo_version"
    echo
    echo "Quick start: hugo new site my-site"
    echo "Docs: https://gohugo.io/documentation/"
    echo
}

post_uninstallation_message() {
    local hugo_version
    hugo_version=$(get_installed_hugo_version)

    echo
    echo "🏁 Uninstallation complete!"
    if [ -n "$hugo_version" ]; then
        echo "   ⚠️  Hugo $hugo_version still found in PATH"
    else
        echo "   ✅ Hugo removed"
    fi
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
        --version)
            if [[ -n "$2" && "$2" != --* ]]; then
                TARGET_VERSION="$2"
                shift 2
            else
                echo "Error: --version requires a value (e.g., 0.157.0)" >&2
                exit 1
            fi
            ;;
        *)
            echo "Error: Unknown argument: $1" >&2
            echo "Usage: $0 [--help] [--debug] [--uninstall] [--force] [--version X.Y.Z]"
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

# Source only the core libraries Hugo needs
source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to install Hugo Extended from GitHub releases
install_hugo_binary() {
    local version="$1"
    local arch="$2"

    echo "📦 Downloading Hugo Extended $version for $arch..."

    # Hugo Extended tarball URL
    local download_url="https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_extended_${version}_linux-${arch}.tar.gz"
    local temp_file="/tmp/hugo_extended_${version}_linux-${arch}.tar.gz"

    if ! curl -fsSL "$download_url" -o "$temp_file"; then
        echo "❌ Failed to download Hugo from $download_url"
        return 1
    fi

    echo "📦 Extracting Hugo to /usr/local/bin..."

    # Remove existing binary if present
    if [ -f "$HUGO_INSTALL_PATH" ]; then
        echo "🗑️  Removing existing Hugo binary..."
        sudo rm -f "$HUGO_INSTALL_PATH"
    fi

    # Extract only the hugo binary to /usr/local/bin
    if ! sudo tar -C /usr/local/bin -xzf "$temp_file" hugo; then
        echo "❌ Failed to extract Hugo"
        rm -f "$temp_file"
        return 1
    fi

    rm -f "$temp_file"
    echo "✅ Hugo Extended $version installed successfully"
    return 0
}

# Function to process installations
process_installations() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        # Uninstall Hugo binary
        if [ -f "$HUGO_INSTALL_PATH" ]; then
            echo "🗑️  Removing Hugo binary from $HUGO_INSTALL_PATH..."
            sudo rm -f "$HUGO_INSTALL_PATH"
            echo "✅ Hugo removed"
        else
            echo "ℹ️  No Hugo binary found at $HUGO_INSTALL_PATH"
        fi

        # Uninstall extensions
        if [ ${#EXTENSIONS[@]} -gt 0 ]; then
            process_extensions "EXTENSIONS"
        fi
    else
        # Install Hugo binary
        SYSTEM_ARCH=$(detect_architecture)

        # Map architecture names
        case "$SYSTEM_ARCH" in
            amd64|x86_64) SYSTEM_ARCH="amd64" ;;
            arm64|aarch64) SYSTEM_ARCH="arm64" ;;
        esac

        if ! install_hugo_binary "$TARGET_VERSION" "$SYSTEM_ARCH"; then
            echo "❌ Hugo installation failed"
            exit 1
        fi

        # Use standard processing for extensions
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
