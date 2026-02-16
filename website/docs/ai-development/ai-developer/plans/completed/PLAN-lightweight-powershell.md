# Feature: Lightweight PowerShell tool for Intune script development

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Create a standalone lightweight PowerShell install script that provides `pwsh` + PSScriptAnalyzer without the full Azure ops stack.

**GitHub Issue**: #47

**Last Updated**: 2026-02-16

**Investigation**: [INVESTIGATE-lightweight-powershell.md](../backlog/INVESTIGATE-lightweight-powershell.md) — chose Option A (standalone script based on template)

---

## Overview

Currently PowerShell is only available via `install-tool-azure-ops.sh`, which bundles Azure CLI, heavy Az/Graph/Exchange modules, and 7 VS Code extensions. For Intune script development, only `pwsh`, `PSScriptAnalyzer`, and the VS Code PowerShell extension are needed.

Create `install-tool-powershell.sh` based on the install template with:
- PowerShell 7 binary (GitHub releases tarball, same as `tool-azure-ops`)
- `PSScriptAnalyzer` module (via `PACKAGES_PWSH`, handled by `core-install-pwsh.sh`)
- `ms-vscode.powershell` VS Code extension

---

## Phase 1: Create the install script — ✅ DONE

### Tasks

- [x] 1.1 Copy `addition-templates/_template-install-script.sh` to `.devcontainer/additions/install-tool-powershell.sh`
- [x] 1.2 Fill in metadata
- [x] 1.3 Fill in extended metadata
- [x] 1.4 Set packages — only PSScriptAnalyzer
- [x] 1.5 Set VS Code extension
- [x] 1.6 Add version configuration
- [x] 1.7 Implement `install_powershell()` function — reused logic from `install-tool-azure-ops.sh`
- [x] 1.8 Implement uninstall logic — remove symlinks, installation directory, and modules directory
- [x] 1.9 Implement `process_installations()` — call `install_powershell` then `process_standard_installations`
- [x] 1.10 Add `post_installation_message()` and `post_uninstallation_message()` with relevant quick-start info

### Validation

```bash
bash install-tool-powershell.sh --help
# Should show metadata, version, and usage
```

User confirms phase is complete.

---

## Phase 2: Test and verify — ✅ DONE

### Tasks

- [x] 2.1 Run `bash -n install-tool-powershell.sh` to verify syntax — passed
- [x] 2.2 Verify `--help` flag works and shows correct metadata — passed (shows ID, name, version, category, packages, extensions)
- [x] 2.3 Review script for consistency with `install-tool-azure-ops.sh` patterns — consistent

### Validation

Syntax check passes. Help output is correct.

User confirms phase is complete.

### Tests Performed

On macOS host (not inside devcontainer):
- `bash -n install-tool-powershell.sh` — syntax check passed
- `bash install-tool-powershell.sh --help` — metadata, version, packages, extensions all displayed correctly
- Manual code review comparing `install_powershell()` with `install-tool-azure-ops.sh` — identical logic
- Verified `process_installations()` follows same install/uninstall pattern as azure-ops

Note: Full end-to-end testing (actual PowerShell install, PSScriptAnalyzer module, uninstall) requires running inside the devcontainer (Linux environment with sudo).

---

## Acceptance Criteria

- [ ] `install-tool-powershell.sh` installs PowerShell 7 from GitHub releases
- [ ] PSScriptAnalyzer module is installed via `PACKAGES_PWSH`
- [ ] VS Code PowerShell extension is included
- [ ] `--help` flag works
- [ ] `--uninstall` flag removes PowerShell, modules, and symlinks
- [ ] Script is idempotent (safe to run twice)
- [ ] Does NOT install Azure CLI, Az modules, Graph, or Exchange modules
- [ ] Category is `LANGUAGE_DEV`
- [ ] `SCRIPT_RELATED` references `tool-azure-ops`
- [ ] Follows template patterns (auto-enable, logging, etc.)

---

## Files to Create

- `.devcontainer/additions/install-tool-powershell.sh` — new install script (based on template)
