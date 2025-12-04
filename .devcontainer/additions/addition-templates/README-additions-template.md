# Addition Script Templates - Developer Guide

**Location:** `/workspace/.devcontainer/additions/addition-templates/`

This directory contains templates for creating new addition scripts that extend the devcontainer with tools, configurations, and services.

---

## Table of Contents

1. [Overview](#overview)
2. [Types of Addition Scripts](#types-of-addition-scripts)
3. [Quick Start](#quick-start)
4. [Template Files](#template-files)
5. [Metadata Fields Reference](#metadata-fields-reference)
6. [The Two-Layer System](#the-two-layer-system)
7. [Prerequisites Pattern](#prerequisites-pattern)
8. [Best Practices](#best-practices)
9. [Testing Your Script](#testing-your-script)
10. [Examples](#examples)

---

## Overview

Addition scripts are bash scripts that automate the installation of tools, configuration of settings, or deployment of services in the devcontainer. They follow a metadata-driven pattern that enables:

- **Automatic discovery** - Scripts are discovered via metadata, no manual registration
- **Menu integration** - Scripts appear in `dev-setup` interactive menu
- **Dependency management** - Prerequisites are checked automatically
- **Idempotent operation** - Safe to run multiple times
- **Clean user experience** - Silent when not needed, loud when required

---

## Types of Addition Scripts

### 1. Installation Scripts (`install-*.sh`)

**Purpose:** Install tools, runtimes, CLI applications, or development environments

**Naming:** `install-<tool-name>.sh`

**Examples:**
- `install-dev-python.sh` - Python runtime and development tools
- `install-kubectl.sh` - Kubernetes CLI
- `install-srv-otel-monitoring.sh` - OpenTelemetry monitoring stack

**Characteristics:**
- Installs binaries, packages, or tools
- Checks if already installed (idempotent)
- Can declare configuration prerequisites
- Auto-adds to `enabled-tools.conf` on success

### 2. Configuration Scripts (`config-*.sh`)

**Purpose:** Configure user settings, credentials, identities, or environment

**Naming:** `config-<setting-name>.sh`

**Examples:**
- `config-devcontainer-identity.sh` - Developer identity for monitoring
- `config-git.sh` - Git user name and email
- `config-aws-credentials.sh` - AWS CLI credentials

**Characteristics:**
- Interactive (prompts user for input)
- Supports `--verify` flag for automatic restoration from .devcontainer.secrets
- Stores configs in `/workspace/.devcontainer.secrets` for persistence across rebuilds
- Idempotent (safe to reconfigure)

### 3. Command Scripts (`cmd-*.sh`)

**Purpose:** Provide multiple related commands for managing, querying, or analyzing resources

**Naming:** `cmd-<purpose>.sh`

**Examples:**
- `cmd-ai.sh` - AI model and spending management
- `cmd-database.sh` - Database query and backup operations
- `cmd-docker.sh` - Docker container management
- `cmd-metrics.sh` - System metrics and monitoring

**Characteristics:**
- Non-interactive (flag-based interface)
- Multiple commands in single script via SCRIPT_COMMANDS array
- Integrates with dev-setup menu (shows all commands)
- Help text auto-generated from SCRIPT_COMMANDS array
- Supports both direct CLI usage and menu execution
- Dynamic argument parsing via cmd-framework.sh

**Key Features:**
- **Single Source of Truth:** SCRIPT_COMMANDS array defines all commands (no manual duplication)
- **Auto-discovery:** Metadata enables automatic menu integration
- **Prerequisites:** Can require config scripts before execution
- **Reusable:** Uses cmd-framework.sh and utilities.sh libraries

---

## Quick Start

### Creating an Install Script

```bash
# 1. Copy the template
cp /workspace/.devcontainer/additions/addition-templates/_template-install-script.sh \
   /workspace/.devcontainer/additions/install-mytool.sh

# 2. Edit the metadata section
# - Update SCRIPT_NAME, SCRIPT_DESCRIPTION, SCRIPT_CATEGORY
# - Update CHECK_INSTALLED_COMMAND
# - Add PREREQUISITE_CONFIGS if needed

# 3. Implement your installation logic
# - Replace placeholder functions with actual installation code
# - Test installation and verification

# 4. Test the script
bash /workspace/.devcontainer/additions/install-mytool.sh

# 5. Enable in project-installs.sh
echo "mytool" >> /workspace/.devcontainer.extend/enabled-tools.conf
bash /workspace/.devcontainer.extend/project-installs.sh
```

### Creating a Config Script

```bash
# 1. Copy the template
cp /workspace/.devcontainer/additions/addition-templates/_template-config-script.sh \
   /workspace/.devcontainer/additions/config-mytool.sh

# 2. Edit the metadata section
# - Update CONFIG_NAME, CONFIG_DESCRIPTION, CONFIG_CATEGORY
# - Update CHECK_CONFIGURED_COMMAND

# 3. Implement verify_your_config() function
# - Check /workspace/.devcontainer.secrets/your-config-file
# - Restore with symlink if exists
# - Return 0 if restored, 1 if not found

# 4. Implement interactive configuration
# - Prompt user for values
# - Save to /workspace/.devcontainer.secrets/your-config-file
# - Create symlink from home directory

# 5. Test both modes
bash /workspace/.devcontainer/additions/config-mytool.sh           # Interactive
bash /workspace/.devcontainer/additions/config-mytool.sh --verify  # Restoration
```

### Creating a Command Script

```bash
# 1. Copy the template
cp /workspace/.devcontainer/additions/addition-templates/_template-cmd-script.sh \
   /workspace/.devcontainer/additions/cmd-mytool.sh

# 2. Edit the metadata section
# - Update CMD_SCRIPT_NAME, CMD_SCRIPT_DESCRIPTION, CMD_SCRIPT_CATEGORY
# - Update CMD_PREREQUISITE_CONFIGS (or leave empty if none)

# 3. Define your SCRIPT_COMMANDS array
# Format: "category|flag|description|function|requires_arg|param_prompt"
SCRIPT_COMMANDS=(
    "Management|--list|List all items|cmd_list|false|"
    "Management|--delete|Delete an item|cmd_delete|true|Enter item ID"
    "Analysis|--stats|Show statistics|cmd_stats|false|"
)

# 4. Implement command functions
cmd_list() {
    # Your list implementation
}

cmd_delete() {
    local item_id="$1"
    # Your delete implementation
}

cmd_stats() {
    # Your stats implementation
}

# 5. Test the script
bash /workspace/.devcontainer/additions/cmd-mytool.sh --help     # Show all commands
bash /workspace/.devcontainer/additions/cmd-mytool.sh --list     # Test command
bash /workspace/.devcontainer/additions/cmd-mytool.sh --delete 123  # Test with arg

# 6. Access via menu
dev-setup
# Select: 4) Command Tools → Your script → Select command
```

**Benefits:**
- Add new command = 1 line in SCRIPT_COMMANDS array + implement function
- Help text auto-generated
- Menu integration automatic
- No need to modify parse_args()

---

## Template Files

### `_template-install-script.sh`

Complete template for creating tool installation scripts.

**Includes:**
- Metadata fields (SCRIPT_NAME, SCRIPT_DESCRIPTION, SCRIPT_CATEGORY, CHECK_INSTALLED_COMMAND)
- PREREQUISITE_CONFIGS field (optional)
- Logging integration (automatic logging to /tmp/devcontainer-install/)
- Auto-enable integration (automatic addition to enabled-tools.conf)
- Installation function templates
- Verification function templates
- Error handling patterns

**Key Sections:**
```bash
# Metadata
SCRIPT_NAME="My Tool"
SCRIPT_DESCRIPTION="Install and configure My Tool"
SCRIPT_CATEGORY="DEV_TOOLS"
CHECK_INSTALLED_COMMAND="command -v mytool >/dev/null 2>&1"
PREREQUISITE_CONFIGS="config-mytool.sh"  # Optional

# Installation
install_mytool() {
    # Your installation logic here
}

# Verification
verify_installation() {
    # Check if installation succeeded
}
```

### `_template-config-script.sh`

Complete template for creating configuration scripts with automatic restoration support.

**Includes:**
- Metadata fields (CONFIG_NAME, CONFIG_DESCRIPTION, CONFIG_CATEGORY, CHECK_CONFIGURED_COMMAND)
- --verify flag support (automatic restoration from .devcontainer.secrets)
- Logging integration
- Interactive configuration flow
- Validation functions
- .devcontainer.secrets integration patterns

**Key Sections:**
```bash
# Metadata
CONFIG_NAME="My Tool Configuration"
CONFIG_DESCRIPTION="Configure My Tool settings"
CONFIG_CATEGORY="USER_CONFIG"
CHECK_CONFIGURED_COMMAND="[ -f ~/.mytool-config ]"

# Non-interactive restoration (--verify flag)
verify_your_config() {
    local .devcontainer.secrets_path="/workspace/.devcontainer.secrets/mytool-config"
    local home_path="$HOME/.mytool-config"

    if [ -f "$.devcontainer.secrets_path" ]; then
        ln -sf "$.devcontainer.secrets_path" "$home_path"
        echo "✅ My Tool configuration restored"
        return 0
    fi
    return 1
}

# Handle --verify flag
if [ "${1:-}" = "--verify" ]; then
    verify_your_config
    exit $?
fi

# Interactive configuration
main() {
    # Prompt user, validate, save to .devcontainer.secrets
}
```

### `_template-cmd-script.sh`

Complete template for creating command scripts with automatic menu integration.

**Includes:**
- Metadata fields (CMD_SCRIPT_NAME, CMD_SCRIPT_DESCRIPTION, CMD_SCRIPT_CATEGORY, CMD_PREREQUISITE_CONFIGS)
- SCRIPT_COMMANDS array pattern (single source of truth for all commands)
- cmd-framework.sh integration (automatic argument parsing and help generation)
- utilities.sh integration (date ranges, currency formatting, number formatting)
- Example command implementations (management, analysis, testing)
- Prerequisite checking
- API call patterns

**Key Sections:**
```bash
# Metadata
CMD_SCRIPT_NAME="Example Management"
CMD_SCRIPT_DESCRIPTION="Manage and analyze example resources"
CMD_SCRIPT_CATEGORY="UNCATEGORIZED"
CMD_PREREQUISITE_CONFIGS="config-example.sh"  # Optional

# SCRIPT_COMMANDS array (6 fields)
# Format: category|flag|description|function|requires_arg|param_prompt
SCRIPT_COMMANDS=(
    "Management|--list|List all items|cmd_list|false|"
    "Management|--delete|Delete an item|cmd_delete|true|Enter item ID"
    "Analysis|--stats|Show statistics|cmd_stats|false|"
)

# Command functions
cmd_list() {
    # Implementation
}

cmd_delete() {
    local item_id="$1"
    # Implementation
}

# Help and parsing (uses framework)
show_help() {
    source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    cmd_framework_generate_help SCRIPT_COMMANDS "cmd-example.sh"
}

parse_args() {
    source "${SCRIPT_DIR}/lib/cmd-framework.sh"
    cmd_framework_parse_args SCRIPT_COMMANDS "cmd-example.sh" "$@"
}
```

**Adding a new command:**
1. Add one line to SCRIPT_COMMANDS array
2. Implement the function
3. Done! (Help text, menu integration, parsing all automatic)

---

## Metadata Fields Reference

### Install Scripts

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `SCRIPT_NAME` | Yes | Human-readable name (2-4 words) | `"Python Development Tools"` |
| `SCRIPT_DESCRIPTION` | Yes | Brief description (one sentence) | `"Install Python 3.11 and pip"` |
| `SCRIPT_CATEGORY` | Yes | Category for menu organization | `"DEV_TOOLS"` |
| `CHECK_INSTALLED_COMMAND` | Yes | Command to check if installed | `"command -v python3 >/dev/null 2>&1"` |
| `PREREQUISITE_CONFIGS` | No | Space-separated config scripts | `"config-aws-credentials.sh"` |

**Categories:**
- `DEV_TOOLS` - Development tools and runtimes
- `INFRA_CONFIG` - Infrastructure configuration
- `AI_TOOLS` - AI and machine learning tools
- `MONITORING` - Monitoring and observability
- `DATABASE` - Database clients and tools
- `CLOUD` - Cloud provider CLIs

### Config Scripts

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `CONFIG_NAME` | Yes | Human-readable name (2-4 words) | `"Git User Identity"` |
| `CONFIG_DESCRIPTION` | Yes | Brief description (one sentence) | `"Configure Git user name and email"` |
| `CONFIG_CATEGORY` | Yes | Category for menu organization | `"USER_CONFIG"` |
| `CHECK_CONFIGURED_COMMAND` | Yes | Command to check if configured | `"git config user.name >/dev/null 2>&1"` |

**Categories:**
- `USER_CONFIG` - User-specific configurations
- `INFRA_CONFIG` - Infrastructure configurations
- `SECURITY` - Security and authentication
- `CREDENTIALS` - Credentials and API keys

### Command Scripts

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `CMD_SCRIPT_NAME` | Yes | Human-readable name (2-4 words) | `"AI Management"` |
| `CMD_SCRIPT_DESCRIPTION` | Yes | Brief description (one sentence) | `"Manage AI models, spending, and usage"` |
| `CMD_SCRIPT_CATEGORY` | Yes | Category for menu organization | `"AI_TOOLS"` |
| `CMD_PREREQUISITE_CONFIGS` | No | Space-separated config scripts | `"config-ai-claudecode.sh"` or `""` |
| `SCRIPT_COMMANDS` | Yes | Array of command definitions | See SCRIPT_COMMANDS array format below |

**SCRIPT_COMMANDS Array Format (6 fields):**
```
"category|flag|description|function|requires_arg|param_prompt"
```

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| category | string | Command grouping | `"Management"`, `"Analysis"` |
| flag | string | Command line flag (starts with --) | `"--list"`, `"--delete"` |
| description | string | User-friendly description | `"List all items"` |
| function | string | Function name to call | `"cmd_list"`, `"cmd_delete"` |
| requires_arg | boolean | Needs parameter? | `"true"`, `"false"` |
| param_prompt | string | Parameter prompt (empty if no param) | `"Enter item ID"`, `""` |

**Example:**
```bash
SCRIPT_COMMANDS=(
    "Management|--list|List all items|cmd_list|false|"
    "Management|--delete|Delete an item|cmd_delete|true|Enter item ID"
)
```

**Categories:**
- `AI_TOOLS` - AI and ML tools
- `DATABASE` - Database operations
- `MONITORING` - Monitoring and metrics
- `INFRA_CONFIG` - Infrastructure management
- `DATA_ANALYTICS` - Data analysis tools
- `UNCATEGORIZED` - Other commands

---

## The Two-Layer System

The devcontainer uses a two-layer approach for managing configurations and prerequisites:

### Layer 1: Silent Config Restoration

**Function:** `restore_all_configurations()` in `project-installs.sh`

**When:** Runs BEFORE tool installation

**Behavior:**
- Discovers ALL `config-*.sh` scripts automatically
- Runs each with `--verify` flag
- Shows ✅ for successful restorations
- **SILENT for missing configs** (no warnings)
- Non-blocking - always continues

**Output:**
```bash
📋 Scanning for configuration scripts...
   ✅ Developer Identity restored
   ✅ AWS Credentials restored

📊 Configuration Restoration Summary:
   ✅ Restored: 2
```

**Purpose:** Restore configs that exist in .devcontainer.secrets without noise. Missing configs are expected (user might not need them).

### Layer 2: Loud Tool Prerequisites

**Function:** `install_project_tools()` in `project-installs.sh`

**When:** Runs DURING tool installation for ENABLED tools

**Behavior:**
- Checks `PREREQUISITE_CONFIGS` field for each enabled tool
- Uses `lib/prerequisite-check.sh` to verify configs
- Shows ⚠️ error if REQUIRED config missing
- **Blocks installation** until prerequisites met
- Provides clear fix instructions

**Output:**
```bash
⚠️  My Tool - missing prerequisites
  ❌ AWS Credentials (run: bash .../config-aws-credentials.sh)

💡 To fix:
   1. Run: check-configs
   2. Then re-run: bash .../project-installs.sh

❌ My Tool - installation skipped (prerequisites not met)
```

**Purpose:** Catch missing configs that are ACTUALLY required by enabled tools. Provides clear error with fix instructions.

### Why Two Layers?

**Problem:** If we warn about every missing config during restoration, it's noisy and confusing:
```bash
⚠️  Tailscale: not found in .devcontainer.secrets  ← User doesn't use Tailscale
⚠️  kubectl: not found in .devcontainer.secrets   ← User doesn't use kubectl
⚠️  AWS CLI: not found in .devcontainer.secrets   ← User doesn't use AWS
```

**Solution:**
- **Layer 1:** Silent restoration = no noise for configs user doesn't need
- **Layer 2:** Loud prerequisites = clear error for configs user DOES need

**Result:** Clean output, precise error reporting when it matters.

---

## Prerequisites Pattern

### When to Use Prerequisites

Add `PREREQUISITE_CONFIGS` to your install script when your tool requires:
- User credentials (AWS keys, API tokens, etc.)
- Identity/authentication (developer identity for monitoring)
- Configuration files (kubeconfig, database connection strings)
- Environment-specific settings

### How to Declare Prerequisites

In your install script metadata section:

```bash
# Single prerequisite
PREREQUISITE_CONFIGS="config-aws-credentials.sh"

# Multiple prerequisites
PREREQUISITE_CONFIGS="config-devcontainer-identity.sh config-aws-credentials.sh"
```

### What Happens When Prerequisites Are Missing

**During Layer 1 (Silent Restoration):**
```bash
# No warning shown - might not be needed yet
```

**During Layer 2 (Tool Installation):**
```bash
📦 Installing My Tool...
⚠️  My Tool - missing prerequisites
  ❌ AWS Credentials (run: bash /workspace/.devcontainer/additions/config-aws-credentials.sh)

💡 To fix:
   1. Run: check-configs (configures all missing items)
   2. Or run each config script listed above
   3. Then re-run: bash /workspace/.devcontainer.extend/project-installs.sh

❌ My Tool - installation skipped (prerequisites not met)
```

### Prerequisites Are Checked Automatically

You don't need to write code to check prerequisites! The system does it for you:

**DON'T DO THIS (old way):**
```bash
# In install-mytool.sh - DON'T write this!
check_aws_credentials() {
    if [ ! -f ~/.aws/credentials ]; then
        echo "ERROR: AWS credentials not configured"
        echo "Run: bash .../config-aws-credentials.sh"
        exit 1
    fi
}
check_aws_credentials || exit 1
```

**DO THIS (new way):**
```bash
# In install-mytool.sh - Just add metadata!
PREREQUISITE_CONFIGS="config-aws-credentials.sh"

# That's it! The system handles checking and error messages.
```

**Benefits:**
- 1 line of metadata vs 30+ lines of code
- Consistent error messages across all tools
- Automatic checking by project-installs.sh
- No code duplication

---

## Best Practices

### General

1. **Start with the template** - Don't write from scratch
2. **Test both success and failure paths** - Verify error handling
3. **Be idempotent** - Safe to run multiple times
4. **Use logging library** - Automatic logging to /tmp/devcontainer-install/
5. **Follow naming conventions** - `install-*.sh` or `config-*.sh`
6. **Document prerequisites** - Use PREREQUISITE_CONFIGS field

### Install Scripts

1. **Check before install** - Use CHECK_INSTALLED_COMMAND to skip if already installed
2. **Check installation location OR PATH** - Better UX even before shell restart
   ```bash
   # Good - checks both location and PATH
   CHECK_INSTALLED_COMMAND="[ -f /usr/local/bin/tool ] || command -v tool >/dev/null 2>&1"

   # Bad - only checks PATH (won't work until shell restart)
   CHECK_INSTALLED_COMMAND="command -v tool >/dev/null 2>&1"
   ```
3. **Verify after install** - Confirm tool is accessible
4. **Clean up on failure** - Remove partial installations
5. **Use version variables** - Make updates easier
6. **Test uninstall** - Implement --uninstall flag

### Config Scripts

1. **Implement --verify support** - Enable automatic restoration
2. **Save to .devcontainer.secrets first** - Then symlink from home directory
   ```bash
   # Good - persists across rebuilds
   cat > /workspace/.devcontainer.secrets/mytool-config <<EOF
   config data
   EOF
   ln -sf /workspace/.devcontainer.secrets/mytool-config ~/.mytool-config

   # Bad - lost on rebuild
   cat > ~/.mytool-config <<EOF
   config data
   EOF
   ```
3. **Validate user input** - Check format before saving
4. **Support reconfiguration** - Allow updating existing config
5. **Hide sensitive data** - Mask passwords/keys in output
6. **Test --verify mode** - Verify restoration works

### Error Handling

1. **Use set -euo pipefail** - Fail fast on errors
2. **Provide clear error messages** - Tell user what went wrong and how to fix
3. **Exit with appropriate codes** - 0 = success, 1 = failure
4. **Don't fail silently** - Always log errors

### Performance

1. **Fast check commands** - CHECK_INSTALLED_COMMAND should run in < 1 second
2. **Avoid network calls in checks** - Check local files/binaries, not remote
3. **Cache downloads** - Don't re-download on each run
4. **Parallel-safe** - Multiple scripts might run concurrently

---

## Testing Your Script

### 0. Verify System Health (Before Creating Scripts)

Before creating new addition scripts, verify the core systems work correctly:

```bash
bash /workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh
```

This runs 10 automated unit tests that validate:
- Component scanning and metadata extraction
- Prerequisite checking system
- Auto-enable functionality
- Configuration restoration (--verify)

**Expected output:**
```
✅ ALL TESTS PASSED
Total Tests: 10, Passed: 10, Failed: 0
```

If tests fail, investigate before creating new scripts. See [tests/README-tests.md](./tests/README-tests.md) for details.

---

### 1. Test Installation

```bash
# Test initial installation
bash /workspace/.devcontainer/additions/install-mytool.sh

# Verify it installed correctly
which mytool
mytool --version

# Test idempotency (should skip, not re-install)
bash /workspace/.devcontainer/additions/install-mytool.sh

# Check logs
cat /tmp/devcontainer-install/install-mytool-*.log
```

### 2. Test Configuration

```bash
# Test interactive configuration
bash /workspace/.devcontainer/additions/config-mytool.sh

# Verify config exists
ls -la ~/.mytool-config
ls -la /workspace/.devcontainer.secrets/mytool-config

# Test --verify restoration
rm ~/.mytool-config
bash /workspace/.devcontainer/additions/config-mytool.sh --verify

# Test with missing config in .devcontainer.secrets
rm /workspace/.devcontainer.secrets/mytool-config
rm ~/.mytool-config
bash /workspace/.devcontainer/additions/config-mytool.sh --verify
# Should return exit code 1, no error message

# Check logs
cat /tmp/devcontainer-install/config-mytool-*.log
```

### 3. Test Prerequisites

```bash
# Test prerequisite checking
# 1. Remove prerequisite config
rm ~/.aws/credentials

# 2. Enable your tool in enabled-tools.conf
echo "mytool" >> /workspace/.devcontainer.extend/enabled-tools.conf

# 3. Run project-installs.sh
bash /workspace/.devcontainer.extend/project-installs.sh

# Should see:
# ⚠️  My Tool - missing prerequisites
#   ❌ AWS Credentials (run: bash .../config-aws-credentials.sh)
```

### 4. Test Discovery

```bash
# Test automatic discovery
source /workspace/.devcontainer/additions/lib/component-scanner.sh

# For install scripts
scan_install_scripts /workspace/.devcontainer/additions | grep mytool

# For config scripts
scan_config_scripts /workspace/.devcontainer/additions | grep mytool

# Should see your script with all metadata fields
```

### 5. Test in dev-setup Menu

```bash
# Run interactive menu
dev-setup

# Navigate to your tool's category
# Verify it appears with correct name and description
# Try installing/configuring through menu
```

---

## Examples

### Example 1: Simple Tool Installation

**Scenario:** Install `jq` JSON processor

```bash
#!/bin/bash
# File: install-jq.sh

SCRIPT_NAME="jq JSON Processor"
SCRIPT_DESCRIPTION="Install jq command-line JSON processor"
SCRIPT_CATEGORY="DEV_TOOLS"
CHECK_INSTALLED_COMMAND="command -v jq >/dev/null 2>&1"

# Source libraries
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

install_jq() {
    echo "📦 Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo "✅ jq installed successfully"
}

verify_installation() {
    if command -v jq >/dev/null 2>&1; then
        echo "✅ jq version: $(jq --version)"
        return 0
    fi
    return 1
}

main() {
    echo "🚀 Starting jq installation..."

    if eval "$CHECK_INSTALLED_COMMAND"; then
        echo "✅ jq is already installed"
        exit 0
    fi

    install_jq
    verify_installation

    # Auto-enable (automatically adds to enabled-tools.conf)
    tool_auto_enable "$SCRIPT_NAME"

    echo "🎉 Installation complete!"
}

main "$@"
```

### Example 2: Tool with Prerequisites

**Scenario:** Install AWS CLI that requires credentials

```bash
#!/bin/bash
# File: install-aws-cli.sh

SCRIPT_NAME="AWS CLI"
SCRIPT_DESCRIPTION="Install AWS Command Line Interface"
SCRIPT_CATEGORY="CLOUD"
CHECK_INSTALLED_COMMAND="command -v aws >/dev/null 2>&1"
PREREQUISITE_CONFIGS="config-aws-credentials.sh"  # Requires AWS credentials

# Source libraries
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

install_aws_cli() {
    echo "📦 Installing AWS CLI..."

    # Download AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install

    # Cleanup
    rm -rf awscliv2.zip aws/

    echo "✅ AWS CLI installed successfully"
}

verify_installation() {
    if command -v aws >/dev/null 2>&1; then
        echo "✅ AWS CLI version: $(aws --version)"
        return 0
    fi
    return 1
}

main() {
    echo "🚀 Starting AWS CLI installation..."

    # Note: Prerequisites are checked automatically by project-installs.sh
    # No need to check manually!

    if eval "$CHECK_INSTALLED_COMMAND"; then
        echo "✅ AWS CLI is already installed"
        exit 0
    fi

    install_aws_cli
    verify_installation
    tool_auto_enable "$SCRIPT_NAME"

    echo "🎉 Installation complete!"
}

main "$@"
```

### Example 3: Configuration Script

**Scenario:** Configure database connection string

```bash
#!/bin/bash
# File: config-database.sh

CONFIG_NAME="Database Connection"
CONFIG_DESCRIPTION="Configure database connection string"
CONFIG_CATEGORY="CREDENTIALS"
CHECK_CONFIGURED_COMMAND="[ -f ~/.database-config ]"

# Source libraries
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/lib/logging.sh"

# Non-interactive restoration (--verify flag)
verify_database_config() {
    local .devcontainer.secrets_config="/workspace/.devcontainer.secrets/database-config"
    local home_config="$HOME/.database-config"

    if [ -f "$.devcontainer.secrets_config" ]; then
        ln -sf "$.devcontainer.secrets_config" "$home_config"
        echo "✅ Database configuration restored"
        return 0
    fi
    return 1
}

# Handle --verify flag
if [ "${1:-}" = "--verify" ]; then
    verify_database_config
    exit $?
fi

# Interactive configuration
main() {
    echo "🔧 Database Connection Configuration"
    echo ""

    # Check if already configured
    if eval "$CHECK_CONFIGURED_COMMAND"; then
        echo "⚠️  Configuration already exists"
        read -p "Reconfigure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration"
            exit 0
        fi
    fi

    # Prompt for values
    echo "Enter database connection details:"
    read -p "Host: " DB_HOST
    read -p "Port: " DB_PORT
    read -p "Database: " DB_NAME
    read -p "Username: " DB_USER
    read -s -p "Password: " DB_PASS
    echo ""

    # Validate
    if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ]; then
        echo "❌ Host and database name are required"
        exit 1
    fi

    # Save to .devcontainer.secrets first
    local .devcontainer.secrets_config="/workspace/.devcontainer.secrets/database-config"
    cat > "$.devcontainer.secrets_config" <<EOF
DB_HOST=$DB_HOST
DB_PORT=${DB_PORT:-5432}
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS
EOF
    chmod 600 "$.devcontainer.secrets_config"

    # Create symlink from home
    ln -sf "$.devcontainer.secrets_config" "$HOME/.database-config"

    echo ""
    echo "✅ Database configuration saved!"
    echo "   Config: $HOME/.database-config"
    echo "   Persists: /workspace/.devcontainer.secrets/database-config"
}

main "$@"
```

---

## Common Patterns

### Pattern 1: Version-Pinned Installation

```bash
TOOL_VERSION="1.2.3"

install_tool() {
    echo "📦 Installing tool v${TOOL_VERSION}..."
    curl -L "https://example.com/releases/v${TOOL_VERSION}/tool.tar.gz" -o tool.tar.gz
    tar xzf tool.tar.gz
    sudo mv tool /usr/local/bin/
    rm tool.tar.gz
}
```

### Pattern 2: Architecture Detection

```bash
install_tool() {
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    echo "📦 Installing tool for ${ARCH}..."
    curl -L "https://example.com/tool-${ARCH}" -o tool
    sudo install tool /usr/local/bin/
}
```

### Pattern 3: Conditional Installation

```bash
install_optional_components() {
    # Install base tool (required)
    install_base_tool

    # Install optional components
    read -p "Install optional plugins? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_plugins
    fi
}
```

### Pattern 4: Multiple Config Files

```bash
verify_myapp_config() {
    local main_config="/workspace/.devcontainer.secrets/myapp-config"
    local credentials="/workspace/.devcontainer.secrets/myapp-credentials"

    local restored=0

    # Restore main config
    if [ -f "$main_config" ]; then
        ln -sf "$main_config" "$HOME/.myapp/config"
        ((restored++))
    fi

    # Restore credentials
    if [ -f "$credentials" ]; then
        ln -sf "$credentials" "$HOME/.myapp/credentials"
        ((restored++))
    fi

    # Success if at least one restored
    if [ $restored -gt 0 ]; then
        echo "✅ My App configuration restored"
        return 0
    fi
    return 1
}
```

---

## Troubleshooting

### Script Not Discovered

**Problem:** Script doesn't appear in dev-setup menu

**Solutions:**
1. Check metadata fields are defined at top of script
2. Verify script name follows convention (`install-*.sh` or `config-*.sh`)
3. Ensure script has execute permissions: `chmod +x script.sh`
4. Test discovery manually:
   ```bash
   source /workspace/.devcontainer/additions/lib/component-scanner.sh
   scan_install_scripts /workspace/.devcontainer/additions | grep yourscript
   ```

### CHECK_INSTALLED_COMMAND Fails

**Problem:** Script always tries to reinstall even though tool is installed

**Solutions:**
1. Test command manually: `command -v tool >/dev/null 2>&1 && echo "found"`
2. Check installation location vs PATH
3. Add OR condition: `[ -f /path/to/tool ] || command -v tool >/dev/null 2>&1`
4. Verify command returns exit code 0 when installed, 1 when not

### Prerequisites Not Working

**Problem:** Tool installs even though prerequisite missing

**Solutions:**
1. Check PREREQUISITE_CONFIGS spelling (exact filename)
2. Verify config script has CHECK_CONFIGURED_COMMAND field
3. Test prerequisite check manually:
   ```bash
   source /workspace/.devcontainer/additions/lib/prerequisite-check.sh
   check_prerequisite_config "config-mytool.sh" "/workspace/.devcontainer/additions"
   echo $?  # Should be 0 if configured, 1 if not
   ```

### --verify Not Working

**Problem:** Config script not restored by restore_all_configurations()

**Solutions:**
1. Ensure script has `if [ "${1:-}" = "--verify" ]` handler
2. Verify handler calls verify function and exits: `verify_func; exit $?`
3. Test manually: `bash config-script.sh --verify; echo $?`
4. Check pattern detection: `grep -q '= "--verify"' config-script.sh`

---

## Next Steps

1. **Copy appropriate template** to `/workspace/.devcontainer/additions/`
2. **Customize metadata** fields for your tool/config
3. **Implement core functions** (install/verify or configure/restore)
4. **Test thoroughly** (success, failure, idempotency)
5. **Add to enabled-tools.conf** or test in dev-setup menu
6. **Document any special requirements** in comments

---

## Additional Resources

- **Main Documentation:** `/workspace/.devcontainer/additions/README-additions.md`
- **Component Scanner Library:** `/workspace/.devcontainer/additions/lib/component-scanner.sh`
- **Prerequisite Check Library:** `/workspace/.devcontainer/additions/lib/prerequisite-check.sh`
- **Auto-Enable Library:** `/workspace/.devcontainer/additions/lib/tool-auto-enable.sh`
- **Working Examples:**
  - `install-srv-otel-monitoring.sh` - Complex install with prerequisites
  - `config-devcontainer-identity.sh` - Config with --verify support
  - `install-dev-python.sh` - Standard development tools installation

---

**Happy scripting! 🚀**
