#!/bin/bash
# dev-update.sh - Update devcontainer-toolbox from inside the container
# Usage: dev-update [--force]

set -e

REPO="TOOLBOX_REPO_PLACEHOLDER"

# Self-copy pattern: copy to temp and exec from there for safe self-update
if [ -z "$DEV_UPDATE_RUNNING_FROM_TEMP" ]; then
    TEMP_SCRIPT=$(mktemp)
    cp "$0" "$TEMP_SCRIPT"
    chmod +x "$TEMP_SCRIPT"
    DEV_UPDATE_RUNNING_FROM_TEMP=1 exec "$TEMP_SCRIPT" "$@"
fi

# Parse arguments
FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE=true
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: dev-update [OPTIONS]"
    echo ""
    echo "Update devcontainer-toolbox to the latest version."
    echo ""
    echo "Options:"
    echo "  -f, --force    Force update even if already on latest version"
    echo "  -h, --help     Show this help message"
    exit 0
fi

# Find workspace root (where .devcontainer is)
# The script is at .devcontainer/manage/dev-update.sh, so go up two levels
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$WORKSPACE_ROOT"

echo "Checking for updates from $REPO..."

# Read current installed version
CURRENT_VERSION=""
if [ -f ".devcontainer/.version" ]; then
    CURRENT_VERSION=$(grep "^VERSION=" .devcontainer/.version 2>/dev/null | cut -d= -f2)
fi

# Fetch remote version
REMOTE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/main/version.txt" 2>/dev/null || echo "")

if [ -z "$REMOTE_VERSION" ]; then
    echo "Error: Could not fetch remote version from $REPO"
    exit 1
fi

# Compare versions
if [ "$FORCE" = false ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Already up to date (version $CURRENT_VERSION)"
    exit 0
fi

if [ -n "$CURRENT_VERSION" ]; then
    echo "Updating from $CURRENT_VERSION to $REMOTE_VERSION..."
else
    echo "Installing version $REMOTE_VERSION..."
fi

# Download and extract
TEMP_DIR=$(mktemp -d)
URL="https://github.com/$REPO/releases/download/latest/dev_containers.zip"

echo "Downloading from $URL..."
curl -fsSL "$URL" -o "$TEMP_DIR/dev_containers.zip"

echo "Extracting..."
unzip -q "$TEMP_DIR/dev_containers.zip" -d "$TEMP_DIR/extract"

# Check if devcontainer.json changed
REBUILD_NEEDED=false
if [ -f ".devcontainer/devcontainer.json" ] && [ -f "$TEMP_DIR/extract/.devcontainer/devcontainer.json" ]; then
    if ! diff -q "$TEMP_DIR/extract/.devcontainer/devcontainer.json" ".devcontainer/devcontainer.json" > /dev/null 2>&1; then
        REBUILD_NEEDED=true
    fi
fi

# Handle existing .devcontainer.extend
EXTEND_BACKED_UP=false
if [ -d ".devcontainer.extend" ]; then
    echo "Backing up .devcontainer.extend..."
    rm -rf .devcontainer.extend.backup
    mv .devcontainer.extend .devcontainer.extend.backup
    EXTEND_BACKED_UP=true
fi

# Replace .devcontainer
echo "Updating .devcontainer..."
rm -rf .devcontainer
cp -r "$TEMP_DIR/extract/.devcontainer" .

# Install fresh .devcontainer.extend
cp -r "$TEMP_DIR/extract/.devcontainer.extend" .

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "Updated to version $REMOTE_VERSION"

if [ "$EXTEND_BACKED_UP" = true ]; then
    echo ""
    echo "Your previous .devcontainer.extend was backed up."
    echo "Review .devcontainer.extend.backup and reconfigure:"
    echo "  - Edit .devcontainer.extend/enabled-tools.conf"
    echo "  - Run: dev-setup"
fi

if [ "$REBUILD_NEEDED" = true ]; then
    echo ""
    echo "devcontainer.json has changed."
    echo "Rebuild the container for changes to take effect:"
    echo "  VS Code: Cmd/Ctrl+Shift+P > 'Dev Containers: Rebuild Container'"
fi

echo ""
echo "Done!"
