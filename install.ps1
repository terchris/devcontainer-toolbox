# install.ps1 - First-time install of devcontainer-toolbox (image mode)
# Run with: irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
# If blocked: powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex"

$ErrorActionPreference = "Stop"

$repo = "terchris/devcontainer-toolbox"
$image = "ghcr.io/${repo}:latest"

Write-Host "Installing devcontainer-toolbox from $repo..."
Write-Host ""

# --- 1. Check Docker is available ------------------------------------------------

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed or not in PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Rancher Desktop from: https://rancherdesktop.io/"
    Write-Host "Then run this script again."
    exit 1
}

# --- 2. Backup existing .devcontainer/ -------------------------------------------

if (Test-Path ".devcontainer") {
    Write-Host "Found existing .devcontainer/ directory."
    Write-Host "Creating backup at .devcontainer.backup/..."
    if (Test-Path ".devcontainer.backup") {
        Remove-Item ".devcontainer.backup" -Recurse -Force
    }
    Rename-Item ".devcontainer" ".devcontainer.backup"
    Write-Host "Backup created."
    Write-Host ""
}

# --- 3. Create .devcontainer/devcontainer.json ------------------------------------

New-Item -ItemType Directory -Path ".devcontainer" -Force | Out-Null

$devcontainerJson = @'
{
    // DevContainer Toolbox — pre-built image mode
    // Docs: https://github.com/terchris/devcontainer-toolbox
    //
    // overrideCommand: false is REQUIRED so VS Code doesn't bypass the ENTRYPOINT.
    // The entrypoint handles all startup — no lifecycle hooks needed.
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

    // Capture host git identity before container starts.
    // Uses cmd.exe syntax since VS Code on Windows runs initializeCommand via cmd.exe.
    // If git is not installed, the commands silently fail — entrypoint has fallbacks.
    "initializeCommand": "mkdir .devcontainer.secrets\\env-vars 2>nul & git config --global user.name > .devcontainer.secrets\\env-vars\\.git-host-name 2>nul & git config --global user.email > .devcontainer.secrets\\env-vars\\.git-host-email 2>nul & ver >nul",

    "remoteUser": "vscode",
    "containerUser": "vscode",
    "shutdownAction": "stopContainer",
    "updateRemoteUserUID": true,
    "init": true
}
'@

$devcontainerJson | Out-File -FilePath ".devcontainer/devcontainer.json" -Encoding utf8

Write-Host "Created .devcontainer/devcontainer.json"

# --- 4. Pull the Docker image -----------------------------------------------------

Write-Host ""
Write-Host "Pulling container image: $image"
Write-Host "(This may take a few minutes on first install...)"
docker pull $image

# --- 5. Print next steps ----------------------------------------------------------

Write-Host ""
Write-Host "devcontainer-toolbox installed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open this folder in VS Code"
Write-Host "  2. When prompted, click 'Reopen in Container'"
Write-Host "     (or run: Cmd/Ctrl+Shift+P > 'Dev Containers: Reopen in Container')"
Write-Host "  3. Inside the container, run: dev-help"
Write-Host ""

if (Test-Path ".devcontainer.backup") {
    Write-Host "Note: Your previous .devcontainer/ was backed up to .devcontainer.backup/"
    Write-Host ""
}
