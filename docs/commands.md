# Commands Reference

All commands available inside the devcontainer. Type `dev-` and press Tab to see them.

## Main Commands

### dev-setup

Interactive menu for managing your development environment.

```bash
dev-setup
```

From this menu you can:
- Browse and install development tools
- Manage background services
- Configure settings
- View environment status

### dev-help

Show all available commands and version info.

```bash
dev-help
```

### dev-update

Update devcontainer-toolbox to the latest version.

```bash
dev-update           # Check and update if newer version available
dev-update --force   # Force update even if same version
```

After updating, VS Code will prompt to rebuild the container.

---

## Service Management

### dev-services

Manage background services (nginx, OTEL, etc.).

```bash
dev-services status          # Show status of all services
dev-services start <name>    # Start a service
dev-services stop <name>     # Stop a service
dev-services restart <name>  # Restart a service
dev-services logs <name>     # View service logs
```

---

## Configuration

### dev-check

Configure and verify Git identity and credentials.

```bash
dev-check            # Interactive configuration
dev-check --show     # Show current configuration
```

Settings are saved to `.devcontainer.secrets/` and restored on container rebuild.

### dev-env

Show what's installed in the current environment.

```bash
dev-env
```

---

## Templates

### dev-template

Create project files from templates.

```bash
dev-template
```

Shows a menu of available templates from the [template library](https://github.com/terchris/urbalurba-dev-templates).

---

## Maintenance

### dev-clean

Delete the devcontainer to start fresh.

```bash
dev-clean
```

After running this, reopen in VS Code to get a clean container.

---

## Running Scripts Directly

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
