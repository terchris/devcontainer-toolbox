#!/bin/bash
# file: .devcontainer/additions/install-tool-sql-rest.sh
#
# Installs SQL database management (SQLTools) and REST API testing (REST Client)
# VS Code extensions. Language-agnostic tools useful for any backend project.
# For usage information, run: ./install-tool-sql-rest.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# --- Script Metadata ---
SCRIPT_ID="tool-sql-rest"
SCRIPT_VER="0.0.1"
SCRIPT_NAME="SQL & REST Tools"
SCRIPT_DESCRIPTION="Database management (Database Client) and REST API testing (REST Client) for multi-language development"
SCRIPT_CATEGORY="INFRA_CONFIG"

# NOTE: We check only the primary extension (Database Client) instead of all extensions
# to avoid tight coupling between SCRIPT_CHECK_COMMAND and the EXTENSIONS array.
# This makes the script more maintainable - if someone adds/removes extensions,
# they don't need to update this check. The extension installer is idempotent anyway.
SCRIPT_CHECK_COMMAND="code --list-extensions 2>/dev/null | grep -q 'cweijan.vscode-database-client2'"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="database sql rest http api mongodb redis"
SCRIPT_ABSTRACT="SQL/NoSQL database management and REST API testing tools for VS Code."
SCRIPT_LOGO="tool-sql-rest-logo.webp"
SCRIPT_WEBSITE="https://database-client.com"
SCRIPT_SUMMARY="Language-agnostic VS Code extensions: Database Client by cweijan for database management (MySQL, PostgreSQL, SQLite, MSSQL, MongoDB, Redis, ClickHouse, ElasticSearch — all drivers bundled, no separate driver install) and REST Client for HTTP API testing. Docker CLI is provided by the devcontainer feature — no separate install needed."
SCRIPT_RELATED="tool-api-dev tool-kubernetes"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install SQL & REST tools||false|"
    "Action|--uninstall|Uninstall SQL & REST tools||false|"
    "Info|--help|Show help and usage information||false|"
)

# System packages (none — Docker CLI is provided by devcontainer feature)
PACKAGES_SYSTEM=()

# Node.js packages
PACKAGES_NODE=()

# Python packages
PACKAGES_PYTHON=()

# VS Code extensions
EXTENSIONS=(
    "Database Client (cweijan.vscode-database-client2) - Database management for MySQL, PostgreSQL, SQLite, MSSQL, MongoDB, Redis, ClickHouse, ElasticSearch — all drivers bundled"
    "REST Client (humao.rest-client) - Send HTTP requests and view responses directly in VS Code"
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

# --- Pre-installation/Uninstallation Setup ---
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."
    fi
}

# --- Post-installation/Uninstallation Messages ---
post_installation_message() {
    echo
    echo "🎉 Installation complete!"
    echo
    echo "Quick start:"
    echo "  - Database Client: Click database icon in VS Code sidebar, then 'Create Connection'"
    echo "                     (Drivers for MySQL, PostgreSQL, SQLite, MSSQL, MongoDB, Redis are bundled)"
    echo "  - REST Client:     Create .http file and write HTTP requests"
    echo
    echo "Example .http file:"
    echo "  GET https://api.github.com/users/octocat"
    echo
    echo "Docs: https://marketplace.visualstudio.com/items?itemName=cweijan.vscode-database-client2"
    echo "      https://marketplace.visualstudio.com/items?itemName=humao.rest-client"
    echo
}

post_uninstallation_message() {
    echo
    echo "🏁 Uninstallation complete!"
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
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

# Note: lib/install-common.sh already sourced earlier (needed for --help)

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to process installations
process_installations() {
    # Use standard processing from lib/install-common.sh
    process_standard_installations
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
