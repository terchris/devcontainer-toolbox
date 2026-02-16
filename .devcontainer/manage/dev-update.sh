#!/bin/bash
# dev-update.sh - Update devcontainer-toolbox from inside the container
# Usage: dev-update [--force]

#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-update"
SCRIPT_NAME="Update"
SCRIPT_DESCRIPTION="Update devcontainer-toolbox to latest version"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"
SCRIPT_CHECK_COMMAND="true"

set -e

# Ensure .devcontainer.secrets is in .gitignore (issue #40)
if [ -n "$DCT_HOME" ] && [ -f "$DCT_HOME/additions/lib/ensure-gitignore.sh" ]; then
    source "$DCT_HOME/additions/lib/ensure-gitignore.sh"
fi

REPO="terchris/devcontainer-toolbox"
IMAGE="ghcr.io/$REPO:latest"

# Parse arguments
FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE=true
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: dev-update [OPTIONS]"
    echo ""
    echo "Update devcontainer-toolbox to the latest version."
    echo "Checks for container-level updates (Dockerfile, OS packages, runtimes)"
    echo "and shows the command to pull the latest image."
    echo ""
    echo "For script-only updates (no container rebuild needed), use 'dev-sync'."
    echo ""
    echo "Options:"
    echo "  -f, --force    Force pull even if already on latest version"
    echo "  -h, --help     Show this help message"
    exit 0
fi

echo "Checking for updates..."
echo ""

# ─── Read current version from image ─────────────────────────────────────────

CURRENT_VERSION=""
if [ -n "$DCT_HOME" ] && [ -f "$DCT_HOME/version.txt" ]; then
    CURRENT_VERSION=$(cat "$DCT_HOME/version.txt" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$CURRENT_VERSION" ]; then
    echo "Current version: $CURRENT_VERSION"
else
    echo "Current version: unknown"
fi

# ─── Fetch remote version ────────────────────────────────────────────────────

REMOTE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/main/version.txt" 2>/dev/null | tr -d '[:space:]' || echo "")

if [ -z "$REMOTE_VERSION" ]; then
    echo "Error: Could not fetch remote version from $REPO"
    exit 1
fi

echo "Latest version:  $REMOTE_VERSION"
echo ""

# ─── Compare versions ────────────────────────────────────────────────────────

if [ "$FORCE" = false ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Already up to date (version $CURRENT_VERSION)"
    exit 0
fi

if [ "$FORCE" = true ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Forcing update (same version: $CURRENT_VERSION)..."
else
    echo "Update available: $CURRENT_VERSION → $REMOTE_VERSION"
fi

# ─── Show update instructions ────────────────────────────────────────────────

echo "To update, run this in your terminal:"
echo ""
echo "  docker pull $IMAGE"
echo ""
echo "Then rebuild the container:"
echo "  VS Code: Cmd/Ctrl+Shift+P > 'Dev Containers: Rebuild Container'"
echo ""
