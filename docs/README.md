# DevContainer Toolbox Documentation

Documentation for developers using devcontainer-toolbox in their projects.

## Quick Links

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started.md) | Installation and first steps |
| [Commands](commands.md) | All `dev-*` commands reference |
| [Tools](tools.md) | Available development tools |
| [Configuration](configuration.md) | Config files and secrets |
| [Troubleshooting](troubleshooting.md) | Common issues and solutions |

## Installation

**Mac/Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

Then open the folder in VS Code and click "Reopen in Container" when prompted.

## Updating

From inside the devcontainer:
```bash
dev-update
```

## Getting Help

Inside the devcontainer:
```bash
dev-help          # Show all commands
dev-setup         # Interactive menu for tools and services
```

## For Contributors

See [contributors/](contributors/) for documentation on maintaining and extending devcontainer-toolbox.
