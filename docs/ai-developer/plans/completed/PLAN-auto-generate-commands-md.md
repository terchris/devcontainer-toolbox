# Plan: Unify Manage Scripts with Additions System

## Status: Completed

**Goal**: Make manage scripts (dev-*.sh) use the same metadata and menu system as additions scripts, and auto-generate docs/commands.md.

**Priority**: Medium

**Last Updated**: 2026-01-15

---

## Problem

Currently:
- `docs/tools.md` and `docs/tools-details.md` are auto-generated from install scripts
- `docs/commands.md` is manually written and can get out of sync
- dev-*.sh scripts in `.devcontainer/manage/` have no standardized metadata
- dev-setup only shows additions scripts, not manage scripts
- Users must know dev-* commands exist - they're not discoverable in the TUI
- Contributor tools (generate docs, run tests) are not easily discoverable

Goal:
- Add same metadata format to manage scripts (SCRIPT_ID, SCRIPT_NAME, SCRIPT_DESCRIPTION, SCRIPT_CATEGORY, SCRIPT_COMMANDS)
- Add new category `SYSTEM_COMMANDS` for user-facing manage scripts
- Add new category `CONTRIBUTOR_TOOLS` for maintainer tools
- Rename `generate-manual.sh` to `dev-docs.sh`
- Create `dev-test.sh` wrapper for run-all-tests.sh
- Update component-scanner.sh to also scan manage directory
- Update dev-setup to show manage scripts in the TUI menu
- Auto-generate docs/commands.md from manage script metadata

---

## Phase 1: Add New Categories — ✅ DONE

Add categories for system commands and contributor tools.

### Tasks

- [x] 1.1 Add `SYSTEM_COMMANDS` category to `lib/categories.sh`:
  ```
  0|SYSTEM_COMMANDS|System Commands|DevContainer management commands|DevContainer management commands (setup, update, services, help)
  ```
  Note: Sort order 0 to show first in menu

- [x] 1.2 Add `CONTRIBUTOR_TOOLS` category to `lib/categories.sh`:
  ```
  7|CONTRIBUTOR_TOOLS|Contributor Tools|Tools for contributors and maintainers|Tools for contributors and maintainers (generate docs, run tests)
  ```
  Note: Sort order 7 to show last in menu

- [x] 1.3 Add category constants:
  ```bash
  readonly CATEGORY_SYSTEM_COMMANDS="SYSTEM_COMMANDS"
  readonly CATEGORY_CONTRIBUTOR_TOOLS="CONTRIBUTOR_TOOLS"
  ```

### Validation

```bash
source .devcontainer/additions/lib/categories.sh
is_valid_category "SYSTEM_COMMANDS" && echo "OK"
is_valid_category "CONTRIBUTOR_TOOLS" && echo "OK"
```

---

## Phase 2: Rename and Create Contributor Tools — ✅ DONE

Rename generate-manual.sh and create dev-test.sh wrapper.

### Tasks

- [x] 2.1 Rename `generate-manual.sh` to `dev-docs.sh`:
  ```bash
  git mv .devcontainer/manage/generate-manual.sh .devcontainer/manage/dev-docs.sh
  ```

- [x] 2.2 Create `dev-test.sh` wrapper script:
  ```bash
  #!/bin/bash
  # dev-test.sh - Run devcontainer-toolbox tests

  SCRIPT_ID="dev-test"
  SCRIPT_NAME="Run Tests"
  SCRIPT_DESCRIPTION="Run static, unit, and install tests"
  SCRIPT_CATEGORY="CONTRIBUTOR_TOOLS"
  SCRIPT_CHECK_COMMAND="true"

  SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

  # Handle --help locally
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
      echo "dev-test - Run devcontainer-toolbox tests"
      echo ""
      echo "Usage: dev-test [test-type] [script-name]"
      echo ""
      echo "This is a wrapper for run-all-tests.sh"
      echo ""
      # Show run-all-tests.sh help
      "$SCRIPT_DIR/../additions/tests/run-all-tests.sh" --help
      exit 0
  fi

  # Pass all arguments to run-all-tests.sh
  exec "$SCRIPT_DIR/../additions/tests/run-all-tests.sh" "$@"
  ```

- [x] 2.3 Add `dev-docs` and `dev-test` to command symlinks:
  - Location: `.devcontainer/additions/lib/environment-utils.sh`
  - Function: `setup_command_symlinks()` lines 106-115
  - Add "dev-docs" and "dev-test" to the `commands` array:
    ```bash
    local commands=(
        "dev-setup"
        "dev-services"
        "dev-template"
        "dev-update"
        "dev-check"
        "dev-clean"
        "dev-env"
        "dev-help"
        "dev-docs"     # NEW - contributor tool
        "dev-test"     # NEW - contributor tool
    )
    ```
  - This creates symlinks `/workspace/.devcontainer/dev-docs` → `manage/dev-docs.sh`
  - And `/workspace/.devcontainer/dev-test` → `manage/dev-test.sh`
  - PATH already includes `/workspace/.devcontainer` via `setup_devcontainer_path()`

### Validation

```bash
dev-docs --help
dev-test --help
```

---

## Phase 3: Add Metadata to System Command Scripts — ✅ DONE

Add standardized metadata to user-facing dev-*.sh scripts.

### Tasks

- [x] 3.1 Add metadata to `dev-setup.sh`:
  ```bash
  SCRIPT_ID="dev-setup"
  SCRIPT_NAME="Setup Menu"
  SCRIPT_DESCRIPTION="Interactive menu for installing tools and managing services"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.2 Add metadata to `dev-help.sh`:
  ```bash
  SCRIPT_ID="dev-help"
  SCRIPT_NAME="Help"
  SCRIPT_DESCRIPTION="Show available commands and version info"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.3 Add metadata to `dev-update.sh`:
  ```bash
  SCRIPT_ID="dev-update"
  SCRIPT_NAME="Update"
  SCRIPT_DESCRIPTION="Update devcontainer-toolbox to latest version"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.4 Add metadata to `dev-services.sh`:
  ```bash
  SCRIPT_ID="dev-services"
  SCRIPT_NAME="Services"
  SCRIPT_DESCRIPTION="Manage background services (start, stop, status, logs)"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.5 Add metadata to `dev-template.sh`:
  ```bash
  SCRIPT_ID="dev-template"
  SCRIPT_NAME="Templates"
  SCRIPT_DESCRIPTION="Create project files from templates"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.6 Add metadata to `dev-check.sh`:
  ```bash
  SCRIPT_ID="dev-check"
  SCRIPT_NAME="Check Configuration"
  SCRIPT_DESCRIPTION="Configure and validate Git identity and credentials"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.7 Add metadata to `dev-env.sh`:
  ```bash
  SCRIPT_ID="dev-env"
  SCRIPT_NAME="Environment"
  SCRIPT_DESCRIPTION="Show installed tools and environment info"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 3.8 Add metadata to `dev-clean.sh`:
  ```bash
  SCRIPT_ID="dev-clean"
  SCRIPT_NAME="Clean"
  SCRIPT_DESCRIPTION="Clean up devcontainer resources"
  SCRIPT_CATEGORY="SYSTEM_COMMANDS"
  SCRIPT_CHECK_COMMAND="true"
  ```

### Validation

```bash
grep "^SCRIPT_ID=" .devcontainer/manage/dev-*.sh | wc -l
# Should show 10 scripts with metadata (8 system + 2 contributor)
```

---

## Phase 4: Add Metadata to Contributor Tool Scripts — ✅ DONE

Add standardized metadata to contributor tools.

### Tasks

- [x] 4.1 Add metadata to `dev-docs.sh` (renamed from generate-manual.sh):
  ```bash
  SCRIPT_ID="dev-docs"
  SCRIPT_NAME="Generate Docs"
  SCRIPT_DESCRIPTION="Generate documentation (tools.md, commands.md)"
  SCRIPT_CATEGORY="CONTRIBUTOR_TOOLS"
  SCRIPT_CHECK_COMMAND="true"
  ```

- [x] 4.2 Metadata already in `dev-test.sh` from Phase 2.4

### Validation

```bash
grep "CONTRIBUTOR_TOOLS" .devcontainer/manage/dev-*.sh
# Should show dev-docs.sh and dev-test.sh
```

---

## Phase 5: Update Component Scanner — ✅ DONE

Extend component-scanner.sh to scan manage directory.

### Tasks

- [x] 5.1 Add `scan_manage_scripts()` function:
  ```bash
  # Scan manage scripts (dev-*.sh) and return metadata
  # Output: script_basename<TAB>script_name<TAB>script_desc<TAB>script_cat<TAB>check_cmd
  scan_manage_scripts() {
      local manage_dir="$1"
      # Similar to scan_install_scripts but for dev-*.sh pattern
      # Excludes:
      #   - dev-welcome.sh (internal, runs on container start)
      #   - dev-setup.sh (would cause recursion - it's the menu itself)
      #   - postStartCommand.sh, postCreateCommand.sh (devcontainer hooks)
  }
  ```

- [x] 5.2 Add helper function to get manage script path from basename

- [x] 5.3 Verify existing tests still pass after scanner changes

### Validation

```bash
source .devcontainer/additions/lib/component-scanner.sh
scan_manage_scripts "/workspace/.devcontainer/manage" | head -3
```

---

## Phase 6: Refactor dev-setup to Dynamic Menu — ✅ DONE

Currently the main menu is hardcoded with 8 options. Refactor to dynamically generate the menu from categories.

### Current Hardcoded Menu (to be replaced):
```
1. Browse & Install Tools
2. Manage Services
3. Setup & Configuration
4. Command Tools
5. Manage Auto-Install Tools
6. Create project from template  <- calls dev-template.sh directly
7. Show Environment Info         <- calls dev-env.sh directly
8. Exit
```

### New Dynamic Menu Structure:
```
1. Browse & Install Tools        → [tool categories: Development, AI, Cloud, Data]
2. Create project from template  ← dev-template.sh DIRECTLY (special case)
3. System Commands               → [submenu: Help, Update, Services, Check, Environment, Clean]
4. Manage Services               → [existing Manage Services submenu]
5. Setup & Configuration         → [config-*.sh scripts]
6. Command Tools                 → [cmd-*.sh scripts]
7. Manage Auto-Install Tools
8. Contributor Tools             → [submenu: dev-docs, dev-test]
9. Exit
```

**Key points:**
- dev-template.sh shown directly at position 2 (special case)
- System Commands submenu contains: dev-help, dev-update, dev-services, dev-check, dev-env, dev-clean
- Contributor Tools submenu contains: dev-docs, dev-test

### Key Design Decisions:
1. **dev-template special case** - shown directly in main menu (not behind category submenu)
2. **All other categories open submenus** - including SYSTEM_COMMANDS, LANGUAGE_DEV, AI_TOOLS, etc.
3. **dev-setup excluded** from SYSTEM_COMMANDS to avoid recursion
4. **Manage scripts use direct run** - selecting runs the script immediately (no SCRIPT_COMMANDS submenu)
5. **BACKGROUND_SERVICES keeps submenu** - opens existing "Manage Services" with Start/Stop + Auto-Start options
6. **Upfront scanning** - all script types scanned at startup (consistent with current behavior)
7. **No symlink** for generate-manual.sh backwards compatibility

### Tasks

- [x] 6.1 Add `MANAGE_DIR` path constant to dev-setup.sh

- [x] 6.2 Create `scan_manage_scripts()` call during initialization (alongside scan_available_tools, etc.)

- [x] 6.3 Create new arrays for manage scripts:
  ```bash
  declare -a AVAILABLE_MANAGE_SCRIPTS=()
  declare -a MANAGE_SCRIPT_NAMES=()
  declare -a MANAGE_SCRIPT_DESCRIPTIONS=()
  declare -a MANAGE_SCRIPT_CATEGORIES=()
  declare -A MANAGE_BY_CATEGORY
  ```

- [x] 6.4 Refactor `show_main_menu()` to be dynamic with this structure:
  ```
  1. Browse & Install Tools        → [tool browser]
  2. Create project from template  ← dev-template.sh (special case, direct)
  3. System Commands               → [submenu]
  4. Manage Services               → [existing submenu]
  5. Setup & Configuration         → [config scripts]
  6. Command Tools                 → [cmd scripts]
  7. Manage Auto-Install Tools
  8. Contributor Tools             → [submenu]
  9. Exit
  ```

- [x] 6.4.1 Handle dev-template special case:
  - dev-template.sh keeps `SCRIPT_CATEGORY="SYSTEM_COMMANDS"` for metadata consistency
  - Main menu shows "Create project from template" directly at position 2
  - SYSTEM_COMMANDS submenu excludes dev-template (already in main menu)

- [x] 6.5 Create `show_manage_scripts_menu()` function:
  - Shows list of dev-* scripts in selected category (SYSTEM_COMMANDS or CONTRIBUTOR_TOOLS)
  - **Direct run**: Selecting a script executes it immediately (no submenu)
  - Shows script output, waits for Enter, returns to menu

- [x] 6.6 Create `scan_available_manage_scripts()` function in dev-setup.sh:
  - Similar to `scan_available_tools()` but calls `scan_manage_scripts()` from library
  - Populates AVAILABLE_MANAGE_SCRIPTS, MANAGE_SCRIPT_NAMES, etc. arrays

- [x] 6.7 Keep `create_project_from_template()` function for special case handling (dev-template shown directly in main menu)

- [x] 6.8 Remove hardcoded "Show Environment Info" option (dev-env now in SYSTEM_COMMANDS menu)

### Validation

Run `dev-setup` and verify:
- Main menu shows categories dynamically
- SYSTEM_COMMANDS appears first (sort order 0)
- CONTRIBUTOR_TOOLS appears last (sort order 7)
- Selecting a category shows scripts in that category
- dev-template, dev-env, dev-help etc. are accessible through SYSTEM_COMMANDS
- dev-docs, dev-test are accessible through CONTRIBUTOR_TOOLS
- Utility options (Manage Auto-Install, Manage Auto-Start, Exit) still work

---

## Phase 7: Update dev-docs.sh (formerly generate-manual.sh) — ✅ DONE

Add function to auto-generate docs/commands.md.

### Tasks

- [x] 7.1 Read current `docs/commands.md` and define target format:
  - Preserve useful structure from manual version
  - Define sections: Quick Reference table, detailed command descriptions
  - Use SCRIPT_NAME and SCRIPT_DESCRIPTION from metadata

- [x] 7.2 Add `MANAGE_DIR` path constant

- [x] 7.3 Add `generate_commands_md()` function to create commands.md content:
  - Generate Quick Reference table from all manage script metadata
  - Generate detailed section for each command
  - Include usage info from script --help output (optional)

- [x] 7.4 Call `generate_commands_md()` in main generation logic

- [x] 7.5 Update script help text to mention commands.md output

- [x] 7.6 Metadata header already added in Phase 4

### Validation

```bash
dev-docs
cat docs/commands.md
```

---

## Phase 8: Update CI Workflow — ✅ DONE

Add commands.md to documentation check.

### Tasks

- [x] 8.1 Update ci-tests.yml to check commands.md in docs-check job

- [x] 8.2 Update any references to generate-manual.sh to use dev-docs.sh

### Validation

CI passes and catches out-of-date commands.md.

---

## Phase 9: Update Documentation — ✅ DONE

Create maintainer documentation and update existing docs.

### Tasks

- [x] 9.1 Create `docs/contributors/manage-scripts.md`:
  - Purpose of manage/ folder vs additions/ folder
  - How manage scripts (dev-*.sh) work
  - Metadata format for manage scripts
  - How dynamic menu generation works
  - When to add new manage scripts vs additions scripts

- [x] 9.2 Update `docs/contributors/architecture.md`:
  - Updated manage/ folder structure with dev-docs.sh and dev-test.sh

- [x] 9.3 Update `docs/ai-developer/CREATING-SCRIPTS.md`:
  - Updated generate-manual.sh → dev-docs reference

- [x] 9.4 Update `docs/contributors/adding-tools.md`:
  - Updated generate-manual.sh → dev-docs reference

- [x] 9.5 Update references to generate-manual.sh → dev-docs:
  - `docs/contributors/CI-CD.md`
  - `docs/contributors/RELEASING.md`
  - `docs/contributors/categories.md`
  - `docs/ai-developer/WORKFLOW.md`
  - `README.md`

### Validation

- manage-scripts.md explains the manage/ folder clearly
- CREATING-SCRIPTS.md clarifies it's for contributors adding tools
- All references to generate-manual.sh updated to dev-docs.sh

---

## Acceptance Criteria

### Categories
- [ ] New SYSTEM_COMMANDS category exists (sort order 0)
- [ ] New CONTRIBUTOR_TOOLS category exists (sort order 7)

### Scripts
- [ ] generate-manual.sh renamed to dev-docs.sh
- [ ] dev-test.sh wrapper created with --help support
- [ ] `dev-docs` and `dev-test` commands work from terminal (PATH/aliases added)
- [ ] All user-facing dev-*.sh scripts have full metadata (8 system + 2 contributor = 10 scripts)
- [ ] dev-setup.sh excluded from scan (avoids recursion)

### Scanner
- [ ] component-scanner.sh can scan manage directory via `scan_manage_scripts()`
- [ ] Existing tests still pass after scanner changes

### Menu
- [ ] dev-setup main menu is dynamically generated from categories
- [ ] dev-template shown directly in main menu (special case)
- [ ] All categories open submenus (including SYSTEM_COMMANDS)
- [ ] SYSTEM_COMMANDS submenu contains: dev-help, dev-update, dev-services, dev-check, dev-env, dev-clean
- [ ] dev-docs, dev-test accessible via CONTRIBUTOR_TOOLS submenu
- [ ] BACKGROUND_SERVICES opens existing "Manage Services" submenu
- [ ] Manage scripts execute directly (no SCRIPT_COMMANDS submenu)

### Documentation Generation
- [ ] dev-docs.sh produces docs/commands.md
- [ ] CI fails if commands.md is out of date

### Documentation
- [ ] `docs/contributors/manage-scripts.md` created for maintainers
- [ ] CREATING-SCRIPTS.md clarifies it's for additions/ only
- [ ] All generate-manual.sh references updated to dev-docs.sh

---

## Files to Create

- `.devcontainer/manage/dev-test.sh` (new wrapper)
- `docs/contributors/manage-scripts.md` (maintainer documentation)

## Files to Rename

- `.devcontainer/manage/generate-manual.sh` → `.devcontainer/manage/dev-docs.sh`

## Files to Modify

**Add categories:**
- `.devcontainer/additions/lib/categories.sh`

**Add metadata:**
- `.devcontainer/manage/dev-setup.sh`
- `.devcontainer/manage/dev-help.sh`
- `.devcontainer/manage/dev-update.sh`
- `.devcontainer/manage/dev-services.sh`
- `.devcontainer/manage/dev-template.sh`
- `.devcontainer/manage/dev-check.sh`
- `.devcontainer/manage/dev-env.sh`
- `.devcontainer/manage/dev-clean.sh`
- `.devcontainer/manage/dev-docs.sh` (after rename)

**Update scanner:**
- `.devcontainer/additions/lib/component-scanner.sh`

**Update PATH/symlinks:**
- `.devcontainer/additions/lib/environment-utils.sh` (add dev-docs, dev-test to commands array)

**Update menu:**
- `.devcontainer/manage/dev-setup.sh` (also needs menu changes)

**Update CI:**
- `.github/workflows/ci-tests.yml`

**Update documentation references:**
- `docs/contributors/CI-CD.md`
- `docs/contributors/testing.md`
- `docs/ai-developer/CREATING-SCRIPTS.md`
- `CLAUDE.md` (if it references generate-manual.sh)

**Generated output:**
- `docs/commands.md` (will be auto-generated)

---

## Notes

### Excluded Scripts
- `dev-welcome.sh` - internal, runs on container start
- `dev-setup.sh` - excluded from its own menu to avoid recursion
- `postStartCommand.sh` and `postCreateCommand.sh` - devcontainer hooks

### Category Sort Order
- SYSTEM_COMMANDS: 0 (first in menu - most commonly used)
- CONTRIBUTOR_TOOLS: 7 (last in menu - less commonly used)

### Design Decisions
1. **dev-template special case** - only this script shown directly in main menu
2. **All categories open submenus** - including SYSTEM_COMMANDS
3. **No symlink** for generate-manual.sh backwards compatibility
4. **Direct run** for manage scripts (no SCRIPT_COMMANDS submenu)
5. **Keep "Manage Services" submenu** - BACKGROUND_SERVICES opens existing submenu
6. **Upfront scanning** - all script types scanned at startup
