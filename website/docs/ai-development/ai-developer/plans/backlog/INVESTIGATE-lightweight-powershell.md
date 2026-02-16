# Investigate: Lightweight PowerShell tool for Intune script development

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Determine the best approach for a standalone lightweight PowerShell install script.

**GitHub Issue**: #47

**Last Updated**: 2026-02-16

---

## Questions to Answer

1. Can we reuse the existing PowerShell installation logic from `install-tool-azure-ops.sh`?
2. What's the right category for this script?
3. What minimal set of packages is needed?
4. Should `PSScriptAnalyzer` move from `tool-azure-ops` to this new script?

---

## Current State

PowerShell (`pwsh`) is only available via `install-tool-azure-ops.sh`, which bundles:
- Azure CLI (`az`)
- PowerShell 7 with heavy modules: `Az`, `Microsoft.Graph`, `ExchangeOnlineManagement`, `PSScriptAnalyzer`
- 7 VS Code extensions (Azure Account, Resources, Storage, Functions, Databases, Pipelines, Terraform)

This is too heavy when only `pwsh` + linting is needed (e.g., for Intune script development).

### Existing infrastructure

| Component | Location | Purpose |
|-----------|----------|---------|
| Install template | `addition-templates/_template-install-script.sh` | Template for new install scripts |
| PowerShell core library | `lib/core-install-pwsh.sh` | Module install/uninstall/update functions |
| Azure ops script | `install-tool-azure-ops.sh` | Full Azure + PowerShell stack |
| CREATING-SCRIPTS.md | `website/docs/ai-development/ai-developer/CREATING-SCRIPTS.md` | Script conventions and metadata |

### How PowerShell is currently installed

`install-tool-azure-ops.sh` installs PowerShell via `pre_installation_setup()` which calls the Microsoft APT repository setup. The `PACKAGES_PWSH` array is then processed by `lib/core-install-pwsh.sh` which handles `Install-Module` for each module.

The `core-install-pwsh.sh` library:
- Checks if `pwsh` is available
- Sets PSGallery as trusted
- Installs/updates/uninstalls modules via `process_pwsh_modules()`
- Handles version checking and reporting

This library is **already sourced by the template** (`source "${SCRIPT_DIR}/lib/core-install-pwsh.sh"`) so a new script using `PACKAGES_PWSH` gets module management for free.

### PowerShell installation itself

PowerShell 7 is installed from Microsoft's APT repository. The `pre_installation_setup()` in `install-tool-azure-ops.sh` handles this via custom code (not a standard `PACKAGES_SYSTEM` entry). A new script would need similar APT repo setup logic.

---

## Options

### Option A: New standalone script based on template

Create `install-tool-powershell.sh` using `_template-install-script.sh`:
- `pre_installation_setup()` — install PowerShell 7 from Microsoft APT repo
- `PACKAGES_PWSH=("PSScriptAnalyzer")` — just the linter
- `EXTENSIONS=("ms-vscode.powershell")` — just the VS Code extension
- Category: `LANGUAGE_DEV`

**Pros:**
- Clean, follows existing patterns
- Template handles all boilerplate (auto-enable, help, uninstall, etc.)
- `core-install-pwsh.sh` already handles module management
- Lightweight — no Azure CLI, no heavy modules

**Cons:**
- Duplicates PowerShell APT repo setup from `install-tool-azure-ops.sh`
- If both are installed, PowerShell is set up twice (idempotent, but wasteful)

### Option B: Extract shared PowerShell install function

Same as Option A, but extract the PowerShell binary installation into a shared function in `lib/` that both scripts can call.

**Pros:**
- No code duplication
- Both scripts use the same install path

**Cons:**
- More refactoring work
- `install-tool-azure-ops.sh` needs to be modified
- Risk of breaking existing script

---

## Recommendation

**Option A** — New standalone script based on the template. Keep it simple.

- Code duplication of the APT repo setup is minimal (~10 lines)
- The scripts are idempotent so installing both is harmless
- Avoids modifying the working `install-tool-azure-ops.sh`
- Can always extract the shared function later if a third script needs PowerShell

### Proposed metadata

```bash
SCRIPT_ID="tool-powershell"
SCRIPT_VER="1.0.0"
SCRIPT_NAME="PowerShell"
SCRIPT_DESCRIPTION="Installs PowerShell 7 with PSScriptAnalyzer for script development and linting"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command -v pwsh >/dev/null 2>&1 || [ -f /usr/bin/pwsh ]"

SCRIPT_TAGS="powershell pwsh intune linting scripting"
SCRIPT_ABSTRACT="PowerShell 7 with PSScriptAnalyzer for script development and linting."
SCRIPT_WEBSITE="https://learn.microsoft.com/en-us/powershell/"
SCRIPT_RELATED="tool-azure-ops"
```

### Proposed packages

```bash
PACKAGES_SYSTEM=()  # PowerShell installed via pre_installation_setup (APT repo)

PACKAGES_PWSH=(
    "PSScriptAnalyzer"  # PowerShell linter
)

EXTENSIONS=(
    "PowerShell (ms-vscode.powershell) - PowerShell language support and debugging"
)
```

### Note on PSScriptAnalyzer

Currently `PSScriptAnalyzer` is in both `tool-azure-ops` and the proposed `tool-powershell`. This is fine — the install library is idempotent and will skip if already installed. No need to remove it from `tool-azure-ops`.

---

## Next Steps

- [ ] Create `PLAN-lightweight-powershell.md` with the chosen approach
