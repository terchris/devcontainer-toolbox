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
    echo "Pulls the latest container image and instructs you to rebuild."
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

# ─── Pull the latest image ───────────────────────────────────────────────────

# Check if Docker is available inside the container (requires socket mount)
if sudo docker info &>/dev/null; then
    echo ""
    echo "Pulling image: $IMAGE"
    sudo docker pull "$IMAGE"

    echo ""
    echo "✅ Image updated!"
    echo ""
    echo "🔄 Rebuild the container to apply the update:"
    echo "   VS Code: Cmd/Ctrl+Shift+P > 'Dev Containers: Rebuild Container'"
    echo ""
else
    # Docker socket not mounted (typical on Windows where /var/run/docker.sock
    # doesn't exist on the host). Give the user a command to run on the host.
    echo ""
    echo "Docker is not available inside this container."
    echo "To update, run this in your host terminal (PowerShell or CMD):"
    echo ""
    echo "  docker pull $IMAGE"
    echo ""
    echo "Then rebuild the container:"
    echo "  VS Code: Cmd/Ctrl+Shift+P > 'Dev Containers: Rebuild Container'"
    echo ""
fi
