#!/bin/bash
# dev-help.sh - Show available dev-* commands

# Get version and repo from .version file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
VERSION_FILE="$SCRIPT_DIR/../.version"
VERSION="unknown"
REPO=""
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(grep "^VERSION=" "$VERSION_FILE" 2>/dev/null | cut -d= -f2)
    REPO=$(grep "^REPO=" "$VERSION_FILE" 2>/dev/null | cut -d= -f2)
fi

echo "DevContainer Toolbox v$VERSION"

# Check for updates (quick, non-blocking)
if [ -n "$REPO" ]; then
    REMOTE_VERSION=$(curl -fsSL --connect-timeout 2 "https://raw.githubusercontent.com/$REPO/main/version.txt" 2>/dev/null || echo "")
    if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "$VERSION" ]; then
        echo "  ⬆️  Update available: v$REMOTE_VERSION (run 'dev-update')"
    fi
fi

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
