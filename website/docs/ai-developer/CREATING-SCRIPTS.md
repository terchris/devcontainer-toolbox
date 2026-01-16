# Creating Scripts - AI Developer Guide

Quick reference for AI assistants creating new tools and services in devcontainer-toolbox.

---

## Script Types

| Type | Pattern | Purpose |
|------|---------|---------|
| Install | `install-*.sh` | Install tools, runtimes, CLIs |
| Config | `config-*.sh` | Configure settings, credentials |
| Service | `service-*.sh` | Manage background services |
| Command | `cmd-*.sh` | Multi-command utilities |

---

## Essential Documentation

Read these before creating scripts:

| Document | Content |
|----------|---------|
| [Creating Install Scripts](../contributors/scripts/install-scripts) | Complete guide for install/config/cmd scripts |
| [Services Overview](../contributors/services) | Service scripts documentation |
| [Libraries Reference](../contributors/architecture/libraries) | Library functions reference |
| [Categories Reference](../contributors/architecture/categories) | Valid category values |

---

## Required Metadata (Core)

Every script MUST have these metadata fields at the top (used by `dev-setup.sh`):

```bash
SCRIPT_ID="unique-identifier"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="Human Readable Name"
SCRIPT_DESCRIPTION="What this script does"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command --version"
```

---

## Extended Metadata (Website)

These fields are for the **website only** and enable richer documentation. They are NOT used by the terminal-based installer.

```bash
# --- Extended metadata (for website) ---
# Required:
SCRIPT_TAGS="keyword1 keyword2 keyword3"
SCRIPT_ABSTRACT="Brief 1-2 sentence description (50-150 chars)"

# Optional:
SCRIPT_LOGO="tool-name-logo.webp"
SCRIPT_WEBSITE="https://official-website.com"
SCRIPT_SUMMARY="Detailed description covering features, use cases, and benefits (150-500 chars)"
SCRIPT_RELATED="related-tool-id-1 related-tool-id-2"
```

| Field | Required | Purpose | Guidelines |
|-------|----------|---------|------------|
| `SCRIPT_TAGS` | Yes | Search keywords | Space-separated, lowercase |
| `SCRIPT_ABSTRACT` | Yes | Brief description | 50-150 characters, 1-2 sentences |
| `SCRIPT_LOGO` | No | Logo filename | Place source in `website/static/img/tools/src/` |
| `SCRIPT_WEBSITE` | No | Official URL | Must start with `https://` |
| `SCRIPT_SUMMARY` | No | Detailed description | 150-500 characters, 3-5 sentences |
| `SCRIPT_RELATED` | No | Related tool IDs | Space-separated script IDs |

---

## Quick Start: Install Script

```bash
#!/bin/bash

# --- Core metadata (required) ---
SCRIPT_ID="dev-example"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="Example Tool"
SCRIPT_DESCRIPTION="Installs the example development tool"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="example --version"

# --- Extended metadata (for website) ---
SCRIPT_TAGS="example demo development"
SCRIPT_ABSTRACT="Example development tool with CLI and VS Code integration."
SCRIPT_LOGO="dev-example-logo.webp"
SCRIPT_WEBSITE="https://example.com"
SCRIPT_SUMMARY="Complete example development environment including CLI tools, VS Code extensions, and common utilities. Ideal for learning and testing."
SCRIPT_RELATED="dev-python dev-typescript"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/tool-auto-enable.sh"

# Handle flags
case "${1:-}" in
    --help) echo "Usage: $0 [--help|--uninstall]"; exit 0 ;;
    --uninstall)
        log_info "Uninstalling example..."
        # uninstall commands here
        auto_disable_tool "install-dev-example.sh"
        exit 0 ;;
esac

# Check if already installed
if command -v example &>/dev/null; then
    log_info "Example already installed"
    exit 0
fi

# Install
log_info "Installing example..."
# installation commands here

# Auto-enable for future rebuilds
auto_enable_tool "install-dev-example.sh"
log_info "Example installed successfully"
```

---

## Quick Start: Service Script

```bash
#!/bin/bash

# --- Core metadata (required) ---
SCRIPT_ID="service-example"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="Example Service"
SCRIPT_DESCRIPTION="Manages the example background service"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"
SCRIPT_CHECK_COMMAND="pgrep -f example-daemon"

# --- Extended metadata (for website) ---
SCRIPT_TAGS="service daemon background example"
SCRIPT_ABSTRACT="Background service for example functionality with auto-restart."
SCRIPT_LOGO="service-example-logo.webp"
SCRIPT_WEBSITE="https://example.com/service"
SCRIPT_SUMMARY="Manages the example background service including start, stop, restart, and status commands. Supports auto-restart on failure and logging."
SCRIPT_RELATED="service-litellm service-openwebui"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/cmd-framework.sh"
source "$SCRIPT_DIR/lib/service-auto-enable.sh"

SCRIPT_COMMANDS=(
    "start:Start example service:do_start"
    "stop:Stop example service:do_stop"
    "restart:Restart example service:do_restart"
    "status:Show service status:do_status"
)

do_start() { log_info "Starting..."; }
do_stop() { log_info "Stopping..."; }
do_restart() { do_stop; do_start; }
do_status() { log_info "Status check..."; }

parse_and_run "$@"
```

---

## Key Libraries

| Library | Key Functions |
|---------|---------------|
| `logging.sh` | `log_info`, `log_warn`, `log_error` |
| `tool-auto-enable.sh` | `auto_enable_tool`, `auto_disable_tool` |
| `service-auto-enable.sh` | `auto_enable_service`, `auto_disable_service` |
| `prerequisite-check.sh` | `check_prerequisite_configs` |
| `cmd-framework.sh` | `parse_and_run` (for service/cmd scripts) |

---

## File Location

All scripts go in: `.devcontainer/additions/`

```
.devcontainer/additions/
├── install-*.sh      # Install scripts
├── config-*.sh       # Config scripts
├── service-*.sh      # Service scripts
├── cmd-*.sh          # Command scripts
└── lib/              # Shared libraries (add new ones for reusable functionality)
```

---

## When to Create Library Functions

If you find yourself writing the same code in multiple scripts, extract it to a library:

1. Create `lib/your-library.sh` with reusable functions
2. Document functions with comments
3. Source it in scripts: `source "$SCRIPT_DIR/lib/your-library.sh"`
4. Update [libraries.md](../contributors/architecture/libraries) with documentation

See existing libraries in `.devcontainer/additions/lib/` for patterns.

---

## Validation Checklist

Before committing a new script:

**Core metadata:**
1. [ ] All core metadata fields are complete (ID, VER, NAME, DESCRIPTION, CATEGORY, CHECK_COMMAND)
2. [ ] Category is valid (check categories.md)

**Extended metadata:**
3. [ ] SCRIPT_TAGS is set (space-separated keywords)
4. [ ] SCRIPT_ABSTRACT is set (50-150 characters)
5. [ ] SCRIPT_LOGO file exists in `website/static/img/tools/src/` (if specified)
6. [ ] SCRIPT_RELATED references valid script IDs (if specified)

**Functionality:**
7. [ ] `--help` flag works
8. [ ] `--uninstall` flag works (for install scripts)
9. [ ] Script is idempotent (safe to run twice)
10. [ ] **All tests pass** (CI will reject PRs with failing tests)

---

## Testing

**Tests must pass before merging.** CI runs static and unit tests automatically on every PR.

Run inside the devcontainer:

```bash
# Run all tests on your script
.devcontainer/additions/tests/run-all-tests.sh static install-dev-example.sh
.devcontainer/additions/tests/run-all-tests.sh unit install-dev-example.sh
.devcontainer/additions/tests/run-all-tests.sh install install-dev-example.sh
```

If tests fail:
- Static test failures → Check metadata, syntax, categories
- Unit test failures → Check `--help` and `--verify` implementations
- Install test failures → Check install/uninstall logic

See [testing.md](../contributors/testing) for details on the test framework.
See [CI-CD.md](../contributors/ci-cd) for what CI checks.

---

## After Adding a Script

Regenerate documentation (run inside the devcontainer):

```bash
dev-docs
```

This updates `website/docs/tools/index.md` so users can see the new tool. CI will fail if this is not done.
