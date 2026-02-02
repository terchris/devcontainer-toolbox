---
sidebar_position: 4
sidebar_label: Install Tools
---

# Install Tools

:::note Auto-generated
This page is auto-generated. Regenerate with: `dev-docs`
:::

## dev-setup

Run `dev-setup` to install development tools. The interactive menu lets you browse and install any of the available tools.

![dev-setup menu](/img/dev-setup.png)

## Quick Reference

| Command | Description |
|---------|-------------|
| [`dev-check`](#dev-check) | Configure and validate Git identity and credentials |
| [`dev-clean`](#dev-clean) | Clean up devcontainer resources |
| [`dev-env`](#dev-env) | Show installed tools and environment info |
| [`dev-help`](#dev-help) | Show available commands and version info |
| [`dev-log`](#dev-log) | Display the container startup log |
| [`dev-services`](#dev-services) | Manage background services (start, stop, status, logs) |
| [`dev-template`](#dev-template) | Create project files from templates |
| [`dev-update`](#dev-update) | Update devcontainer-toolbox to latest version |
| [`dev-setup`](#dev-setup) | Interactive menu for installing tools and managing services |
| [`dev-cubes`](#dev-cubes) | Generate homepage floating cubes configuration |
| [`dev-docs`](#dev-docs) | Generate documentation (tools.md, commands.md) |
| [`dev-test`](#dev-test) | Run static, unit, and install tests |

---

## System Commands

### dev-check

Configure and validate Git identity and credentials

```bash
dev-check
dev-check --show    # Show current configuration
```

### dev-clean

Clean up devcontainer resources

```bash
dev-clean
```

### dev-env

Show installed tools and environment info

```bash
dev-env
```

### dev-help

Show available commands and version info

```bash
dev-help
```

### dev-log

Display the container startup log

```bash
dev-log
```

### dev-services

Manage background services (start, stop, status, logs)

```bash
dev-services
dev-services status          # Show status of all services
dev-services start <name>    # Start a service
dev-services stop <name>     # Stop a service
dev-services logs <name>     # View service logs
```

### dev-template

Create project files from templates

```bash
dev-template
```

### dev-update

Update devcontainer-toolbox to latest version

```bash
dev-update
dev-update --force   # Force update even if same version
```

### dev-setup

Interactive menu for installing tools and managing services

```bash
dev-setup
```

---

## Contributor Tools

### dev-cubes

Generate homepage floating cubes configuration

```bash
dev-cubes
```

### dev-docs

Generate documentation (tools.md, commands.md)

```bash
dev-docs
```

### dev-test

Run static, unit, and install tests

```bash
dev-test
```

---

## Running Install Scripts Directly

All install scripts can also be run directly:

```bash
# Show help for a script
.devcontainer/additions/install-dev-python.sh --help

# Install with specific version
.devcontainer/additions/install-dev-golang.sh --version 1.22.0

# Uninstall
.devcontainer/additions/install-dev-golang.sh --uninstall
```

Use `dev-setup` for the interactive menu, or run scripts directly for automation.
