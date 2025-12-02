#!/bin/bash
# file: .devcontainer/additions/_template-install-script.sh
#
# TEMPLATE: Copy this file when creating new installation scripts
# Rename to: install-[your-name].sh
# Example: install-dev-python.sh
#
# [Brief description of what this script installs]
# For usage information and available options, run: ./install-[name].sh --help
#
#------------------------------------------------------------------------------
# METADATA PATTERN - Required for automatic script discovery
#------------------------------------------------------------------------------
#
# The dev-setup.sh menu system uses the component-scanner library to automatically
# discover and display all install scripts. To make your script visible in the menu,
# you must define these four metadata fields in the CONFIGURATION section below:
#
# SCRIPT_NAME - Human-readable name displayed in the menu (2-4 words)
#   Example: "Python Development Tools"
#
# SCRIPT_DESCRIPTION - Brief description of what the script installs (one sentence)
#   Example: "Install Python 3.11, pip, and essential Python development packages"
#
# SCRIPT_CATEGORY - Category for menu organization
#   IMPORTANT: Use one of the valid categories defined in lib/categories.sh
#   Valid categories:
#     LANGUAGE_DEV    - Development Tools (Python, TypeScript, Go, Rust, etc.)
#     AI_TOOLS        - AI & Machine Learning Tools (Claude Code, etc.)
#     CLOUD_TOOLS     - Cloud & Infrastructure Tools (Azure, AWS, etc.)
#     DATA_ANALYTICS  - Data & Analytics Tools (Jupyter, pandas, DBT, etc.)
#     INFRA_CONFIG    - Infrastructure & Configuration (Ansible, Kubernetes, etc.)
#   Example: "LANGUAGE_DEV"
#
#   For full category descriptions, see: .devcontainer/additions/lib/categories.sh
#   Or run: source lib/categories.sh && show_all_categories
#
# CHECK_INSTALLED_COMMAND - Shell command to check if already installed
#   - Must return exit code 0 if installed, 1 if not installed
#   - Should suppress all output (use >/dev/null 2>&1)
#   - Should be fast (run in < 1 second)
#   - Should be idempotent (safe to run repeatedly)
#   - BEST PRACTICE: Check installation location OR PATH for better UX
#     This ensures the tool shows as installed immediately after installation,
#     even if the current shell's PATH hasn't been updated yet.
#   Examples:
#     "[ -f $HOME/.cargo/bin/rustc ] || command -v rustc >/dev/null 2>&1"
#     "[ -f /usr/local/bin/tool ] || command -v tool >/dev/null 2>&1"
#     "dpkg -l python3 2>/dev/null | grep -q '^ii'"
#     "[ -d /opt/tool ]"
#
# PREREQUISITE_CONFIGS - Space-separated list of config scripts required (OPTIONAL)
#   Use this field to declare configuration prerequisites that must exist before
#   your tool can be installed. The system will automatically check these and
#   block installation with a clear error if prerequisites are missing.
#
#   Format: Space-separated list of config script filenames
#   Example: "config-devcontainer-identity.sh config-aws-credentials.sh"
#
#   How it works:
#     1. project-installs.sh checks this field BEFORE running your install script
#     2. Uses lib/prerequisite-check.sh to verify each config is satisfied
#     3. If any prerequisite missing, shows error and skips installation
#     4. User fixes prerequisites, re-runs project-installs.sh
#
#   Two-Layer System:
#     Layer 1: Silent Restoration (restore_all_configurations)
#       - Runs BEFORE tool installation
#       - Attempts to restore ALL configs from .devcontainer.secrets
#       - SILENT for missing configs (no noise)
#
#     Layer 2: Loud Prerequisites (install_project_tools - uses this field!)
#       - Runs DURING tool installation for YOUR tool
#       - Checks YOUR PREREQUISITE_CONFIGS field
#       - LOUD error if required config missing
#       - Blocks installation until fixed
#
#   Example output when prerequisite missing:
#     ⚠️  My Tool - missing prerequisites
#       ❌ Developer Identity (run: bash .../config-devcontainer-identity.sh)
#
#     💡 To fix:
#        1. Run: check-configs
#        2. Then re-run: bash .../project-installs.sh
#
#   Leave empty if no prerequisites needed (most tools don't need this).
#
# AUTO-ENABLE PATTERN - Tools automatically add themselves to enabled-tools.conf
#   When a tool is successfully installed, it automatically adds itself to
#   .devcontainer.extend/enabled-tools.conf. This ensures the tool will be
#   reinstalled on container rebuild. This template includes the auto-enable
#   code - no changes needed unless you want custom behavior.
#
# For more details, see: .devcontainer/additions/README-additions.md
#
#------------------------------------------------------------------------------
# CONFIGURATION - Modify this section for each new script
#------------------------------------------------------------------------------

# --- Script Metadata ---
SCRIPT_ID="[category-name]"  # Unique identifier (e.g., dev-python, tool-azure, srv-nginx)
SCRIPT_NAME="[Name]"
SCRIPT_DESCRIPTION="[Brief description of what this script installs and its purpose]"
SCRIPT_CATEGORY="DEV_TOOLS"  # Options: DEV_TOOLS, INFRA_CONFIG, AI_TOOLS, MONITORING, DATABASE, CLOUD
CHECK_INSTALLED_COMMAND="command -v [tool-name] >/dev/null 2>&1"  # Command to check if already installed

# Custom usage text for --help
SCRIPT_USAGE="  $(basename "$0")              # Install
  $(basename "$0") --help       # Show this help
  $(basename "$0") --uninstall  # Uninstall"

# Optional: Prerequisite configurations required before installation
# Uncomment and modify if your tool requires specific configurations
# PREREQUISITE_CONFIGS="config-devcontainer-identity.sh"
# Multiple prerequisites: PREREQUISITE_CONFIGS="config-identity.sh config-aws-credentials.sh"

# --- IMPORTANT: Base Devcontainer Packages ---
# The following packages are PRE-INSTALLED in the base devcontainer image
# (.devcontainer/Dockerfile.base) and DO NOT need to be listed in PACKAGES_SYSTEM:
#
# Common utilities:
#   - git, curl, wget, zip, unzip, xz-utils
#   - ca-certificates, gnupg, lsb-release
#   - supervisor (process manager)
#   - jc, xdg-utils, traceroute, iproute2, iputils-ping, libcap2-bin
#
# Pre-installed runtimes:
#   - Python 3.12 (from base image mcr.microsoft.com/devcontainers/python:1-3.12-bookworm)
#   - Node.js 22.12.0 (installed via direct binary)
#   - GitHub CLI (gh)
#
# BEST PRACTICE:
# - Only add packages to PACKAGES_SYSTEM if they are truly required AND not in the base image
# - Check Dockerfile.base before adding system packages
# - For language development (Python, TypeScript, etc.), you likely DON'T need PACKAGES_SYSTEM
# - For tools needing repositories (Java, .NET, etc.), you may need a few packages for the repository setup

# System packages (usually empty for most scripts)
PACKAGES_SYSTEM=(
    # IMPORTANT: Check .devcontainer/Dockerfile.base before adding packages here
    # Most common packages (git, curl, wget, gnupg, ca-certificates, etc.) are already installed
    # "package1"  # Only add if truly needed AND not in base image
)

# Language-specific packages (choose one that matches your script)
# PACKAGES_GO=(
#     # "golang.org/x/tools/gopls@latest"
# )
#
# PACKAGES_JAVA=(
#     # "maven"
# )
#
# PACKAGES_PYTHON=(
#     # "pytest"
# )
#
# PACKAGES_CARGO=(
#     # "cargo-edit"
# )
#
# PACKAGES_NODE=(
#     # "typescript"
# )
#
# PACKAGES_PWSH=(
#     # "Az"
# )
#
# PACKAGES_DOTNET=(
#     # "Microsoft.PowerApps.CLI.Tool"
# )

# VS Code extensions
EXTENSIONS=(
    # "Extension Name (extension-id) - Description"
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
# VERSION CONFIGURATION (Optional - for scripts with --version flag)
#------------------------------------------------------------------------------
# If your script supports installing specific versions via --version flag,
# define these standard variables:
#
# DEFAULT_VERSION="X.Y.Z"  # Default version if --version not specified
# TARGET_VERSION=""        # Actual version to install (set by arg parser)
#
# Benefits of using these standard names:
# - Help system auto-detects DEFAULT_VERSION and displays it
# - Consistent across all language scripts (Go, Java, Python, etc.)
# - Shows as "Default: Version X.Y.Z" in --help output
#
# Example:
#   DEFAULT_VERSION="1.21.0"
#   TARGET_VERSION=""
#
# In argument parser:
#   --version)
#       TARGET_VERSION="$2"
#       ;;
#
# In pre_installation_setup():
#   if [ -z "$TARGET_VERSION" ]; then
#       TARGET_VERSION="$DEFAULT_VERSION"
#   fi
#------------------------------------------------------------------------------

# --- Pre-installation/Uninstallation Setup ---
pre_installation_setup() {
    if [ "${UNINSTALL_MODE}" -eq 1 ]; then
        echo "🔧 Preparing for uninstallation..."
    else
        echo "🔧 Performing pre-installation setup..."

        # Add SCRIPT-SPECIFIC setup here (repositories, GPG keys, etc.)
        # DO NOT add common setup like:
        #   - ensure_secrets_folder_gitignored() (handled automatically)
        #   - ensure_secrets_folder_structure() (handled automatically)
        #   - mkdir -p /workspace/.devcontainer.secrets (handled automatically)

        # Example script-specific setup:
        # curl -fsSL https://example.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/example-archive-keyring.gpg
    fi
}

#------------------------------------------------------------------------------
# UTILITY FUNCTIONS (OPTIONAL)
#------------------------------------------------------------------------------
# Version checking functions - Use ONLY when needed.
#
# WHEN TO USE VERSION FUNCTIONS:
# - Custom installation logic (downloading binaries, manual setup, NOT using PACKAGES_*)
# - Script supports --version flag for version-aware installation
# - Need to compare versions, check prerequisites, make installation decisions
#
# WHEN NOT TO USE VERSION FUNCTIONS:
# - Using PACKAGES_SYSTEM, PACKAGES_NODE, etc. (library functions handle versions internally)
# - Simple installation where version checking isn't needed for logic
# - Library functions already display appropriate messages
#
# EXAMPLES WHERE VERSION FUNCTIONS ARE NEEDED:
# - install-dev-golang.sh: Custom download from golang.org, supports --version flag
# - install-srv-otel-monitoring.sh: Downloads .deb/.tar.gz from GitHub, checks versions
#
# EXAMPLES WHERE VERSION FUNCTIONS ARE NOT NEEDED:
# - install-srv-nginx.sh: Uses PACKAGES_SYSTEM (library handles it)
# - install-tool-azure.sh: Uses PACKAGES_SYSTEM + PACKAGES_NODE (library handles it)
#
# If you DO need version functions, use this pattern:
#
# NAMING CONVENTION:
# - Single tool: get_installed_version()
# - Multiple tools: get_installed_TOOLNAME_version() for each tool
#
# EXAMPLES BY TOOL TYPE:
#
# Simple version extraction (most tools):
# get_installed_version() {
#     if command -v [tool-command] >/dev/null 2>&1; then
#         [tool-command] --version 2>/dev/null | head -1
#     else
#         echo ""
#     fi
# }
#
# Version with grep/awk parsing (Go, Rust, etc.):
# get_installed_version() {
#     if command -v go >/dev/null 2>&1; then
#         go version 2>/dev/null | grep -oP 'go\K[0-9.]+'
#     else
#         echo ""
#     fi
# }
#
# JSON output extraction (Azure CLI, etc.):
# get_installed_version() {
#     if command -v az >/dev/null 2>&1; then
#         az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4
#     else
#         echo ""
#     fi
# }
#
# Multi-tool scripts - use separate functions per tool:
# get_installed_tool1_version() {
#     if command -v tool1 >/dev/null 2>&1; then
#         tool1 --version 2>/dev/null | head -1
#     else
#         echo ""
#     fi
# }
#
# get_installed_tool2_version() {
#     if command -v tool2 >/dev/null 2>&1; then
#         tool2 --version 2>/dev/null | head -1
#     else
#         echo ""
#     fi
# }

# ============================================================================
# DEPRECATED: VERIFY_COMMANDS - DO NOT USE IN NEW SCRIPTS
# ============================================================================
# VERIFY_COMMANDS has been deprecated in favor of CHECK_INSTALLED_COMMAND
# as the single source of truth for installation verification.
#
# DECISION: We are in the process of removing VERIFY_COMMANDS from all scripts.
# - CHECK_INSTALLED_COMMAND is used by the menu system (dev-setup.sh)
# - VERIFY_COMMANDS was optional post-installation verification
# - Maintaining both creates duplication and confusion
# - Refactored scripts (golang, java) do not use VERIFY_COMMANDS
#
# If you need detailed verification, include it in post_installation_message()
# instead of using a separate VERIFY_COMMANDS array.
#
# DO NOT DEFINE VERIFY_COMMANDS IN NEW SCRIPTS
# DO NOT CALL verify_installations() IN NEW SCRIPTS
# ============================================================================

# --- Post-installation/Uninstallation Messages ---
post_installation_message() {
    # If you defined version functions above, use them here:
    # local tool_version
    # tool_version=$(get_installed_version)
    # if [ -z "$tool_version" ]; then
    #     tool_version="not found"
    # fi
    #
    # If using PACKAGES_* arrays (no version functions), keep it simple:
    echo
    echo "🎉 Installation complete!"
    echo
    echo "Quick start: [quick start command]"
    echo "Docs: [documentation URL]"
    echo
}

post_uninstallation_message() {
    # If you defined version functions above, use them to verify removal:
    # local tool_version
    # tool_version=$(get_installed_version)
    #
    # echo
    # echo "🏁 Uninstallation complete!"
    # if [ -n "$tool_version" ]; then
    #     echo "   ⚠️  [Tool] $tool_version still found in PATH"
    # else
    #     echo "   ✅ [Tool] removed"
    # fi
    # echo
    #
    # If using PACKAGES_* arrays (no version functions), keep it simple:
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
source "${SCRIPT_DIR}/lib/core-install-pwsh.sh"
source "${SCRIPT_DIR}/lib/core-install-dotnet.sh"
source "${SCRIPT_DIR}/lib/core-install-python.sh"

# Note: lib/install-common.sh already sourced earlier (needed for --help)

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Function to process installations
#
# For most scripts: Use the standard library function (shown below)
# For custom installations: Add custom logic before calling library function
#
# PATTERN 1: Pure simple (most common) - Just use library
process_installations() {
    # Use standard processing from lib/install-common.sh
    process_standard_installations
}

# PATTERN 2: Custom prefix - Custom logic first, then library
# Uncomment and modify if you need custom installation logic:
# process_installations() {
#     # Custom installation first
#     install_custom_tool
#
#     # Then use standard processing from lib/install-common.sh
#     process_standard_installations
# }

# PATTERN 3: Completely custom (rare) - Skip library if needed
# Only use this for very unique installation requirements
# process_installations() {
#     # Your completely custom installation logic
#     install_custom_tool_completely_different_way
#
#     # Note: If you skip process_standard_installations, you must
#     # manually call process_*_packages for each package type you use
# }

# Function to verify installations
# Note: Using common implementation from lib/install-common.sh (sourced above)
# No local definition needed - library function is used directly

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------

if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    echo "🔄 Starting uninstallation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    pre_installation_setup
    process_installations
    post_uninstallation_message

    # Remove from auto-enable config
    auto_disable_tool
else
    echo "🔄 Starting installation process for: $SCRIPT_NAME"
    echo "Purpose: $SCRIPT_DESCRIPTION"
    pre_installation_setup
    process_installations
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool
fi

echo "✅ Script execution finished."
exit 0