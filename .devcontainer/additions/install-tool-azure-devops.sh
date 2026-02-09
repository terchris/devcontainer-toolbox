#!/bin/bash
# file: .devcontainer/additions/install-tool-azure-devops.sh
#
# Installs Azure CLI with the azure-devops extension for working with Azure DevOps
# repositories, pull requests, and pipelines from the command line.
# For usage information, run: ./install-tool-azure-devops.sh --help
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# --- Script Metadata ---
SCRIPT_ID="tool-azure-devops"
SCRIPT_VER="0.0.1"
SCRIPT_NAME="Azure DevOps CLI"
SCRIPT_DESCRIPTION="Installs Azure CLI with azure-devops extension for git PR, merge, and repo management"
SCRIPT_CATEGORY="CLOUD_TOOLS"
SCRIPT_CHECK_COMMAND="az extension show --name azure-devops >/dev/null 2>&1"

# --- Extended Metadata (for website documentation) ---
SCRIPT_TAGS="azure devops git pr merge repos cli pipelines"
SCRIPT_ABSTRACT="Lightweight Azure DevOps CLI for pull requests, merges, and repository management."
SCRIPT_LOGO="tool-azure-devops-logo.webp"
SCRIPT_WEBSITE="https://learn.microsoft.com/en-us/azure/devops/cli/"
SCRIPT_SUMMARY="Minimal Azure CLI installation with the azure-devops extension. Enables az repos pr create/list/show/update commands for working with Azure DevOps repositories without the heavy extras from tool-azure-dev or tool-azure-ops."
SCRIPT_RELATED="tool-azure-dev tool-azure-ops config-azure-devops"

# Commands for dev-setup.sh menu integration
SCRIPT_COMMANDS=(
    "Action||Install Azure DevOps CLI||false|"
    "Action|--uninstall|Uninstall Azure DevOps CLI||false|"
    "Info|--help|Show help and usage information||false|"
)

# System packages - only Azure CLI
PACKAGES_SYSTEM=(
    "azure-cli"  # Installed from Microsoft APT repository
)

# No Node.js packages needed
PACKAGES_NODE=()

# No VS Code extensions - this is CLI-only
EXTENSIONS=()

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

        # Add Azure CLI repository before package installation
        add_azure_cli_repository
    fi
}

# --- Add Azure CLI Repository ---
add_azure_cli_repository() {
    echo "➕ Adding Azure CLI repository..."

    local keyring_dir="/etc/apt/keyrings"
    local keyring_file="$keyring_dir/microsoft-azure-cli.gpg"
    local repo_file="/etc/apt/sources.list.d/azure-cli.list"

    # Check if repository already configured
    if [ -f "$repo_file" ] && grep -q "packages.microsoft.com/repos/azure-cli" "$repo_file" 2>/dev/null; then
        echo "✅ Azure CLI repository already configured"
        sudo apt-get update -y > /dev/null 2>&1
        return
    fi

    # Create keyrings directory if needed
    sudo mkdir -p "$keyring_dir"

    # Download and install Microsoft signing key
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
        sudo gpg --dearmor -o "$keyring_file"

    # Add Azure CLI repository
    local distro_codename=$(lsb_release -cs)
    echo "deb [arch=amd64 signed-by=$keyring_file] https://packages.microsoft.com/repos/azure-cli/ ${distro_codename} main" | \
        sudo tee "$repo_file"

    # Update package lists
    sudo apt-get update -y > /dev/null 2>&1
    echo "✅ Azure CLI repository added successfully"
}

# --- Post-installation Setup ---
post_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        # Remove the azure-devops extension on uninstall
        echo "🔧 Removing azure-devops extension..."
        az extension remove --name azure-devops 2>/dev/null || true
    else
        # Install the azure-devops extension
        echo "🔧 Installing azure-devops extension..."
        az extension add --name azure-devops --yes 2>/dev/null || \
            az extension add --name azure-devops 2>/dev/null || true
        echo "✅ azure-devops extension installed"
    fi
}

# --- Post-installation/Uninstallation Messages ---
post_installation_message() {
    echo
    echo "🎉 Installation complete!"
    echo
    echo "Quick start - Azure DevOps CLI:"
    echo "  - Configure defaults:    az devops configure --defaults organization=https://dev.azure.com/MyOrg project=MyProject"
    echo "  - Login with PAT:        export AZURE_DEVOPS_EXT_PAT=<your-pat>"
    echo "  - Or use dev-setup:      dev-setup → Manage Configurations → Azure DevOps Identity"
    echo
    echo "Pull Request commands:"
    echo "  - Create PR:             az repos pr create --title \"My PR\" --source-branch feature/x"
    echo "  - List PRs:              az repos pr list"
    echo "  - Show PR:               az repos pr show --id 123"
    echo "  - Set auto-complete:     az repos pr update --id 123 --auto-complete true"
    echo "  - Approve PR:            az repos pr set-vote --id 123 --vote approve"
    echo
    echo "Repository commands:"
    echo "  - List repos:            az repos list"
    echo "  - Show repo:             az repos show --repository myrepo"
    echo
    echo "Docs:"
    echo "  - Azure DevOps CLI:      https://learn.microsoft.com/en-us/azure/devops/cli/"
    echo "  - PAT tokens:            https://learn.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate"
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
source "${SCRIPT_DIR}/lib/core-install-node.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to process installations
process_installations() {
    # Use standard processing from lib/install-common.sh
    process_standard_installations

    # After standard installations, handle the azure-devops extension
    post_installation_setup
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
