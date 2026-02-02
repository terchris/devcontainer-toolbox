#!/bin/bash
# install.sh - First-time install of devcontainer-toolbox (image mode)
# Run with: curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
set -e

REPO="terchris/devcontainer-toolbox"
IMAGE="ghcr.io/$REPO:latest"

echo "Installing devcontainer-toolbox from $REPO..."
echo ""

# ─── 1. Check Docker is available ────────────────────────────────────────────

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    echo ""
    echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    echo "Then run this script again."
    exit 1
fi

# ─── 2. Backup existing .devcontainer/ ───────────────────────────────────────

if [ -d ".devcontainer" ]; then
    echo "Found existing .devcontainer/ directory."
    echo "Creating backup at .devcontainer.backup/..."
    rm -rf .devcontainer.backup
    mv .devcontainer .devcontainer.backup
    echo "Backup created."
    echo ""
fi

# ─── 3. Create .devcontainer/devcontainer.json ───────────────────────────────

mkdir -p .devcontainer

cat > .devcontainer/devcontainer.json << 'DEVCONTAINER_EOF'
{
    // DevContainer Toolbox — pre-built image mode
    // Docs: https://github.com/terchris/devcontainer-toolbox
    //
    // overrideCommand: false is REQUIRED so VS Code doesn't bypass the ENTRYPOINT.
    // The entrypoint handles all startup — no lifecycle hooks needed.
    "name": "DevContainer Toolbox",
    "image": "ghcr.io/terchris/devcontainer-toolbox:latest",
    "overrideCommand": false,

    // VPN capabilities
    "runArgs": [
        "--cap-add=NET_ADMIN",
        "--cap-add=NET_RAW",
        "--cap-add=SYS_ADMIN",
        "--cap-add=AUDIT_WRITE",
        "--device=/dev/net/tun:/dev/net/tun",
        "--privileged"
    ],

    "customizations": {
        "vscode": {
            "extensions": [
                "yzhang.markdown-all-in-one",
                "MermaidChart.vscode-mermaid-chart",
                "redhat.vscode-yaml",
                "mhutchie.git-graph",
                "timonwong.shellcheck"
            ]
        }
    },

    "remoteEnv": {
        "DOCKER_HOST": "unix:///var/run/docker.sock",
        "DCT_HOME": "/opt/devcontainer-toolbox",
        "DCT_WORKSPACE": "/workspace"
    },

    "mounts": [
        "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind,consistency=cached"
    ],

    "workspaceFolder": "/workspace",
    "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",

    // Capture host git identity before container starts
    "initializeCommand": "mkdir -p .devcontainer.secrets/env-vars && (git config --global user.name > .devcontainer.secrets/env-vars/.git-host-name 2>/dev/null || true) && (git config --global user.email > .devcontainer.secrets/env-vars/.git-host-email 2>/dev/null || true)",

    "remoteUser": "vscode",
    "containerUser": "vscode",
    "shutdownAction": "stopContainer",
    "updateRemoteUserUID": true,
    "init": true
}
DEVCONTAINER_EOF

echo "Created .devcontainer/devcontainer.json"

# ─── 4. Pull the Docker image ────────────────────────────────────────────────

echo ""
echo "Pulling container image: $IMAGE"
echo "(This may take a few minutes on first install...)"
docker pull "$IMAGE"

# ─── 5. Print next steps ─────────────────────────────────────────────────────

echo ""
echo "✅ devcontainer-toolbox installed!"
echo ""
echo "Next steps:"
echo "  1. Open this folder in VS Code"
echo "  2. When prompted, click 'Reopen in Container'"
echo "     (or run: Cmd/Ctrl+Shift+P > 'Dev Containers: Reopen in Container')"
echo "  3. Inside the container, run: dev-help"
echo ""

if [ -d ".devcontainer.backup" ]; then
    echo "Note: Your previous .devcontainer/ was backed up to .devcontainer.backup/"
    echo ""
fi
