# DevContainer Toolbox Documentation

Complete documentation for devcontainer-toolbox.

---

## User Documentation

For developers using devcontainer-toolbox in their projects.

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started.md) | Installation and first steps |
| [Commands](commands.md) | All `dev-*` commands reference |
| [Tools](tools.md) | Available development tools |
| [Tools Details](tools-details.md) | Detailed tool information |
| [Configuration](configuration.md) | Config files and secrets |
| [Troubleshooting](troubleshooting.md) | Common issues and solutions |

---

## Contributor Documentation

For developers extending or maintaining devcontainer-toolbox.

| Document | Description |
|----------|-------------|
| [Contributor Guide](contributors/README.md) | Overview for contributors |
| [Adding Tools](contributors/adding-tools.md) | How to add new tools |
| [Creating Install Scripts](contributors/creating-install-scripts.md) | Install script guide |
| [Creating Service Scripts](contributors/creating-service-scripts.md) | Service script guide |
| [Libraries](contributors/libraries.md) | Shared library functions |
| [Architecture](contributors/architecture.md) | System architecture |
| [Menu System](contributors/menu-system.md) | Dialog tool and menus |
| [Categories](contributors/categories.md) | Tool category definitions |
| [Testing](contributors/testing.md) | Running tests |
| [Testing Maintenance](contributors/testing-maintenance.md) | Maintaining test framework |
| [CI/CD](contributors/CI-CD.md) | GitHub Actions and CI |
| [Releasing](contributors/RELEASING.md) | Release process |

### Services Documentation

| Document | Description |
|----------|-------------|
| [Services Overview](contributors/services.md) | Background services index |
| [Nginx](contributors/services-nginx.md) | Nginx reverse proxy |
| [OpenTelemetry](contributors/services-otel.md) | OTEL monitoring |
| [Service Dependencies](contributors/services-dependencies.md) | Service dependency system |
| [Monitoring Requirements](contributors/services-monitoring-requirements.md) | Monitoring requirements |

---

## AI Developer Documentation

For AI assistants (Claude Code) working on devcontainer-toolbox.

| Document | Description |
|----------|-------------|
| [AI Developer Guide](ai-developer/README.md) | Overview for AI assistants |
| [Workflow](ai-developer/WORKFLOW.md) | Plan to implementation flow |
| [Plans](ai-developer/PLANS.md) | Plan structure and templates |
| [Creating Scripts](ai-developer/CREATING-SCRIPTS.md) | AI guide for creating scripts |

---

## Quick Start

**Install:**
```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash

# Windows PowerShell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

**Use:**
```bash
dev-setup     # Interactive menu for tools and services
dev-help      # Show all commands
dev-update    # Update to latest version
```
