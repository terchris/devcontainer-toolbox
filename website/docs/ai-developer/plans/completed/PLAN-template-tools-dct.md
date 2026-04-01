# Feature: TEMPLATE_TOOLS support in template installers (DCT side)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-03-30

**Goal**: Make `dev-template.sh` and `dev-template-ai.sh` read `TEMPLATE_TOOLS` from `TEMPLATE_INFO` and automatically install the required devcontainer tools.

**Last Updated**: 2026-03-30

**Investigation**: [INVESTIGATE-advanced-templates.md](../backlog/INVESTIGATE-advanced-templates.md)

**Companion plan**: `PLAN-template-tools-dev-templates.md` in `helpers-no/dev-templates` -- adds `TEMPLATE_TOOLS` to each template's `TEMPLATE_INFO`. **Completed 2026-03-30** -- all 7 app templates now have `TEMPLATE_TOOLS` on `main`.

---

## Overview

When a user installs a template (e.g., PHP Basic Webserver), the required runtime (e.g., PHP) should be automatically installed in the devcontainer. Currently templates only scaffold files -- the user must manually find and install the tool.

**How it works:**

1. `TEMPLATE_INFO` declares: `TEMPLATE_TOOLS="dev-php-laravel"`
2. Template installer reads `TEMPLATE_TOOLS`
3. For each tool ID:
   - Runs the install script (`install-{SCRIPT_ID}.sh`)
   - The install script's `auto_enable_tool` adds it to `enabled-tools.conf` automatically
4. Tools persist across container rebuilds via `enabled-tools.conf`

**Key design notes:**
- Install scripts are idempotent -- re-running `dev-template` won't reinstall tools already present
- `$ADDITIONS_DIR` must be set by the calling script before `install_template_tools()` is called
- `install_template_tools()` should run BEFORE placeholder replacement so tool output appears before the completion message

---

## Phase 1: Update shared library -- DONE

### Tasks

- [x] 1.1 Update `read_template_info()` in `lib/template-common.sh`:
  - Add `INFO_TOOLS=""` default
  - Add `TEMPLATE_TOOLS` to the `unset` line BEFORE sourcing (prevents leaking between templates)
  - Read `INFO_TOOLS="${TEMPLATE_TOOLS:-$INFO_TOOLS}"`
  - Add `TEMPLATE_TOOLS` to the `unset` line AFTER sourcing (cleanup)
- [x] 1.2 Add `install_template_tools()` function to `lib/template-common.sh`:
  - Takes space-separated SCRIPT_IDs as argument
  - For each ID, find `install-${ID}.sh` in `$ADDITIONS_DIR`
  - If script exists, run it with `bash "$script_path"`
  - If install script **fails** (non-zero exit), catch the error and continue:
    `if ! bash "$script_path"; then echo "warning: install later with dev-setup"; fi`
    (Both calling scripts use `set -e` — uncaught failure would abort the entire template install)
  - If script not found, print warning and continue (don't crash)
  - Print summary of what was installed / failed
  - Requires `$ADDITIONS_DIR` to be set by the calling script (document in function header)
  - Handle empty/unset argument gracefully (no-op)

### Validation

Library function exists, handles single tool, multiple tools, empty tools, and unknown tool IDs.

---

## Phase 2: Integrate into dev-template.sh -- DONE

### Tasks

- [x] 2.1 Add `TEMPLATE_TOOLS_LIST=()` array to `scan_templates()`
- [x] 2.2 Add `TEMPLATE_TOOLS_LIST+=("$INFO_TOOLS")` in the scan loop
- [x] 2.3 Show tools in `show_template_details()` dialog -- add "Tools: dev-php-laravel" to the details text if `TEMPLATE_TOOLS_LIST[$idx]` is non-empty
- [x] 2.4 Call `install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]}"` in main flow AFTER `copy_template_files` and BEFORE `process_template_files`
- [x] 2.5 Update `--help` text to mention that required tools are installed automatically

### Validation

Running `dev-template` with PHP template shows tools in details dialog and installs PHP automatically.

---

## Phase 3: Integrate into dev-template-ai.sh -- DONE

### Tasks

- [x] 3.1 Add `TEMPLATE_TOOLS_LIST=()` array to `scan_templates()`
- [x] 3.2 Add `TEMPLATE_TOOLS_LIST+=("$INFO_TOOLS")` in the scan loop
- [x] 3.3 Show tools in `show_template_details_dialog()` if non-empty (via the shared function or locally)
- [x] 3.4 Call `install_template_tools "${TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]}"` in main flow AFTER `copy_template_files` and BEFORE `process_template_files`
- [x] 3.5 Update `--help` text to mention that required tools are installed automatically

### Validation

`dev-template-ai` handles `TEMPLATE_TOOLS` if present (no-op if empty).

---

## Phase 4: Testing -- DONE

### Tasks

**Happy path:**
- [x] 4.1 Test `dev-template` with PHP template -- PHP should auto-install, show in dialog details
- [x] 4.2 Test `dev-template-ai` with plan-based-workflow -- no tools, should work as before (backward compatible)
- [x] 4.3 Verify template details dialog shows "Tools to install: dev-php-laravel" before confirmation
- [x] 4.4 Verify tools persist in `enabled-tools.conf` after install
- [x] 4.5 Verify `--help` text mentions automatic tool installation

**Idempotency:**
- [x] 4.6 Re-run `dev-template` on same project -- tools should skip (already installed)

**Error handling:**
- [x] 4.7 Test with unknown tool ID -- should warn and continue, not abort template install
- [x] 4.8 Test with a tool that fails to install -- should warn and continue, remaining tools still install, template files still in place, completion message still shows
- [x] 4.9 Verify cleanup runs even if tool install fails (temp dir removed)

**Multiple tools:**
- [x] 4.10 Test with template that has multiple tools (edit a TEMPLATE_INFO temporarily to have two tools) -- both should install

**Regression:**
- [x] 4.11 Verify `dev-template.sh` still works end-to-end after changes
- [x] 4.12 Verify `dev-template-ai.sh` still works end-to-end after changes

### Validation

All tests pass. Backward compatible with templates that don't have TEMPLATE_TOOLS. Failed tool installs don't abort the template installer.

---

## Acceptance Criteria

- [x] `install_template_tools()` in `template-common.sh` handles single and multiple tool IDs
- [x] `read_template_info()` properly unsets `TEMPLATE_TOOLS` before and after sourcing (no leaking between templates)
- [x] `dev-template.sh` installs tools declared in `TEMPLATE_TOOLS`
- [x] `dev-template-ai.sh` installs tools declared in `TEMPLATE_TOOLS`
- [x] Tools added to `enabled-tools.conf` (persist across rebuilds)
- [x] Backward compatible -- templates without `TEMPLATE_TOOLS` work as before
- [x] Unknown tool IDs produce a warning, not a crash
- [x] Template details dialog shows required tools before user confirms
- [x] `--help` mentions automatic tool installation
- [x] Re-running on same project doesn't reinstall already-installed tools
- [x] Failed tool install doesn't abort template installer -- warns and continues
- [x] Cleanup runs even when tool installs fail

---

## Template-to-Tool Mapping (reference)

| Template | TEMPLATE_TOOLS value |
|----------|---------------------|
| php-basic-webserver | `dev-php-laravel` |
| typescript-basic-webserver | `dev-typescript` |
| designsystemet-basic-react-app | `dev-typescript` |
| python-basic-webserver | `dev-python` |
| golang-basic-webserver | `dev-golang` |
| java-basic-webserver | `dev-java` |
| csharp-basic-webserver | `dev-csharp` |
| plan-based-workflow (ai) | *(none -- no runtime needed)* |

---

## Files to Modify

- `.devcontainer/manage/lib/template-common.sh` -- add `install_template_tools()`, update `read_template_info()`
- `.devcontainer/manage/dev-template.sh` -- add tools array, show in details, call installer, update help
- `.devcontainer/manage/dev-template-ai.sh` -- add tools array, show in details, call installer, update help
