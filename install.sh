#!/bin/bash
# install.sh - First-time install of devcontainer-toolbox
# Run with: curl -fsSL https://raw.githubusercontent.com/REPO/main/install.sh | bash
set -e

REPO="terchris/devcontainer-toolbox"
URL="https://github.com/$REPO/releases/download/latest/dev_containers.zip"
TEMP_DIR=$(mktemp -d)

echo "Installing devcontainer-toolbox from $REPO..."

# Download
curl -fsSL "$URL" -o "$TEMP_DIR/dev_containers.zip"

# Extract
unzip -q "$TEMP_DIR/dev_containers.zip" -d "$TEMP_DIR/extract"

# Check for existing .devcontainer
if [ -d ".devcontainer" ]; then
    if [ -f ".devcontainer/.version" ]; then
        echo "Found existing devcontainer-toolbox installation."
        echo "Use 'dev-update' inside the container to update instead."
        rm -rf "$TEMP_DIR"
        exit 1
    else
        echo "Found existing .devcontainer without version info."
        echo "This may be from an older installation or a different setup."
        echo "Creating backup at .devcontainer.backup..."
        rm -rf .devcontainer.backup
        mv .devcontainer .devcontainer.backup
        echo "Backup created."
    fi
fi

# Copy .devcontainer
cp -r "$TEMP_DIR/extract/.devcontainer" .

# Handle .devcontainer.extend
if [ -d ".devcontainer.extend" ]; then
    echo "Found existing .devcontainer.extend."
    echo "Creating backup at .devcontainer.extend.backup..."
    rm -rf .devcontainer.extend.backup
    mv .devcontainer.extend .devcontainer.extend.backup
    echo "Backup created."
fi

# Copy fresh .devcontainer.extend
cp -r "$TEMP_DIR/extract/.devcontainer.extend" .

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "Installed devcontainer-toolbox!"
echo ""
echo "Next steps:"
echo "  1. Open this folder in VS Code"
echo "  2. When prompted, click 'Reopen in Container'"
echo "  3. Inside the container, run: dev-help (to see available commands)"
echo "  4. Run: dev-update (to check for updates)"

if [ -d ".devcontainer.extend.backup" ]; then
    echo ""
    echo "Note: Your previous .devcontainer.extend was backed up."
    echo "Review .devcontainer.extend.backup and reconfigure as needed."
fi
