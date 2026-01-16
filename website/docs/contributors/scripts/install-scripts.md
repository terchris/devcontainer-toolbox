---
title: Creating Install Scripts
sidebar_position: 1
---

# Creating Install Scripts

Complete guide to creating `install-*.sh` scripts that add new tools to devcontainer-toolbox.

---

## Quick Start

```bash
# 1. Copy the template
cp /workspace/.devcontainer/additions/addition-templates/_template-install-script.sh \
   /workspace/.devcontainer/additions/install-mytool.sh

# 2. Edit the metadata section (SCRIPT_NAME, SCRIPT_CATEGORY, etc.)

# 3. Implement your installation logic

# 4. Test the script
bash /workspace/.devcontainer/additions/install-mytool.sh

# 5. Enable in project
echo "mytool" >> /workspace/.devcontainer.extend/enabled-tools.conf
```

---

## Script Types

### Installation Scripts (`install-*.sh`)

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

### Configuration Scripts (`config-*.sh`)

**Purpose:** Configure user settings, credentials, identities, or environment

**Naming:** `config-<setting-name>.sh`

**Characteristics:**
- Interactive (prompts user for input)
- Supports `--verify` flag for automatic restoration
- Stores configs in `/workspace/.devcontainer.secrets` for persistence
- Idempotent (safe to reconfigure)

### Command Scripts (`cmd-*.sh`)

**Purpose:** Provide multiple related commands for managing resources

**Naming:** `cmd-<purpose>.sh`

**Characteristics:**
- Non-interactive (flag-based interface)
- Multiple commands via SCRIPT_COMMANDS array
- Help text auto-generated

---

## Metadata Fields Reference

### Core Fields (Required)

These fields are used by `dev-setup.sh` for the terminal-based installer:

| Field | Description | Example |
|-------|-------------|---------|
| `SCRIPT_ID` | Unique identifier | `"dev-python"` |
| `SCRIPT_VER` | Version number | `"1.0.0"` |
| `SCRIPT_NAME` | Human-readable name (2-4 words) | `"Python Development Tools"` |
| `SCRIPT_DESCRIPTION` | Brief description (one sentence) | `"Install Python 3.11 and pip"` |
| `SCRIPT_CATEGORY` | Category for menu organization | `"LANGUAGE_DEV"` |
| `SCRIPT_CHECK_COMMAND` | Command to check if installed | `"command -v python3 >/dev/null 2>&1"` |

### Core Fields (Optional)

| Field | Description | Example |
|-------|-------------|---------|
| `SCRIPT_PREREQUISITES` | Space-separated config scripts | `"config-aws-credentials.sh"` |

### Extended Fields (Website Only)

These fields are for the **documentation website only** and enable richer tool pages:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `SCRIPT_TAGS` | Yes | Search keywords (space-separated) | `"python pip venv development"` |
| `SCRIPT_ABSTRACT` | Yes | Brief description (50-150 chars) | `"Full Python development environment..."` |
| `SCRIPT_LOGO` | No | Logo filename | `"dev-python-logo.webp"` |
| `SCRIPT_WEBSITE` | No | Official tool URL | `"https://python.org"` |
| `SCRIPT_SUMMARY` | No | Detailed description (150-500 chars) | `"Complete Python development setup..."` |
| `SCRIPT_RELATED` | No | Related tool IDs (space-separated) | `"dev-data-analytics dev-ai"` |

**Logo files:** Place source images in `website/static/img/tools/src/`. They are automatically processed to 512x512 WebP during deployment.

### Valid Categories

- `LANGUAGE_DEV` - Development tools and runtimes
- `INFRA_CONFIG` - Infrastructure configuration
- `AI_TOOLS` - AI and machine learning tools
- `CLOUD_TOOLS` - Cloud provider CLIs
- `DATA_ANALYTICS` - Data analysis tools
- `BACKGROUND_SERVICES` - Background services and daemons
- `CONTRIBUTOR_TOOLS` - Tools for contributors
- `SYSTEM_COMMANDS` - DevContainer management commands

---

## The Two-Layer System

The devcontainer uses a two-layer approach for managing configurations:

### Layer 1: Silent Config Restoration

**When:** Runs BEFORE tool installation

**Behavior:**
- Discovers ALL `config-*.sh` scripts automatically
- Runs each with `--verify` flag
- Shows ✅ for successful restorations
- **SILENT for missing configs** (no warnings)

### Layer 2: Loud Tool Prerequisites

**When:** Runs DURING tool installation for ENABLED tools

**Behavior:**
- Checks `SCRIPT_PREREQUISITES` field for each enabled tool
- Shows ⚠️ error if REQUIRED config missing
- **Blocks installation** until prerequisites met

### Why Two Layers?

**Problem:** Warning about every missing config is noisy:
```bash
⚠️  Tailscale: not found  ← User doesn't use Tailscale
⚠️  kubectl: not found    ← User doesn't use kubectl
```

**Solution:**
- Layer 1: Silent restoration = no noise for configs user doesn't need
- Layer 2: Loud prerequisites = clear error for configs user DOES need

---

## Prerequisites Pattern

### When to Use Prerequisites

Add `SCRIPT_PREREQUISITES` when your tool requires:
- User credentials (AWS keys, API tokens)
- Identity/authentication
- Configuration files

### How to Declare

```bash
# Single prerequisite
SCRIPT_PREREQUISITES="config-aws-credentials.sh"

# Multiple prerequisites
SCRIPT_PREREQUISITES="config-devcontainer-identity.sh config-aws-credentials.sh"
```

### Prerequisites Are Checked Automatically

You don't need to write code to check prerequisites! Just add metadata:

```bash
# DON'T DO THIS (old way):
check_aws_credentials() {
    if [ ! -f ~/.aws/credentials ]; then
        echo "ERROR: AWS credentials not configured"
        exit 1
    fi
}

# DO THIS (new way):
SCRIPT_PREREQUISITES="config-aws-credentials.sh"
# That's it! The system handles checking.
```

---

## Best Practices

### General

1. **Start with the template** - Don't write from scratch
2. **Test both success and failure paths**
3. **Be idempotent** - Safe to run multiple times
4. **Use logging library** - Automatic logging to /tmp/devcontainer-install/
5. **Follow naming conventions** - `install-*.sh`

### Install Scripts

1. **Check before install** - Use SCRIPT_CHECK_COMMAND to skip if already installed
2. **Check installation location OR PATH** - Better UX even before shell restart
   ```bash
   # Good - checks both location and PATH
   SCRIPT_CHECK_COMMAND="[ -f /usr/local/bin/tool ] || command -v tool >/dev/null 2>&1"
   ```
3. **Verify after install** - Confirm tool is accessible
4. **Clean up on failure** - Remove partial installations
5. **Use version variables** - Make updates easier
6. **Test uninstall** - Implement --uninstall flag

### Error Handling

1. **Use set -euo pipefail** - Fail fast on errors
2. **Provide clear error messages**
3. **Exit with appropriate codes** - 0 = success, 1 = failure

---

## Examples

### Simple Tool Installation

```bash
#!/bin/bash
# File: install-jq.sh

# --- Core metadata (required) ---
SCRIPT_ID="dev-jq"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="jq JSON Processor"
SCRIPT_DESCRIPTION="Install jq command-line JSON processor"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command -v jq >/dev/null 2>&1"

# --- Extended metadata (for website) ---
SCRIPT_TAGS="jq json processor cli query"
SCRIPT_ABSTRACT="Command-line JSON processor for parsing and transforming JSON data."
SCRIPT_LOGO="dev-jq-logo.webp"
SCRIPT_WEBSITE="https://jqlang.github.io/jq/"
SCRIPT_SUMMARY="Lightweight command-line JSON processor. Parse, filter, and transform JSON data with a powerful expression syntax. Essential tool for working with APIs and configuration files."
SCRIPT_RELATED="dev-python dev-typescript"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"
source "${SCRIPT_DIR}/lib/logging.sh"

install_jq() {
    echo "📦 Installing jq..."
    sudo apt-get update
    sudo apt-get install -y jq
    echo "✅ jq installed successfully"
}

main() {
    if eval "$SCRIPT_CHECK_COMMAND"; then
        echo "✅ jq is already installed"
        exit 0
    fi

    install_jq
    tool_auto_enable "$SCRIPT_NAME"
    echo "🎉 Installation complete!"
}

main "$@"
```

### Tool with Prerequisites

```bash
#!/bin/bash
# File: install-aws-cli.sh

# --- Core metadata (required) ---
SCRIPT_ID="cloud-aws"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="AWS CLI"
SCRIPT_DESCRIPTION="Install AWS Command Line Interface"
SCRIPT_CATEGORY="CLOUD_TOOLS"
SCRIPT_CHECK_COMMAND="command -v aws >/dev/null 2>&1"
SCRIPT_PREREQUISITES="config-aws-credentials.sh"  # Requires AWS credentials

# --- Extended metadata (for website) ---
SCRIPT_TAGS="aws amazon cloud cli s3 ec2 lambda"
SCRIPT_ABSTRACT="AWS Command Line Interface for managing Amazon Web Services."
SCRIPT_LOGO="cloud-aws-logo.webp"
SCRIPT_WEBSITE="https://aws.amazon.com/cli/"
SCRIPT_SUMMARY="Official AWS CLI for interacting with Amazon Web Services. Manage S3, EC2, Lambda, and 200+ AWS services from the command line. Supports profiles, MFA, and SSO authentication."
SCRIPT_RELATED="cloud-azure cloud-terraform"

# ... installation logic ...
# Prerequisites are checked automatically!
```

---

## Testing Your Script

### 1. Test Installation

```bash
# Test initial installation
bash /workspace/.devcontainer/additions/install-mytool.sh

# Verify it installed correctly
which mytool
mytool --version

# Test idempotency (should skip, not re-install)
bash /workspace/.devcontainer/additions/install-mytool.sh
```

### 2. Test Discovery

```bash
source /workspace/.devcontainer/additions/lib/component-scanner.sh
scan_install_scripts /workspace/.devcontainer/additions | grep mytool
```

### 3. Test in dev-setup Menu

```bash
dev-setup
# Navigate to your tool's category
# Verify it appears with correct name and description
```

---

## Common Patterns

### Version-Pinned Installation

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

### Architecture Detection

```bash
install_tool() {
    local ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    curl -L "https://example.com/tool-${ARCH}" -o tool
    sudo install tool /usr/local/bin/
}
```

---

## Troubleshooting

### Script Not Discovered

1. Check metadata fields are defined at top of script
2. Verify script name follows convention (`install-*.sh`)
3. Ensure script has execute permissions: `chmod +x script.sh`

### CHECK_INSTALLED_COMMAND Fails

1. Test command manually: `command -v tool >/dev/null 2>&1 && echo "found"`
2. Add OR condition: `[ -f /path/to/tool ] || command -v tool >/dev/null 2>&1`

### Prerequisites Not Working

1. Check SCRIPT_PREREQUISITES spelling (exact filename)
2. Verify config script has CHECK_CONFIGURED_COMMAND field

---

## See Also

- [Architecture](../architecture) - System architecture
- [Libraries Reference](../architecture/libraries) - Shared functions
- [Testing](../testing) - Test your scripts
