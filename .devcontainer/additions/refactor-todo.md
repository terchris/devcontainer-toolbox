# Refactor TODO list

This file contains stuff that we need to do before we are finished refactoring.

## SCRIPT_VER variable
The scripts will evolve over time and we need a way to keep track of them.
The --help should display the version and also the install/uninstall
updat ethe template to include the SCRIPT_VER
For all scripts we now start at 0.0.3 and follow the best practice numbering 

## Standard version checking function

### Problem
Some scripts with CUSTOM installation logic don't have version checking functions, leading to duplicate code.
Scripts using PACKAGES_* arrays incorrectly have version functions (library handles versions).

### Key Decision: Version Functions Only for Custom Installations

**Use version functions ONLY when:**
- Custom installation logic (downloading binaries, manual setup, NOT using PACKAGES_*)
- Script supports --version flag for version-aware installation
- Need to compare versions, check prerequisites, make installation decisions

**Skip version functions when:**
- Using PACKAGES_SYSTEM, PACKAGES_NODE, etc. (library functions handle versions internally)
- Library functions already display appropriate messages
- No version-aware installation logic needed

### Affected Scripts

**Scripts WITH custom installation that NEED version functions:**
- ✅ install-dev-golang.sh (has it - custom download, supports --version)
- ✅ install-dev-java.sh (has it - custom download, supports --version)
- ❌ install-srv-otel-monitoring.sh (needs it - downloads .deb/.tar.gz from GitHub)

**Scripts USING PACKAGES_* that should NOT have version functions:**
- ✅ install-srv-nginx.sh (correct - uses PACKAGES_SYSTEM)
- ❌ install-tool-azure.sh (needs removal - uses PACKAGES_SYSTEM + PACKAGES_NODE)
- install-dev-rust.sh (uses rustup - evaluate if custom or standard)
- install-dev-python.sh (uses PACKAGES_SYSTEM - evaluate)
- install-dev-typescript.sh (uses PACKAGES_NODE - evaluate)
- install-dev-csharp.sh (uses Microsoft repo + apt - evaluate)
- install-dev-php-laravel.sh (uses PACKAGES_SYSTEM - evaluate)

### Solution Pattern

**Standard Function Name**: `get_installed_version()` (or `get_installed_TOOLNAME_version()` for multi-tool scripts)

**Location**: After pre_installation_setup(), in "Utility Functions" section (OPTIONAL)

**Standard Template**:
```bash
# --- Utility Functions ---
# Centralized version checking - returns version string or empty if not installed
get_installed_version() {
    if command -v [tool-command] >/dev/null 2>&1; then
        [tool-command] --version 2>/dev/null | [extraction-logic]
    else
        echo ""
    fi
}
```

**Usage Pattern** - Replace all inline version checks:
- pre_installation_setup(): Detect current version for upgrade messages
- install_*() functions: Check if already installed with correct version
- post_installation_message(): Display installed version
- post_uninstallation_message(): Verify removal

**Examples by Tool Type**:

Simple extraction (Go, Python, Rust):
```bash
get_installed_version() {
    if command -v go >/dev/null 2>&1; then
        go version 2>/dev/null | grep -oP 'go\K[0-9.]+'
    else
        echo ""
    fi
}
```

JSON extraction (Azure CLI):
```bash
get_installed_version() {
    if command -v az >/dev/null 2>&1; then
        az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4
    else
        echo ""
    fi
}
```

Multi-tool scripts (separate function per tool):
```bash
get_installed_otel_version() {
    if command -v otelcol-contrib >/dev/null 2>&1; then
        otelcol-contrib --version 2>/dev/null | head -1
    else
        echo ""
    fi
}

get_installed_script_exporter_version() {
    if [ -f /usr/local/bin/script_exporter ]; then
        /usr/local/bin/script_exporter --version 2>/dev/null | head -1
    else
        echo ""
    fi
}
```

### Implementation Steps

1. ✅ Update template with clear guidance on when to use/skip version functions
2. ❌ Add version functions to install-srv-otel-monitoring.sh (custom GitHub downloads)
3. ❌ Remove version functions from install-tool-azure.sh (uses PACKAGES_*)
4. ❌ Evaluate and update remaining dev scripts based on installation method
5. Test each modified script to ensure correct behavior

### Benefits
- **Simpler scripts** when using PACKAGES_* (no unnecessary code)
- **Consistent pattern** for custom installations (DRY principle)
- **Clear distinction** between standard (PACKAGES_*) and custom installations
- **Easier maintenance** - change version logic in one place for custom installs
- **Template clarity** - explicit guidance on when to use each pattern

## Docker Extension Testing

Docker extension was added to install-tool-dev-utils.sh with Docker CLI (docker.io package).
Extension installed successfully but needs testing after devcontainer rebuild to verify:
- Docker CLI can connect to Rancher Desktop via /var/run/docker.sock
- Docker extension UI works correctly
- `docker ps` command works inside devcontainer

Test after rebuild:
```bash
docker ps
docker images
```
note: i think that the path is not set as i do: vscode ➜ /workspace (main) $ docker ps
bash: docker: command not found


## auto_enable_tool and auto_disable_tool ✅ COMPLETED
Manages addition and removal from .devcontainer.extend/enabled-tools.conf
✅ DONE: All scripts now use these functions correctly (no parameters)
✅ DONE: Added auto_disable_tool to uninstall paths where missing
✅ DONE: Removed unnecessary parameters from all calls

**Fixed scripts:**
- install-dev-csharp.sh
- install-dev-golang.sh
- install-dev-java.sh
- install-dev-php-laravel.sh
- install-dev-python.sh
- install-dev-rust.sh
- install-dev-typescript.sh
- install-tool-powershell.sh

**Pattern used:**
```bash
if [ "${UNINSTALL_MODE}" -eq 1 ]; then
    # ... uninstall logic
    post_uninstallation_message

    # Remove from auto-enable config
    auto_disable_tool  # No parameters
else
    # ... install logic
    post_installation_message

    # Auto-enable for container rebuild
    auto_enable_tool  # No parameters
fi
```

## --debug  flag
Some scripts have the --debug flag and some not. why?
Do the system support it/do we need it

## PREREQUISITE_CONFIGS automatic enforcement
The template defines PREREQUISITE_CONFIGS field and lib/prerequisite-check.sh library exists, but automatic checking is not yet implemented in dev-setup.sh or project-installs.sh.
TODO: Implement automatic prerequisite checking before running install scripts (see template lines 52-86 and TODO in config-ai-claudecode.sh)
TODO: Once implemented, remove manual prerequisite checks from pre_installation_setup() functions and rely on PREREQUISITE_CONFIGS declaration instead