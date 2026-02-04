---
title: System Architecture
sidebar_position: 1
---

# DevContainer Additions System - Architecture

This document describes the architecture and design patterns of the DevContainer Additions System - a metadata-driven, self-discovering script management system for devcontainer configuration.

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

### Install Scripts (`install-*.sh`)

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

### Config Scripts (`config-*.sh`)

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

### Service Scripts (`service-*.sh`)

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

### Command Scripts (`cmd-*.sh`)

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
│   │   └── _template-cmd-script.sh
│   │
│   ├── install-*.sh                  # Tool installers
│   ├── config-*.sh                   # Configuration scripts
│   ├── service-*.sh                  # Service managers
│   └── cmd-*.sh                      # Command utilities
│
└── doc/                              # Documentation

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
│             └─→ "Manage Services"                                   │
│                 └─→ show_all_services_menu()                        │
│                     └─→ show_service_submenu()                      │
│                         └─→ Execute --start/--stop/etc.             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

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

### 3. Config Persistence Pattern

Survive container rebuilds:

```bash
# 1. Interactive mode saves to .devcontainer.secrets
write_configuration() {
    local SECRETS_PATH="/workspace/.devcontainer.secrets/myconfig"
    echo "KEY=$VALUE" > "$SECRETS_PATH"
    ln -sf "$SECRETS_PATH" "$HOME/.myconfig"
}

# 2. --verify mode restores symlink
verify_config() {
    local SECRETS_PATH="/workspace/.devcontainer.secrets/myconfig"
    if [ -f "$SECRETS_PATH" ]; then
        ln -sf "$SECRETS_PATH" "$HOME/.myconfig"
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

---

## See Also

- [Categories Reference](categories) - Valid script categories
- [Libraries Reference](libraries) - Shared library functions
- [Menu System](menu-system) - Dialog tool usage
- [Creating Scripts](../scripts/install-scripts) - How to create new scripts
