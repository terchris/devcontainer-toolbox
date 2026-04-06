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

**Image mode:** At build time, the Docker image copies these scripts to `/opt/devcontainer-toolbox/additions/` (set as `$DCT_HOME/additions/`). When developing and testing locally in the repo, you work with the `.devcontainer/additions/` path as normal. The image build handles the copy.

---

## When to Create Library Functions

If you find yourself writing the same code in multiple scripts, extract it to a library:

1. Create `lib/your-library.sh` with reusable functions
2. Document functions with comments
3. Source it in scripts: `source "$SCRIPT_DIR/lib/your-library.sh"`
4. Update [libraries.md](../contributors/architecture/libraries) with documentation

See existing libraries in `.devcontainer/additions/lib/` for patterns.

---

## Version Pinning Rules

When a script installs software, decide whether to pin a `DEFAULT_VERSION` or install latest. Wrong choice either way causes problems: unpinned runtimes break user code on surprise upgrades, stale pins give users 3-year-old software.

### Pin when

**Rule 1: Pin if the version affects user code compatibility.**
Languages, runtimes, SDKs, and frameworks. A version change can break builds, imports, or APIs.
Pin: Go, Java, .NET, PHP, Node.js, Hugo, Python.
Don't pin: shellcheck, jq, curl, wget, git.

**Rule 2: Pin if config format changes between versions.**
Tools where the user writes config files tied to a specific schema.
Pin: OTel Collector (config YAML schema changes), Kubernetes tools (API versions).

### Don't pin when

**Rule 3: Don't pin if installed via a package manager that handles compatibility.**
apt, npm global, pip, rustup — these resolve dependencies themselves.

**Rule 4: Don't pin utilities where "latest" is always safe.**
Small CLI tools, formatters, dev helpers. Breaking changes are rare and low-impact.

### How to pin

**Rule 5: Every pin MUST have a Renovate annotation.**
No pin without a maintenance path. Format:
```bash
# renovate: datasource=github-releases depName=golang/go
DEFAULT_VERSION="1.26.1"
```
If Renovate is not yet set up, document the pin with a date comment:
```bash
DEFAULT_VERSION="1.26.1"  # Pinned 2026-04-06, check https://go.dev/dl/
```

**Rule 6: Pin to the latest stable, not an arbitrary old version.**
When adding a new pin, always check upstream for the current stable release. Never copy a version from a tutorial or blog post without verifying.

**Rule 7: Use LTS/stable tracks, not bleeding edge.**
For software with LTS releases, pin to the active LTS:
- Node.js: latest v22.x (Jod LTS), not v24.x until it becomes LTS
- Java: 17 or 21 (LTS), not 22 (short-term)
- .NET: 8.0 (LTS), not 10.0 (current but short-term support)

**Rule 8: `--version` flag must always be available.**
Every script with a `DEFAULT_VERSION` must accept `--version X.Y.Z` so users can override. The pin is a sensible default, not a constraint.

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
11. [ ] **Install cycle test passes** if you changed a version pin or install logic (`run-all-tests.sh install <script>`)

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

### When to run install cycle tests (Level 3)

The install cycle test (`run-all-tests.sh install`) actually downloads, installs, verifies, uninstalls, and re-verifies. It is **not run in CI** — it runs locally in the devcontainer only.

**You MUST run it when:**
- Bumping a `DEFAULT_VERSION` pin (e.g., Go 1.21 → 1.26)
- Changing download URLs or archive handling logic
- Adding a new install script
- Modifying install/uninstall logic

```bash
# After changing install-dev-golang.sh:
.devcontainer/additions/tests/run-all-tests.sh install install-dev-golang.sh

# Full cycle for ALL scripts (slow — downloads everything, 15-30 min):
.devcontainer/additions/tests/run-all-tests.sh install
```

The test auto-discovers all `install-*.sh` scripts — no hardcoded list. New scripts are automatically included.

See [testing.md](../contributors/testing) for details on the test framework.
See [CI-CD.md](../contributors/ci-cd) for what CI checks.

---

## After Adding a Script

Regenerate documentation (run inside the devcontainer):

```bash
dev-docs
```

This updates `website/docs/tools/index.mdx` so users can see the new tool. CI will fail if this is not done.
