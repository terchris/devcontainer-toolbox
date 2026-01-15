#!/bin/bash
# dev-help.sh - Show available dev-* commands

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-help"
SCRIPT_NAME="Help"
SCRIPT_DESCRIPTION="Show available commands and version info"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"

# Get script directory and source version utilities
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Handle both direct (.devcontainer/) and manage/ subfolder locations
if [ -f "$SCRIPT_DIR/lib/version-utils.sh" ]; then
    source "$SCRIPT_DIR/lib/version-utils.sh"
elif [ -f "$SCRIPT_DIR/manage/lib/version-utils.sh" ]; then
    source "$SCRIPT_DIR/manage/lib/version-utils.sh"
fi

# Show version and update status
show_version_info

echo ""
cat << 'EOF'
Available dev-* commands:

  dev-setup      Configure which tools to enable
  dev-services   Manage development services
  dev-template   Create files from templates
  dev-update     Update devcontainer-toolbox
  dev-check      Validate configuration files
  dev-env        Show environment information
  dev-clean      Clean up devcontainer resources
  dev-help       Show this help message

Run any command with --help for more details.
EOF
