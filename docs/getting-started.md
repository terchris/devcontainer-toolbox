# Getting Started

A ready-to-use development environment that works the same on Windows, Mac, and Linux.

## What is a DevContainer?

- A development environment that runs in a container
- Includes all the tools you need pre-installed
- Same setup for everyone on the team
- No need to install anything on your machine (except Docker)

**Learn More:**
- [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers) - Official VS Code documentation
- [Get Started with Dev Containers](https://www.youtube.com/watch?v=b1RavPr_878&t=38s) - 5-minute video tutorial

## Prerequisites

Install Docker, preferably via [Rancher Desktop](https://rancherdesktop.io/) instead of Docker Desktop.

- **Windows**: Install inside WSL. See [setup-windows.md](../.devcontainer/setup/setup-windows.md)
- **Mac/Linux**: See [setup-mac.md](../.devcontainer/setup/setup-mac.md)

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

## Using the DevContainer

After the container starts, you have access to helpful commands.

### Main Command: `dev-setup`

This is your **one-stop menu** for managing your development environment:

```bash
dev-setup
```

From this menu you can:
- Install additional development tools (Python, TypeScript, Go, PHP, C#, Rust, PowerShell, etc.)
- Manage background services (nginx, OTEL monitoring, etc.)
- Configure settings (Git identity, credentials)
- View environment status

### Other Useful Commands

```bash
dev-help              # Show all available commands
dev-services status   # Quick check: what services are running?
dev-check             # Setup Git identity and credentials
dev-env               # See what's installed
dev-update            # Update devcontainer-toolbox
```

See [commands.md](commands.md) for complete command reference.

## Customizing for Your Project

Want to install project-specific packages or run setup scripts?

Edit: `.devcontainer.extend/project-installs.sh`

```bash
#!/bin/bash
set -e

printf "Running custom project installations...\n"

# Install your project dependencies
cd /workspace
npm install

# Or any other setup you need
# pip install -r requirements.txt
# bash scripts/setup-database.sh

printf "Custom project installations complete\n"
```

This runs automatically when the container is created. Perfect for:
- Installing npm/pip packages
- Setting up databases
- Generating code from schemas
- Any project-specific setup

## Configuration Files

Your project customizations live in `.devcontainer.extend/`:

| File | Purpose |
|------|---------|
| `enabled-tools.conf` | Tools to auto-install on container rebuild |
| `enabled-services.conf` | Services to auto-start |
| `project-installs.sh` | Your custom setup script |

Secrets are stored in `.devcontainer.secrets/` (git-ignored).

See [configuration.md](configuration.md) for details.

## Starting Fresh

The great thing about devcontainers is you can experiment freely. To reset:

```bash
dev-clean    # Delete the devcontainer
```

Then reopen in VS Code to get a fresh container.

## Need Help?

See [troubleshooting.md](troubleshooting.md) for common issues, or run:

```bash
dev-help
```
