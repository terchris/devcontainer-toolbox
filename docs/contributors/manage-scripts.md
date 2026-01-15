# Manage Scripts (dev-*.sh)

Guide for working with manage scripts - the system commands that control devcontainer-toolbox.

## Overview

The `manage/` folder contains **system commands** (dev-*.sh) that users run directly. These are different from `additions/` scripts which install tools.

| Folder | Purpose | Examples |
|--------|---------|----------|
| `.devcontainer/manage/` | System commands for users | dev-setup, dev-help, dev-update |
| `.devcontainer/additions/` | Install scripts for tools | install-dev-python.sh, install-dev-golang.sh |

## Script Categories

Manage scripts use two categories:

| Category | Sort Order | Purpose |
|----------|------------|---------|
| `SYSTEM_COMMANDS` | 0 (first) | Core user commands (help, update, services, etc.) |
| `CONTRIBUTOR_TOOLS` | 7 (last) | Tools for contributors (dev-docs, dev-test) |

## Metadata Format

All manage scripts must have this metadata block near the top:

```bash
#------------------------------------------------------------------------------
# Script Metadata (for component scanner)
#------------------------------------------------------------------------------
SCRIPT_ID="dev-example"
SCRIPT_NAME="Example Command"
SCRIPT_DESCRIPTION="Brief description of what this command does"
SCRIPT_CATEGORY="SYSTEM_COMMANDS"  # or CONTRIBUTOR_TOOLS
SCRIPT_CHECK_COMMAND="true"
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `SCRIPT_ID` | Yes | Command name without .sh (e.g., "dev-help") |
| `SCRIPT_NAME` | Yes | Short display name for menus (e.g., "Help") |
| `SCRIPT_DESCRIPTION` | Yes | One-line description |
| `SCRIPT_CATEGORY` | Yes | `SYSTEM_COMMANDS` or `CONTRIBUTOR_TOOLS` |
| `SCRIPT_CHECK_COMMAND` | Yes | Usually "true" for manage scripts |

## How Scripts Are Discovered

The `component-scanner.sh` library provides `scan_manage_scripts()` which:

1. Scans all `dev-*.sh` files in the manage directory
2. Extracts metadata from each script
3. Returns tab-separated data for menu generation

**Excluded scripts:**
- `dev-setup.sh` - Excluded to avoid recursion (it's the menu itself)
- `dev-welcome.sh` - Internal script, runs on container start

## Dynamic Menu System

The `dev-setup` main menu is dynamically generated:

1. At startup, `scan_available_manage_scripts()` populates arrays
2. Scripts are grouped by category (SYSTEM_COMMANDS, CONTRIBUTOR_TOOLS)
3. Selecting a category shows a submenu of scripts in that category
4. Selecting a script executes it directly

**Special case:** `dev-template` is shown directly in the main menu at position 2, not in the SYSTEM_COMMANDS submenu.

## Adding a New Manage Script

1. Create the script in `.devcontainer/manage/`:
   ```bash
   #!/bin/bash
   # file: .devcontainer/manage/dev-newcmd.sh

   #------------------------------------------------------------------------------
   # Script Metadata (for component scanner)
   #------------------------------------------------------------------------------
   SCRIPT_ID="dev-newcmd"
   SCRIPT_NAME="New Command"
   SCRIPT_DESCRIPTION="What this command does"
   SCRIPT_CATEGORY="SYSTEM_COMMANDS"
   SCRIPT_CHECK_COMMAND="true"

   # ... rest of script
   ```

2. Add to `environment-utils.sh` commands array:
   ```bash
   local commands=(
       # ... existing commands
       "dev-newcmd"
   )
   ```

3. Make executable:
   ```bash
   chmod +x .devcontainer/manage/dev-newcmd.sh
   ```

4. Documentation is auto-updated by CI after merge. To preview locally:
   ```bash
   dev-docs
   ```

## When to Add Manage Scripts vs Additions Scripts

| Add to manage/ | Add to additions/ |
|----------------|-------------------|
| System-level commands | Tool installation |
| User-facing dev-* commands | Background services |
| Maintenance utilities | Config scripts |
| Contributor tools | Command scripts |

**Rule of thumb:** If it's a command users type directly (`dev-something`), it goes in `manage/`. If it installs/configures something, it goes in `additions/`.

## Testing

Run static tests to validate metadata:

```bash
dev-test static
```

This checks:
- Script syntax
- Required metadata fields
- Category validity
