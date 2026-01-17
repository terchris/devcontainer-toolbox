---
sidebar_position: 2
---

# Getting Started

A ready-to-use development environment that works the same on Windows, Mac, and Linux.

## Prerequisites

### All Platforms

1. **Docker** - Install [Rancher Desktop](https://rancherdesktop.io/) (free and open source)
   - *Why not Docker Desktop?* Docker Desktop requires a [paid subscription](https://www.docker.com/pricing/) for companies. Rancher Desktop is 100% free.

2. **VS Code** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Windows Users

Before installing Rancher Desktop, you need WSL (Windows Subsystem for Linux):

```powershell
# Run in PowerShell as Administrator
wsl --install
```

Restart your computer after the command completes, then install Rancher Desktop.

**Note:** This works on Windows 10 (build 19041+) and Windows 11.

### Mac/Linux Users

Just install Rancher Desktop - no additional setup needed.

## Installation (3 Steps)

### Step 1: Install in Your Project

Open a terminal in your project directory and run:

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

If you see "running scripts is disabled on this system":
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex"
```

### Step 2: Open in VS Code

```bash
code .
```

### Step 3: Reopen in Container

When VS Code prompts "Reopen in Container", click it. First time takes a few minutes.

That's it! You're ready to start developing.

## What's Next?

- **[Install Tools](commands)** - Add development tools (Python, TypeScript, Go, etc.)
- **[Customization](configuration)** - Configure your project settings
- **[Troubleshooting](troubleshooting)** - Common issues and solutions

Run `dev-help` in the terminal to see all available commands.
