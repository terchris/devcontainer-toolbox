#!/bin/bash
# dev-update.sh - Update devcontainer-toolbox from inside the container
# Usage: dev-update [--check] [--force]

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

REPO="helpers-no/devcontainer-toolbox"
IMAGE="ghcr.io/$REPO:latest"
WORKSPACE="${DCT_WORKSPACE:-/workspace}"
DEVCONTAINER_JSON="$WORKSPACE/.devcontainer/devcontainer.json"

# Parse arguments
FORCE=false
CHECK_ONLY=false
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE=true ;;
        --check|-c) CHECK_ONLY=true ;;
        --help|-h)
            echo "Usage: dev-update [OPTIONS]"
            echo ""
            echo "Update devcontainer-toolbox to the latest version."
            echo "Pulls the new image and triggers a VS Code rebuild prompt."
            echo ""
            echo "Options:"
            echo "  -c, --check    Check for updates without pulling"
            echo "  -f, --force    Force pull even if already on latest version"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
    esac
done

echo ""
echo "🔍 Checking for updates..."
echo ""

# ─── Read current version from image ─────────────────────────────────────────

CURRENT_VERSION=""
if [ -n "$DCT_HOME" ] && [ -f "$DCT_HOME/version.txt" ]; then
    CURRENT_VERSION=$(cat "$DCT_HOME/version.txt" 2>/dev/null | tr -d '[:space:]')
fi

if [ -n "$CURRENT_VERSION" ]; then
    echo "   Current version: $CURRENT_VERSION"
else
    echo "   Current version: unknown"
fi

# ─── Fetch remote version ────────────────────────────────────────────────────

REMOTE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/main/version.txt" 2>/dev/null | tr -d '[:space:]' || echo "")

if [ -z "$REMOTE_VERSION" ]; then
    echo "   ❌ Could not fetch remote version. Check your network connection."
    exit 1
fi

echo "   Latest version:  $REMOTE_VERSION"
echo ""

# ─── Compare versions ────────────────────────────────────────────────────────

if [ "$FORCE" = false ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "   ✅ Already up to date (version $CURRENT_VERSION)"
    exit 0
fi

if [ "$FORCE" = true ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "   Forcing update (same version: $CURRENT_VERSION)..."
else
    echo "   Update available: $CURRENT_VERSION → $REMOTE_VERSION"
fi

# ─── Check-only mode ─────────────────────────────────────────────────────────

if [ "$CHECK_ONLY" = true ]; then
    echo ""
    echo "   Run 'dev-update' to install the update."
    exit 0
fi

# ─── Pull new image ──────────────────────────────────────────────────────────

if ! command -v docker &>/dev/null; then
    # No Docker CLI — fall back to manual instructions
    echo ""
    echo "   Docker CLI not available inside this container."
    echo "   To update manually, run in your host terminal:"
    echo ""
    echo "     docker pull $IMAGE"
    echo ""
    echo "   Then rebuild: VS Code → Cmd/Ctrl+Shift+P → 'Dev Containers: Rebuild Container'"
    exit 0
fi

# Check if image is pinned to a specific version tag
CURRENT_IMAGE=""
if [ -f "$DEVCONTAINER_JSON" ]; then
    CURRENT_IMAGE=$(grep -o '"image"[[:space:]]*:[[:space:]]*"[^"]*"' "$DEVCONTAINER_JSON" | grep -o '"[^"]*"$' | tr -d '"')
fi

if [ -n "$CURRENT_IMAGE" ] && ! echo "$CURRENT_IMAGE" | grep -q ":latest$"; then
    echo ""
    echo "   ⚠️  Your devcontainer.json uses a pinned image tag: $CURRENT_IMAGE"
    echo "   To update, change the image tag in .devcontainer/devcontainer.json"
    echo "   to ':latest' or ':$REMOTE_VERSION', then rebuild the container."
    exit 0
fi

echo ""
echo "📦 Downloading update (~750MB)..."
echo ""

if ! docker pull "$IMAGE"; then
    echo ""
    echo "   ❌ Failed to pull image. Check your network connection."
    exit 1
fi

# ─── Trigger VS Code rebuild prompt ──────────────────────────────────────────

echo ""
if [ -f "$DEVCONTAINER_JSON" ] && grep -q "DCT_IMAGE_VERSION" "$DEVCONTAINER_JSON"; then
    sed -i "s/\"DCT_IMAGE_VERSION\": \"[^\"]*\"/\"DCT_IMAGE_VERSION\": \"${REMOTE_VERSION}\"/" "$DEVCONTAINER_JSON"
    echo "✅ DCT v${REMOTE_VERSION} downloaded."
    echo "   VS Code will prompt you to rebuild — click \"Rebuild\" to apply."
    echo "   Your files in /workspace are safe."
else
    echo "✅ DCT v${REMOTE_VERSION} downloaded."
    echo "   To apply: VS Code → Cmd/Ctrl+Shift+P → 'Dev Containers: Rebuild Container'"
    echo "   Your files in /workspace are safe."
fi
echo ""
