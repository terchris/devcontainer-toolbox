---
title: Libraries Reference
sidebar_position: 3
---

# Library Functions Reference

Shared libraries in `.devcontainer/additions/lib/` provide reusable functionality for install, service, and config scripts.

---

## Overview

| Library | Purpose |
|---------|---------|
| `logging.sh` | Automatic logging to file with timestamps |
| `component-scanner.sh` | Script discovery and metadata extraction |
| `categories.sh` | Category definitions and helpers |
| `tool-auto-enable.sh` | Auto-enable tools for container rebuild |
| `service-auto-enable.sh` | Auto-enable services for container restart |
| `prerequisite-check.sh` | Validate configuration dependencies |
| `install-common.sh` | Shared install/uninstall patterns |
| `core-install-*.sh` | Package installers (npm, pip, cargo, etc.) |

---

## logging.sh

Automatically redirects all script output to a timestamped log file.

### Usage

```bash
source "${SCRIPT_DIR}/lib/logging.sh"
```

### What it does

- Creates log directory: `/tmp/devcontainer-install/`
- Creates timestamped log file: `install-dev-python-20260115-143022.log`
- Redirects stdout and stderr to both terminal and log file
- Provides logging functions for structured output

### Functions

| Function | Description |
|----------|-------------|
| `log_info "message"` | Info message with timestamp |
| `log_success "message"` | Success message with checkmark |
| `log_error "message"` | Error message with X |
| `log_warning "message"` | Warning message |

### Example

```bash
source "${SCRIPT_DIR}/lib/logging.sh"

log_info "Starting installation..."
apt-get install -y python3
log_success "Python installed"
```

---

## component-scanner.sh

Discovers scripts and extracts metadata for the dev-setup menu.

### Usage

```bash
source "/workspace/.devcontainer/additions/lib/component-scanner.sh"
```

### Key Functions

#### scan_install_scripts

Scan all `install-*.sh` scripts and return metadata.

```bash
while IFS=$'\t' read -r basename script_id name desc cat check prereqs; do
    echo "Found: $name (ID: $script_id)"
done < <(scan_install_scripts "/workspace/.devcontainer/additions")
```

**Output format** (tab-separated):
```
script_basename  SCRIPT_ID  SCRIPT_NAME  SCRIPT_DESCRIPTION  SCRIPT_CATEGORY  SCRIPT_CHECK_COMMAND  SCRIPT_PREREQUISITES
```

#### scan_service_scripts_new

Scan all `service-*.sh` scripts.

```bash
while IFS=$'\t' read -r basename name desc cat path prereqs; do
    echo "Service: $name"
done < <(scan_service_scripts_new "/workspace/.devcontainer/additions")
```

#### scan_config_scripts

Scan all `config-*.sh` scripts.

```bash
while IFS=$'\t' read -r basename name desc cat check prereqs; do
    echo "Config: $name"
done < <(scan_config_scripts "/workspace/.devcontainer/additions")
```

#### extract_script_metadata

Extract a single metadata field from a script.

```bash
script_name=$(extract_script_metadata "/path/to/install-python.sh" "SCRIPT_NAME")
# Returns: "Python Development Tools"
```

#### check_component_installed

Check if a component is installed using its check command.

```bash
if check_component_installed "command -v python3 >/dev/null 2>&1"; then
    echo "Python is installed"
fi
```

---

## categories.sh

Central definition of script categories.

### Usage

```bash
source "${SCRIPT_DIR}/lib/categories.sh"
```

### Available Categories

| Category ID | Display Name |
|-------------|--------------|
| `LANGUAGE_DEV` | Development Tools |
| `AI_TOOLS` | AI & Machine Learning Tools |
| `CLOUD_TOOLS` | Cloud & Infrastructure Tools |
| `DATA_ANALYTICS` | Data & Analytics Tools |
| `BACKGROUND_SERVICES` | Background Services & Daemons |
| `INFRA_CONFIG` | Infrastructure & Configuration |

### Functions

| Function | Description |
|----------|-------------|
| `get_category_display_name "LANGUAGE_DEV"` | Returns "Development Tools" |
| `get_category_description "LANGUAGE_DEV"` | Returns long description |
| `is_valid_category "LANGUAGE_DEV"` | Returns 0 if valid |
| `get_all_category_ids` | Lists all category IDs |
| `show_all_categories` | Human-readable category list |

### Example

```bash
source "${SCRIPT_DIR}/lib/categories.sh"

# In your script metadata
SCRIPT_CATEGORY="LANGUAGE_DEV"

# Get display name
display=$(get_category_display_name "$SCRIPT_CATEGORY")
echo "Category: $display"  # "Development Tools"
```

---

## tool-auto-enable.sh

Manages tool auto-installation on container rebuild.

### Usage

```bash
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"
```

### How it works

- Tools are tracked in `.devcontainer.extend/enabled-tools.conf`
- When a tool installs successfully, it auto-enables itself
- On container rebuild, enabled tools reinstall automatically

### Functions

| Function | Description |
|----------|-------------|
| `auto_enable_tool` | Enable current tool (uses SCRIPT_ID) |
| `auto_disable_tool` | Disable current tool |
| `is_tool_auto_enabled "tool-id"` | Check if tool is enabled |
| `list_enabled_tools` | Show all enabled tools |

### Example (in install script)

```bash
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# After successful installation
auto_enable_tool  # Reads SCRIPT_ID from script metadata

# In uninstall
auto_disable_tool
```

---

## service-auto-enable.sh

Manages service auto-start on container restart.

### Usage

```bash
source "${SCRIPT_DIR}/lib/service-auto-enable.sh"
```

### How it works

- Services are tracked in `.devcontainer.extend/enabled-services.conf`
- When a service starts successfully, it auto-enables itself
- On container restart, enabled services start automatically via supervisord

### Functions

| Function | Description |
|----------|-------------|
| `auto_enable_service` | Enable current service (uses SCRIPT_ID) |
| `auto_disable_service` | Disable current service |
| `is_auto_enabled "service-id"` | Check if service is enabled |
| `list_enabled_services` | Show all enabled services |

---

## prerequisite-check.sh

Validates configuration dependencies before tool installation.

### Usage

```bash
source "/workspace/.devcontainer/additions/lib/prerequisite-check.sh"
```

### Functions

#### check_prerequisite_config

Check if a single config has been completed.

```bash
if check_prerequisite_config "config-devcontainer-identity.sh" "/workspace/.devcontainer/additions"; then
    echo "Identity is configured"
fi
```

#### check_prerequisite_configs

Check multiple configs (all must pass).

```bash
if check_prerequisite_configs "config-identity.sh config-git.sh" "$ADDITIONS_DIR"; then
    echo "All prerequisites met"
else
    echo "Missing prerequisites"
fi
```

#### show_missing_prerequisites

Display which prerequisites are missing.

```bash
show_missing_prerequisites "config-identity.sh config-git.sh" "$ADDITIONS_DIR"
# Output:
#   ❌ Developer Identity (run: bash .../config-devcontainer-identity.sh)
```

---

## Core Install Libraries

Package-specific installers that handle common installation patterns.

### core-install-node.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-node.sh"

# Install global npm packages
npm_install_global "typescript" "ts-node" "@types/node"
```

### core-install-python.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-python.sh"

# Install pip packages
pip_install "pandas" "numpy" "scikit-learn"
```

### core-install-cargo.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-cargo.sh"

# Install Rust crates
cargo_install "ripgrep" "fd-find"
```

### core-install-go.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-go.sh"

# Install Go packages
go_install "golang.org/x/tools/gopls@latest"
```

### core-install-dotnet.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-dotnet.sh"

# Install .NET tools
dotnet_tool_install "dotnet-ef"
```

### core-install-system.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-system.sh"

# Install system packages
apt_install "build-essential" "cmake"
```

### core-install-extensions.sh

```bash
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"

# Install VS Code extensions
install_vscode_extension "ms-python.python"
```

---

## Loading Libraries

Libraries are typically loaded at the start of a script:

```bash
#!/bin/bash
# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load required libraries
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/categories.sh"
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"

# Your script code here...
```

---

## See Also

- [Creating Install Scripts](../scripts/install-scripts)
- [System Architecture](./)
