# DevContainer Additions System - Architecture Documentation

This document describes the architecture and design patterns of the DevContainer Additions System - a metadata-driven, self-discovering script management system for devcontainer configuration.

## Table of Contents

- [Overview](#overview)
- [Script Types](#script-types)
- [Metadata System](#metadata-system)
- [Library System](#library-system)
- [Key Patterns](#key-patterns)
- [Directory Structure](#directory-structure)
- [Data Flow](#data-flow)
- [Extending the System](#extending-the-system)

---

## Overview

The Additions System provides:

1. **Automatic Script Discovery** - Scripts are found by filename pattern and parsed for metadata
2. **Interactive Menu Interface** - Dialog-based TUI for easy navigation
3. **Status Indicators** - Visual feedback showing installed/configured/running state
4. **Category Organization** - Scripts grouped logically for easy navigation
5. **Auto-Enable/Disable** - Track what's installed for container rebuild persistence
6. **Prerequisite Checking** - Validate dependencies before execution

### Design Philosophy

- **Convention over configuration** - Filename prefixes determine script type
- **Self-documenting** - Metadata in scripts serves as both documentation and discovery mechanism
- **Declarative actions** - `SCRIPT_COMMANDS` array defines available operations
- **Separation of concerns** - Core logic in libraries, scripts are thin wrappers

---

## Script Types

### Naming Conventions

| Prefix | Type | Purpose |
|--------|------|---------|
| `install-*.sh` | Install | Install tools, languages, packages |
| `config-*.sh` | Config | Configure settings, credentials |
| `service-*.sh` | Service | Manage background services (unified start/stop) |
| `cmd-*.sh` | Command | Utility commands and tools |

### Script Type Details

#### Install Scripts (`install-*.sh`)

Install development tools, languages, and packages.

**Lifecycle:**
```
install-dev-golang.sh
    ├── --help      → Show usage
    ├── (default)   → Install with defaults
    ├── --version   → Install specific version
    └── --uninstall → Remove installation
```

**Key Features:**
- Idempotent (safe to run multiple times)
- Auto-enable on success (adds to `enabled-tools.conf`)
- Version support for most language tools
- Uninstall support

#### Config Scripts (`config-*.sh`)

Configure settings, credentials, and environment.

**Lifecycle:**
```
config-git.sh
    ├── --help    → Show usage
    ├── (default) → Interactive configuration
    ├── --show    → Display current config
    └── --verify  → Silent restore from .devcontainer.secrets
```

**Key Features:**
- Interactive prompts for user input
- Persist to `.devcontainer.secrets/` for rebuild survival
- `--verify` flag for non-interactive restoration
- Reconfiguration support

#### Service Scripts (`service-*.sh`)

Unified service management (replaces old start-*/stop-* pattern).

**Lifecycle:**
```
service-nginx.sh
    ├── --start       → Start service (foreground for supervisord)
    ├── --stop        → Stop service gracefully
    ├── --restart     → Restart service
    ├── --status      → Show status with details
    ├── --is-running  → Silent check (exit code only)
    ├── --logs        → Show recent logs
    ├── --logs-follow → Tail logs
    ├── --validate    → Validate configuration
    ├── --reload      → Reload config without restart
    └── --health      → Health check
```

**Key Features:**
- All operations in one script
- Supervisord integration (`exec` for foreground)
- Auto-enable/disable for container restart
- Prerequisite tool checking

#### Command Scripts (`cmd-*.sh`)

Utility commands and tools.

**Lifecycle:**
```
cmd-ai.sh
    ├── --list-models → List available AI models
    ├── --check-key   → Verify API key
    └── --usage       → Show API usage
```

---

## Metadata System

### Required Metadata Fields

Every discoverable script must define these fields near the top:

```bash
#------------------------------------------------------------------------------
# SCRIPT METADATA - For dev-setup.sh menu discovery
#------------------------------------------------------------------------------

SCRIPT_ID="dev-golang"                    # Unique identifier
SCRIPT_VER="0.0.1"                        # Script version
SCRIPT_NAME="Go Runtime & Development"    # Display name (2-4 words)
SCRIPT_DESCRIPTION="Install Go runtime"   # One-line description
SCRIPT_CATEGORY="LANGUAGE_DEV"            # Category for grouping
SCRIPT_CHECK_COMMAND="command -v go"      # Status check (exit 0=yes, 1=no)
```

### Optional Metadata Fields

```bash
# Prerequisites (space-separated config script names)
SCRIPT_PREREQUISITES="config-identity.sh config-aws.sh"

# For service scripts - installation prerequisites
SCRIPT_PREREQUISITE_TOOLS="install-srv-nginx.sh"

# For service scripts - supervisord integration
SERVICE_PRIORITY="20"          # Start order (lower = earlier)
SERVICE_DEPENDS="service-db"   # Runtime dependencies
SERVICE_AUTO_RESTART="true"    # Restart on failure
```

### SCRIPT_COMMANDS Array

Defines available actions for submenu generation:

```bash
SCRIPT_COMMANDS=(
    "Action||Install with default version||false|"
    "Action|--version|Install specific version||true|Enter version (e.g., 1.21.0)"
    "Action|--uninstall|Uninstall this tool||false|"
    "Info|--help|Show help and usage information||false|"
)
```

**Format:** `category|flag|description|function|requires_arg|param_prompt`

| Field | Description |
|-------|-------------|
| `category` | Grouping in submenu (Action, Info, Config, Debug, etc.) |
| `flag` | Command line flag (empty = default action with no args) |
| `description` | User-friendly text shown in menu |
| `function` | Function to call (used by service scripts) |
| `requires_arg` | `true` if flag needs a parameter |
| `param_prompt` | Prompt text for parameter input |

### Check Command Guidelines

The `SCRIPT_CHECK_COMMAND` determines status display:

```bash
# Good: Fast, silent, returns 0 or 1
SCRIPT_CHECK_COMMAND="command -v go >/dev/null 2>&1"
SCRIPT_CHECK_COMMAND="[ -f ~/.config ] && grep -q 'key=' ~/.config"
SCRIPT_CHECK_COMMAND="pgrep -x nginx >/dev/null 2>&1"

# Best practice: Check install location OR PATH (works before PATH refresh)
SCRIPT_CHECK_COMMAND="[ -f /usr/local/go/bin/go ] || command -v go >/dev/null 2>&1"

# Bad: Too slow, produces output, uses variables
SCRIPT_CHECK_COMMAND="apt-cache policy python3"  # Too slow
SCRIPT_CHECK_COMMAND="echo checking..."          # Produces output
SCRIPT_CHECK_COMMAND="command -v $TOOL"          # Variable not expanded
```

---

## Library System

### Core Libraries

Located in `.devcontainer/additions/lib/`:

#### component-scanner.sh (v1.2.0)

Scans scripts and extracts metadata.

**Key Functions:**
```bash
# Scan all install scripts
scan_install_scripts "$ADDITIONS_DIR"
# Output: script_basename<TAB>SCRIPT_ID<TAB>SCRIPT_NAME<TAB>...

# Scan all config scripts
scan_config_scripts "$ADDITIONS_DIR"

# Scan all service scripts (new pattern)
scan_service_scripts_new "$ADDITIONS_DIR"

# Extract single metadata field
value=$(extract_script_metadata "/path/to/script.sh" "SCRIPT_NAME")

# Check if component is installed
if check_component_installed "$check_command"; then
    echo "Installed"
fi
```

#### categories.sh

Central category definitions.

**Table Format:**
```bash
CATEGORY_TABLE="
SORT|ID|DISPLAY_NAME|SHORT_DESC|LONG_DESC
1|LANGUAGE_DEV|Development Tools|Dev tools|Programming languages...
2|AI_TOOLS|AI & ML Tools|AI tools|AI and machine learning...
"
```

**Key Functions:**
```bash
# Get display name for category
get_category_display_name "LANGUAGE_DEV"  # Returns: "Development Tools"

# Get all category IDs in sort order
get_all_category_ids  # Returns: LANGUAGE_DEV\nAI_TOOLS\n...

# Validate category
is_valid_category "LANGUAGE_DEV"  # Returns 0 or 1
```

#### prerequisite-check.sh

Validates dependencies before script execution.

```bash
# Check if prerequisites are met
if check_prerequisite_configs "config-identity.sh config-aws.sh" "$ADDITIONS_DIR"; then
    echo "All prerequisites met"
fi

# Show what's missing
show_missing_prerequisites "config-identity.sh" "$ADDITIONS_DIR"
```

#### service-auto-enable.sh

Manages `enabled-services.conf` for auto-start on container restart.

```bash
# Enable service for auto-start
enable_service_autostart "nginx" "Nginx Proxy"

# Disable service
disable_service_autostart "nginx" "Nginx Proxy"

# Check if enabled
is_auto_enabled "nginx"
```

#### tool-auto-enable.sh

Manages `enabled-tools.conf` for auto-install on container rebuild.

```bash
# Enable tool for auto-install
auto_enable_tool   # Uses SCRIPT_ID from script

# Disable tool
auto_disable_tool

# Check if enabled
is_tool_auto_enabled "dev-golang"
```

#### logging.sh

Automatic output logging.

```bash
# Source at script start - all output auto-logged
source "${SCRIPT_DIR}/lib/logging.sh"

# Logs written to: /tmp/devcontainer-install/scriptname-YYYYMMDD-HHMMSS.log
```

#### install-common.sh

Shared installation patterns.

```bash
# Standard installation processing (uses PACKAGES_* arrays)
process_standard_installations

# Show script help (auto-generated from metadata)
show_script_help

# Show install header
show_install_header          # For install
show_install_header "uninstall"  # For uninstall
```

### Package Installer Libraries

| Library | Purpose |
|---------|---------|
| `core-install-system.sh` | apt-get packages |
| `core-install-node.sh` | npm packages |
| `core-install-python.sh` | pip packages |
| `core-install-go.sh` | go install packages |
| `core-install-cargo.sh` | cargo packages |
| `core-install-dotnet.sh` | dotnet tools |
| `core-install-pwsh.sh` | PowerShell modules |
| `core-install-extensions.sh` | VS Code extensions |

---

## Key Patterns

### 1. Status Check Pattern

Single source of truth for status:

```bash
SCRIPT_CHECK_COMMAND="[ -f /usr/local/go/bin/go ] || command -v go >/dev/null 2>&1"
```

Used by:
- Menu system for ✅/❌ display
- Scripts to skip if already installed
- Prerequisites validation

### 2. Auto-Enable Pattern

Track installations for rebuild persistence:

```bash
# In main execution block
if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    # ... uninstall logic ...
    auto_disable_tool
else
    # ... install logic ...
    auto_enable_tool
fi
```

Stores in `.devcontainer.extend/enabled-tools.conf`:
```
# Auto-enabled tools for container rebuild
dev-golang
dev-python
tool-kubernetes
```

### 3. Config Persistence Pattern

Survive container rebuilds:

```bash
# 1. Interactive mode saves to .devcontainer.secrets
write_configuration() {
    local TOPSECRET_PATH="/workspace/.devcontainer.secrets/myconfig"
    echo "KEY=$VALUE" > "$TOPSECRET_PATH"
    ln -sf "$TOPSECRET_PATH" "$HOME/.myconfig"
}

# 2. --verify mode restores symlink
verify_config() {
    local TOPSECRET_PATH="/workspace/.devcontainer.secrets/myconfig"
    if [ -f "$TOPSECRET_PATH" ]; then
        ln -sf "$TOPSECRET_PATH" "$HOME/.myconfig"
        return 0
    fi
    return 1  # Silent failure - config not in .devcontainer.secrets yet
}

# 3. Handle --verify flag before main
if [ "${1:-}" = "--verify" ]; then
    verify_config
    exit $?
fi
```

### 4. Two-Layer Prerequisite Pattern

**Layer 1: Silent Restoration** (before tools)
- Runs `config-*.sh --verify` for all configs
- Silent when config not in `.devcontainer.secrets`
- Shows ✅ only for successful restorations

**Layer 2: Loud Prerequisites** (during tool install)
- Checks `SCRIPT_PREREQUISITES` for enabled tools
- Blocks installation if required config missing
- Shows clear error with fix instructions

### 5. Service Foreground Pattern

For supervisord integration:

```bash
service_start() {
    # ... setup logic ...

    # CRITICAL: Use exec for supervisord
    # This replaces the shell process with nginx
    exec sudo nginx -g "daemon off;"

    # Code after exec NEVER runs
}
```

### 6. Submenu Generation Pattern

Declarative action definitions:

```bash
SCRIPT_COMMANDS=(
    "Control|--start|Start service|service_start|false|"
    "Control|--stop|Stop service|service_stop|false|"
    "Status|--status|Show status|service_status|false|"
)

# Framework parses array and:
# 1. Generates --help text
# 2. Builds menu options
# 3. Routes flags to functions
```

---

## Directory Structure

```
.devcontainer/
├── manage/                           # Management scripts
│   ├── dev-setup.sh                  # Main menu entry point
│   ├── dev-services.sh               # Service management helpers
│   ├── dev-template.sh               # Project template system
│   ├── postCreateCommand.sh          # Container startup script
│   ├── dev-check.sh                  # Config validation
│   ├── dev-clean.sh                  # Container cleanup
│   ├── dev-env.sh                    # Environment info
│   ├── dev-help.sh                   # Help command
│   ├── dev-update.sh                 # Update toolbox
│   ├── dev-docs.sh                   # Documentation generator
│   └── dev-test.sh                   # Test runner
│
├── additions/                        # Additions system
│   ├── lib/                          # Shared libraries
│   │   ├── component-scanner.sh      # Metadata extraction
│   │   ├── categories.sh             # Category definitions
│   │   ├── prerequisite-check.sh     # Dependency validation
│   │   ├── service-auto-enable.sh    # Auto-start management
│   │   ├── tool-auto-enable.sh       # Auto-install management
│   │   ├── logging.sh                # Output logging
│   │   ├── install-common.sh         # Shared install patterns
│   │   ├── cmd-framework.sh          # Command parsing framework
│   │   └── core-install-*.sh         # Package installers
│   │
│   ├── addition-templates/           # Templates for new scripts
│   │   ├── _template-install-script.sh
│   │   ├── _template-config-script.sh
│   │   ├── _template-service-script.sh
│   │   ├── _template-cmd-script.sh
│   │   └── README-secrets.md            # User-facing secrets docs
│   │
│   ├── install-*.sh                  # Tool installers
│   ├── config-*.sh                   # Configuration scripts
│   ├── service-*.sh                  # Service managers
│   ├── cmd-*.sh                      # Command utilities
│   │
│   ├── nginx/                        # Nginx config templates
│   ├── otel/                         # OTEL config and dashboards
│   └── tests/                        # Test suite
│
└── doc/                              # Documentation
    └── additions-system-architecture.md  # This file

.devcontainer.extend/                 # Project-specific (persisted)
├── enabled-tools.conf                # Tools to auto-install
├── enabled-services.conf             # Services to auto-start
└── project-installs.sh               # Project-specific setup

.devcontainer.secrets/                # Secrets (git-ignored)
├── nginx-config/                     # Nginx backend config
├── devcontainer-identity             # Developer identity
└── ...                               # Other credentials
```

---

## Data Flow

### Container Startup Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ Container Created                                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. postCreateCommand.sh executes                                    │
│     │                                                                │
│     ├─→ restore_all_configurations()                                │
│     │   └─→ Runs all config-*.sh --verify                           │
│     │       └─→ Restores configs from .devcontainer.secrets         │
│     │                                                                │
│     ├─→ install_project_tools()                                     │
│     │   └─→ Reads enabled-tools.conf                                │
│     │       └─→ For each tool:                                      │
│     │           ├─→ Check SCRIPT_PREREQUISITES                      │
│     │           └─→ Run install-*.sh                                │
│     │                                                                │
│     └─→ start_enabled_services()                                    │
│         └─→ Reads enabled-services.conf                             │
│             └─→ For each service (by priority):                     │
│                 └─→ supervisorctl start service                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Menu System Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ User runs: dev-setup                                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. dev-setup.sh starts                                              │
│     │                                                                │
│     ├─→ Source libraries                                            │
│     │   ├─→ component-scanner.sh                                    │
│     │   ├─→ categories.sh                                           │
│     │   └─→ prerequisite-check.sh                                   │
│     │                                                                │
│     ├─→ scan_available_tools()                                      │
│     │   └─→ For each install-*.sh:                                  │
│     │       ├─→ Extract metadata (grep SCRIPT_*)                    │
│     │       └─→ Populate AVAILABLE_TOOLS[] arrays                   │
│     │                                                                │
│     └─→ show_main_menu()                                            │
│         └─→ dialog --menu                                           │
│             │                                                        │
│             ├─→ "Browse & Install Tools"                            │
│             │   └─→ show_category_menu()                            │
│             │       └─→ show_tools_in_category()                    │
│             │           └─→ show_tool_details_and_confirm()         │
│             │               └─→ Execute selected action             │
│             │                                                        │
│             ├─→ "Manage Services"                                   │
│             │   └─→ show_all_services_menu()                        │
│             │       └─→ show_service_submenu()                      │
│             │           └─→ Execute --start/--stop/etc.             │
│             │                                                        │
│             └─→ ... other menu options ...                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Extending the System

### Adding a New Tool

1. Copy template:
   ```bash
   cp .devcontainer/additions/addition-templates/_template-install-script.sh \
      .devcontainer/additions/install-mytool.sh
   ```

2. Update metadata:
   ```bash
   SCRIPT_ID="mytool"
   SCRIPT_NAME="My Tool"
   SCRIPT_DESCRIPTION="Install My Tool for development"
   SCRIPT_CATEGORY="LANGUAGE_DEV"
   SCRIPT_CHECK_COMMAND="command -v mytool >/dev/null 2>&1"
   ```

3. Define packages and extensions:
   ```bash
   PACKAGES_SYSTEM=("mytool-package")
   EXTENSIONS=("MyTool Extension (publisher.extension)")
   ```

4. Script is automatically discovered in menu.

### Adding a New Category

Edit `.devcontainer/additions/lib/categories.sh`:

```bash
CATEGORY_TABLE="
...existing categories...
7|MY_CATEGORY|My Category Name|Short desc|Long description here
"
```

### Adding a New Config

1. Copy template:
   ```bash
   cp .devcontainer/additions/addition-templates/_template-config-script.sh \
      .devcontainer/additions/config-myconfig.sh
   ```

2. Implement `verify_myconfig()` for `--verify` support

3. Save config to `.devcontainer.secrets/` in `write_configuration()`

---

## References

- [Menu System](menu-system.md) - Dialog tool usage and widgets
- [Creating Install Scripts](creating-install-scripts.md) - Complete install script guide
- [Creating Service Scripts](creating-service-scripts.md) - Service script guide
- [Libraries Reference](libraries.md) - Library functions documentation
- [categories.sh](../../.devcontainer/additions/lib/categories.sh) - Category definitions
- [component-scanner.sh](../../.devcontainer/additions/lib/component-scanner.sh) - Scanner library

---

**Last Updated:** 2024-12
**System Version:** dev-setup.sh v3.4.0, component-scanner.sh v1.2.0
