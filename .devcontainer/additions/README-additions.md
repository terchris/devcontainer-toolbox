# Devcontainer Additions System

This folder contains a modular system for installing tools, configuring settings, and managing services in your devcontainer. The system uses automatic script discovery and provides a unified menu interface for easy management.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Script Types](#script-types)
- [Using the Menu System](#using-the-menu-system)
- [Script Discovery and Metadata](#script-discovery-and-metadata)
- [Creating New Scripts](#creating-new-scripts)
- [Project Integration](#project-integration)
- [Directory Structure](#directory-structure)

---

## Overview

The additions system provides:

- **Automatic Script Discovery**: Scripts are automatically detected and listed in the menu based on metadata
- **Three Script Types**: Install components, configure settings, manage services
- **Status Indicators**: Visual status (✓/✗) shows what's installed, configured, or running
- **Category Organization**: Scripts are organized by category (DEV_TOOLS, INFRA_CONFIG, AI_TOOLS, etc.)
- **Menu Interface**: Interactive menu via `dev-setup.sh` for easy management
- **Project Integration**: Easily add scripts to your project's automated setup

---

## Quick Start

### Using the Interactive Menu

The easiest way to manage additions is through the interactive menu:

```bash
dev-setup
```

This displays all available components, configurations, and services with their current status.

### Running Scripts Directly

You can also run scripts directly from the command line:

```bash
# Install a component
bash .devcontainer/additions/install-dev-python.sh

# Configure a setting
bash .devcontainer/additions/config-devcontainer-identity.sh

# Start a service
bash .devcontainer/additions/start-otel-monitoring.sh

# Stop a service
bash .devcontainer/additions/stop-otel-monitoring.sh
```

---

## Script Types

The additions system supports three types of scripts, each with specific naming conventions and purposes:

### 1. Install Scripts (`install-*.sh`)

Install components, tools, or dependencies.

**Naming Pattern**: `install-<component-name>.sh`

**Examples**:
- `install-dev-python.sh` - Python development tools
- `install-dev-golang.sh` - Go development environment
- `install-kubectl.sh` - Kubernetes CLI tools
- `install-srv-otel-monitoring.sh` - OpenTelemetry monitoring

**Key Features**:
- Idempotent (safe to run multiple times)
- Status check command to detect if already installed
- Optional uninstall support via `--uninstall` flag
- Category-based organization

**Required Metadata**:
```bash
SCRIPT_NAME="Human-readable component name"
SCRIPT_DESCRIPTION="Brief description of what this installs"
SCRIPT_CATEGORY="DEV_TOOLS"  # or INFRA_CONFIG, AI_TOOLS, etc.
CHECK_INSTALLED_COMMAND="command -v python3 >/dev/null 2>&1"
```

### 2. Configuration Scripts (`config-*.sh`)

Configure settings, credentials, or environment variables.

**Naming Pattern**: `config-<setting-name>.sh`

**Examples**:
- `config-devcontainer-identity.sh` - Developer identity for monitoring

**Key Features**:
- Interactive configuration prompts
- Status check to detect if already configured
- Validation and verification
- Reconfiguration support

**Required Metadata**:
```bash
CONFIG_NAME="Human-readable configuration name"
CONFIG_DESCRIPTION="Brief description of what this configures"
CONFIG_CATEGORY="INFRA_CONFIG"  # or USER_CONFIG, etc.
CHECK_CONFIGURED_COMMAND="[ -f ~/.devcontainer-identity ] && grep -q '^export DEVELOPER_ID=' ~/.devcontainer-identity"
```

### 3. Service Scripts (`start-*.sh` and `stop-*.sh`)

Start and stop background services or daemons.

**Naming Pattern**: `start-<service-name>.sh` and `stop-<service-name>.sh`

**Examples**:
- `start-otel-monitoring.sh` / `stop-otel-monitoring.sh` - OpenTelemetry monitoring services

**Key Features**:
- Paired start/stop scripts
- Status check to detect if service is running
- Graceful shutdown support
- Service lifecycle management

**Required Metadata** (in `start-*.sh`):
```bash
SERVICE_NAME="Human-readable service name"
SERVICE_DESCRIPTION="Brief description of what this service does"
SERVICE_CATEGORY="INFRA_CONFIG"  # or MONITORING, DATABASE, etc.
CHECK_RUNNING_COMMAND="pgrep -f 'otelcol-contrib.*config' >/dev/null 2>&1"
```

**Optional Metadata** (in `stop-*.sh`):
```bash
SERVICE_NAME="Human-readable service name"
SERVICE_DESCRIPTION="Brief description"
SERVICE_CATEGORY="INFRA_CONFIG"
```

---

## Automatic Logging

All install and config scripts automatically log their output to timestamped files in `/tmp/devcontainer-install/`. This provides a complete audit trail of what was installed, when, and any errors that occurred.

### Log File Location

```
/tmp/devcontainer-install/
  install-dev-golang-20251118-124020.log
  install-dev-java-20251118-124145.log
  install-dev-rust-20251118-124302.log
  config-git-user-20251118-124430.log
  ...
```

### Log File Naming

Log files follow this pattern:
```
<script-name>-<YYYYMMDD>-<HHMMSS>.log
```

**Examples:**
- `install-dev-golang-20251118-124020.log` - Go installation run at 12:40:20
- `install-dev-python-20251118-131545.log` - Python installation run at 13:15:45
- `config-git-user-20251118-094520.log` - Git config run at 09:45:20

### Logging Behavior

**Automatic Logging:**
- All scripts that source the logging library automatically log their output
- Output appears on terminal in real-time (no change in behavior)
- Output is simultaneously written to log file using `tee`
- Log location is displayed at script startup

**What Gets Logged:**
- All terminal output (stdout and stderr)
- Installation progress and status messages
- Error messages and warnings
- Command output and results
- Emojis and formatting (preserved exactly as shown on terminal)

### Using the Logging Library

The logging library is automatically included in all scripts created from templates. For existing scripts:

```bash
# Source logging library (add after other library sources)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"  
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/lib/logging.sh"
```

Once sourced, all script output is automatically logged. No code changes needed.

### Viewing Logs

```bash
# List all log files
ls -lht /tmp/devcontainer-install/

# View a specific log
cat /tmp/devcontainer-install/install-dev-golang-20251118-124020.log

# View the most recent log for a script
ls -t /tmp/devcontainer-install/install-dev-golang-*.log | head -1 | xargs cat

# Search logs for errors
grep -i error /tmp/devcontainer-install/*.log

# View logs from today
find /tmp/devcontainer-install -name "*.log" -mtime 0
```

### Log Cleanup

Logs are stored in `/tmp/` which means:
- They persist during the container session
- They are cleared when the container is stopped/rebuilt
- They don't accumulate in the git repository
- They don't consume disk space long-term

To manually clean up old logs:
```bash
# Remove logs older than 7 days
find /tmp/devcontainer-install -name "*.log" -mtime +7 -delete

# Remove all logs
rm -rf /tmp/devcontainer-install/*.log
```

### Benefits

**For Development:**
- Complete audit trail of what was installed
- Easy troubleshooting when installations fail
- Can review logs after container rebuild completes
- Compare logs across multiple installation runs

**For Support:**
- Team members can share log files when asking for help
- Clear record of exactly what happened during installation
- Timestamps help correlate issues with system events

**For Automation:**
- Log files can be parsed for CI/CD reporting
- Installation duration can be tracked
- Failure patterns can be identified

---

## Using the Menu System

The menu system (`dev-setup.sh`) provides an interactive interface for managing all additions.

### Menu Features

- **Automatic Discovery**: All scripts with proper metadata are automatically detected
- **Status Indicators**:
  - `✓` (green checkmark) - Component installed / Config completed / Service running
  - `✗` (red X) - Component not installed / Config not completed / Service not running
- **Category Organization**: Scripts grouped by category
- **One-click Execution**: Select and run scripts directly from the menu

### Status Checks

The menu system uses the check commands defined in each script's metadata:

```bash
# For install scripts
CHECK_INSTALLED_COMMAND="command -v python3 >/dev/null 2>&1"

# For config scripts
CHECK_CONFIGURED_COMMAND="[ -f ~/.config-file ]"

# For service scripts
CHECK_RUNNING_COMMAND="pgrep -f 'service-name' >/dev/null 2>&1"
```

These commands are evaluated by the component scanner library to determine status.

---

## Script Discovery and Metadata

### Component Scanner Library

The additions system uses a shared library for script discovery:

**Location**: `.devcontainer/additions/lib/component-scanner.sh` (v1.1.0)

**Key Functions**:
- `scan_install_scripts()` - Find and extract metadata from install scripts
- `scan_config_scripts()` - Find and extract metadata from config scripts
- `scan_service_scripts()` - Find and extract metadata from service scripts
- `check_component_installed()` - Execute status check commands
- `check_config_configured()` - Verify configuration status
- `extract_*_metadata()` - Extract individual metadata fields

### Metadata Format

All metadata must be defined at the top of each script (within the first ~50 lines) using this exact format:

```bash
#!/bin/bash
# file: .devcontainer/additions/install-example.sh
#
# DESCRIPTION: Brief description
# PURPOSE: Detailed purpose
#
# Usage: ./install-example.sh
#
#------------------------------------------------------------------------------
# SCRIPT METADATA - For dev-setup.sh menu discovery
#------------------------------------------------------------------------------

SCRIPT_NAME="Example Component"
SCRIPT_DESCRIPTION="Install example component with all dependencies"
SCRIPT_CATEGORY="DEV_TOOLS"
CHECK_INSTALLED_COMMAND="command -v example >/dev/null 2>&1"

#------------------------------------------------------------------------------

# Rest of script...
```

### Category Naming

Use consistent category names across scripts:

**Common Categories**:
- `DEV_TOOLS` - Development tools and language runtimes
- `INFRA_CONFIG` - Infrastructure and configuration
- `AI_TOOLS` - AI coding assistants and tools
- `MONITORING` - Monitoring and observability
- `DATABASE` - Database tools and clients
- `CLOUD` - Cloud provider CLI tools

You can define custom categories as needed.

### Check Command Guidelines

Check commands should:
- Return exit code `0` if installed/configured/running
- Return exit code `1` if not installed/configured/running
- Suppress all output (`>/dev/null 2>&1`)
- Be fast (run in < 1 second)
- Be idempotent (safe to run repeatedly)

**Good Examples**:
```bash
# Check if command exists
CHECK_INSTALLED_COMMAND="command -v python3 >/dev/null 2>&1"

# Check if file exists and contains content
CHECK_CONFIGURED_COMMAND="[ -f ~/.config ] && grep -q 'key=value' ~/.config"

# Check if process is running
CHECK_RUNNING_COMMAND="pgrep -f 'service-name' >/dev/null 2>&1"

# Check if package is installed (Debian/Ubuntu)
CHECK_INSTALLED_COMMAND="dpkg -l package-name 2>/dev/null | grep -q '^ii'"

# Check if directory exists
CHECK_INSTALLED_COMMAND="[ -d /opt/tool ]"

# Complex check with multiple conditions
CHECK_INSTALLED_COMMAND="[ -f /usr/bin/tool ] && tool --version >/dev/null 2>&1"
```

**Bad Examples**:
```bash
# Don't use variable substitution (not evaluated at scan time)
CHECK_INSTALLED_COMMAND="command -v $TOOL_NAME >/dev/null 2>&1"  # WRONG

# Don't output text (breaks menu display)
CHECK_INSTALLED_COMMAND="echo 'Checking...'; command -v python3"  # WRONG

# Don't use slow commands (delays menu)
CHECK_INSTALLED_COMMAND="apt-cache policy python3 | grep Installed"  # TOO SLOW
```

---

## Creating New Scripts

**For detailed instructions on creating new scripts, see:**

📖 **[Addition Script Templates Guide](./addition-templates/README-additions-template.md)**

This comprehensive guide includes:
- Complete templates for install and config scripts
- Step-by-step creation instructions
- Metadata fields reference
- Two-layer system explanation (silent restoration, loud prerequisites)
- Prerequisites pattern (PREREQUISITE_CONFIGS)
- Best practices and testing guidelines
- Working examples and common patterns
- Troubleshooting guide

### Quick Start

**1. Read the comprehensive guide:**
```bash
cat /workspace/.devcontainer/additions/addition-templates/README-additions-template.md
```

**2. Copy the appropriate template:**
```bash
# For install scripts
cp /workspace/.devcontainer/additions/addition-templates/_template-install-script.sh \
   /workspace/.devcontainer/additions/install-my-tool.sh

# For config scripts
cp /workspace/.devcontainer/additions/addition-templates/_template-config-script.sh \
   /workspace/.devcontainer/additions/config-my-tool.sh
```

**3. Follow the inline documentation in the template**

**4. Test and enable your script**

### Template Location

All templates and creation documentation are located in:
```
/workspace/.devcontainer/additions/addition-templates/
├── README-additions-template.md     # Complete developer guide
├── _template-install-script.sh      # Template for install scripts
├── _template-config-script.sh       # Template for config scripts
└── tests/                           # Automated test suite
    ├── README-tests.md              # Test documentation
    ├── run-unit-tests.sh            # Automated unit test runner
    └── test-plan.md                 # Complete test plan
```

**Note:** Detailed examples, patterns, and complete implementation guides are in the template documentation. This keeps the main README focused on using the system, while the template guide focuses on creating new scripts.

### Verify System Health

Before creating new scripts, verify the core systems work correctly:

```bash
bash /workspace/.devcontainer/additions/addition-templates/tests/run-unit-tests.sh
```

See [tests/README-tests.md](./addition-templates/tests/README-tests.md) for details.

---

## Project Integration

### Adding to Project-Specific Setup

To ensure team members have the same tools installed, add scripts to your project's automated setup:

**File**: `.devcontainer.extend/project-installs.sh`

```bash
#!/bin/bash
# Project-specific installations
# This script runs automatically when the container is rebuilt

set -euo pipefail

echo "Installing project dependencies..."

# Install required development tools
bash .devcontainer/additions/install-dev-python.sh
bash .devcontainer/additions/install-dev-typescript.sh

# Install project-specific tools
bash .devcontainer/additions/install-kubectl.sh

# Configure monitoring (optional)
if [ -f ~/.devcontainer-identity ]; then
    bash .devcontainer/additions/start-otel-monitoring.sh
fi

echo "✓ Project dependencies installed"
```

**Benefits**:
- New team members get a consistent development environment
- Reduces onboarding time
- Documents project dependencies as code
- Runs automatically on container rebuild

**See Also**: [.devcontainer.extend/readme-devcontainer-extend.md](../../.devcontainer.extend/readme-devcontainer-extend.md)

---

## Directory Structure

```
.devcontainer/additions/
│
├── README-additions.md              # This file - How to USE the additions system
│
├── addition-templates/              # Templates and creation guide
│   ├── README-additions-template.md # Complete guide for CREATING new scripts
│   ├── _template-install-script.sh  # Template for install scripts
│   └── _template-config-script.sh   # Template for config scripts
│
├── lib/                             # Shared libraries
│   ├── component-scanner.sh         # Script discovery library
│   ├── prerequisite-check.sh        # Prerequisite checking library
│   ├── logging.sh                   # Automatic logging library
│   └── tool-auto-enable.sh          # Auto-enable library
│
├── install-*.sh                     # Install scripts (components/tools)
│   ├── install-dev-python.sh
│   ├── install-dev-golang.sh
│   ├── install-kubectl.sh
│   └── install-srv-otel-monitoring.sh
│
├── config-*.sh                      # Configuration scripts
│   └── config-devcontainer-identity.sh
│
├── start-*.sh / stop-*.sh           # Service management scripts
│   ├── start-otel-monitoring.sh
│   └── stop-otel-monitoring.sh
│
└── otel/                            # OTel monitoring system
    ├── README-otel.md               # OTel-specific documentation
    ├── otelcol-config.yaml          # OTel collector configuration
    ├── otelcol-metrics-config.yaml  # Metrics collector configuration
    ├── script-exporter-config.yaml  # Script exporter configuration
    │
    ├── adm/                         # Admin tools (not visible in menu)
    │   └── generate-devcontainer-identity.sh
    │
    └── scripts/                     # OTel helper scripts
        └── send-event-notification.sh
```

---

## Best Practices

### Script Development

1. **Use Templates**: Start with the provided templates in `addition-templates/` for consistency
2. **Read the Creation Guide**: See [addition-templates/README-additions-template.md](./addition-templates/README-additions-template.md) for complete instructions
3. **Add Metadata**: Always include complete metadata for menu discovery
4. **Include Logging**: Ensure scripts source the logging library for audit trails
5. **Test Check Commands**: Verify check commands work correctly before and after installation
6. **Handle Errors**: Use `set -euo pipefail` and provide clear error messages
7. **Be Idempotent**: Scripts should be safe to run multiple times
8. **Provide Feedback**: Use clear output messages for user feedback
9. **Document Usage**: Include usage examples in script header comments

### Naming Conventions

1. **Install Scripts**: `install-<category>-<name>.sh`
   - Examples: `install-dev-python.sh`, `install-cloud-aws-cli.sh`
2. **Config Scripts**: `config-<setting>.sh`
   - Examples: `config-git-user.sh`, `config-devcontainer-identity.sh`
3. **Service Scripts**: `start-<service>.sh` / `stop-<service>.sh`
   - Examples: `start-otel-monitoring.sh`, `stop-database.sh`

### Metadata Guidelines

1. **Keep Names Concise**: 2-4 words maximum for SCRIPT_NAME
2. **Write Clear Descriptions**: One sentence explaining what the script does
3. **Use Standard Categories**: Stick to common category names for consistency
4. **Test Check Commands**: Verify they work in different states (installed/not installed)

---

## Troubleshooting

### Script Not Appearing in Menu

**Possible Causes**:
1. Missing or incorrect metadata fields
2. Script doesn't match naming pattern (`install-*.sh`, `config-*.sh`, `start-*.sh`)
3. Metadata not in first ~50 lines of script
4. Template file (contains `_template` in name)

**Solution**:
- Verify all required metadata fields are present
- Check exact spelling: `SCRIPT_NAME=` (not `SCRIPTNAME=` or `script_name=`)
- Move metadata section to top of file
- Ensure script name matches pattern

### Status Indicator Shows Wrong State

**Possible Causes**:
1. Check command doesn't accurately reflect state
2. Check command has syntax errors
3. Check command is too slow or hangs

**Solution**:
- Test check command manually: `eval "command -v python3 >/dev/null 2>&1" && echo "✓" || echo "✗"`
- Verify check command returns correct exit codes (0 = true, 1 = false)
- Simplify complex check commands
- Add timeout to slow commands

### Script Fails During Execution

**Possible Causes**:
1. Missing dependencies
2. Permission issues
3. Network connectivity problems
4. Incorrect paths

**Solution**:
- Check error messages carefully
- Verify prerequisites are installed
- Test commands individually
- Use absolute paths instead of relative paths

---

## Advanced Topics

### Creating Custom Categories

You can define custom categories for your organization:

```bash
# Enterprise categories
SCRIPT_CATEGORY="COMPANY_TOOLS"      # Company-specific tools
SCRIPT_CATEGORY="SECURITY_TOOLS"     # Security scanning tools
SCRIPT_CATEGORY="COMPLIANCE"         # Compliance and audit tools
```

### Uninstall Support

Add uninstall support to install scripts:

```bash
# Parse command-line arguments
UNINSTALL_MODE=0
if [ "${1:-}" = "--uninstall" ]; then
    UNINSTALL_MODE=1
fi

# Implement uninstall function
uninstall() {
    echo "Uninstalling component..."
    sudo apt-get remove -y package-name
    sudo apt-get autoremove -y
    echo "✓ Uninstall complete"
}

# Main execution
if [ $UNINSTALL_MODE -eq 1 ]; then
    uninstall
else
    install
fi
```

### Silent Mode

Support silent/non-interactive mode:

```bash
# Check for silent mode flag
SILENT_MODE=${SILENT_MODE:-0}
if [ "${1:-}" = "--silent" ]; then
    SILENT_MODE=1
fi

# Skip prompts in silent mode
if [ $SILENT_MODE -eq 0 ]; then
    read -p "Continue? (Y/n): " -n 1 -r
    echo
fi
```

---

## Related Documentation

- [Nginx Reverse Proxy](nginx/README-nginx.md) - Network architecture and proxy configuration for cluster services
- [OTel Monitoring System](otel/README-otel.md) - OpenTelemetry monitoring documentation
- [Devcontainer Extend](../../.devcontainer.extend/readme-devcontainer-extend.md) - Project-specific customization
- [Component Scanner Library](lib/component-scanner.sh) - Script discovery library documentation

---

## Support

For questions or issues:

1. Check script comments and inline documentation
2. Review examples in existing scripts
3. Test changes in a clean container
4. Consult related documentation above

---

**Last Updated**: 2025-11-18
**Component Scanner Version**: 1.1.0
**Logging Library**: Enabled
