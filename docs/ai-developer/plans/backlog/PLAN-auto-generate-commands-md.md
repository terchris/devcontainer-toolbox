# Plan: Auto-generate docs/commands.md

## Status: Backlog

**Goal**: Add metadata to dev-*.sh scripts and extend generate-manual.sh to auto-generate docs/commands.md.

**Priority**: Low

**Last Updated**: 2026-01-15

---

## Problem

Currently:
- `docs/tools.md` and `docs/tools-details.md` are auto-generated from install scripts
- `docs/commands.md` is manually written and can get out of sync
- dev-*.sh scripts have no standardized metadata

Goal:
- Add metadata to dev-*.sh scripts (SCRIPT_ID, SCRIPT_NAME, SCRIPT_DESCRIPTION)
- Extend generate-manual.sh to also generate docs/commands.md
- Keep commands.md in sync automatically

---

## Phase 1: Add Metadata to Manage Scripts

Add standardized metadata to each dev-*.sh script.

### Tasks

- [ ] 1.1 Add metadata to `dev-setup.sh`:
  ```bash
  SCRIPT_ID="dev-setup"
  SCRIPT_NAME="Setup Menu"
  SCRIPT_DESCRIPTION="Interactive menu for installing tools and managing services"
  ```

- [ ] 1.2 Add metadata to `dev-help.sh`:
  ```bash
  SCRIPT_ID="dev-help"
  SCRIPT_NAME="Help"
  SCRIPT_DESCRIPTION="Show available commands and version info"
  ```

- [ ] 1.3 Add metadata to `dev-update.sh`:
  ```bash
  SCRIPT_ID="dev-update"
  SCRIPT_NAME="Update"
  SCRIPT_DESCRIPTION="Update devcontainer-toolbox to latest version"
  ```

- [ ] 1.4 Add metadata to `dev-services.sh`:
  ```bash
  SCRIPT_ID="dev-services"
  SCRIPT_NAME="Services"
  SCRIPT_DESCRIPTION="Manage background services (start, stop, status, logs)"
  ```

- [ ] 1.5 Add metadata to `dev-template.sh`:
  ```bash
  SCRIPT_ID="dev-template"
  SCRIPT_NAME="Templates"
  SCRIPT_DESCRIPTION="Create project files from templates"
  ```

- [ ] 1.6 Add metadata to `dev-check.sh`:
  ```bash
  SCRIPT_ID="dev-check"
  SCRIPT_NAME="Check"
  SCRIPT_DESCRIPTION="Validate configuration and credentials"
  ```

- [ ] 1.7 Add metadata to `dev-env.sh`:
  ```bash
  SCRIPT_ID="dev-env"
  SCRIPT_NAME="Environment"
  SCRIPT_DESCRIPTION="Show installed tools and environment info"
  ```

- [ ] 1.8 Add metadata to `dev-clean.sh`:
  ```bash
  SCRIPT_ID="dev-clean"
  SCRIPT_NAME="Clean"
  SCRIPT_DESCRIPTION="Clean up devcontainer resources"
  ```

- [ ] 1.9 Add metadata to `dev-welcome.sh`:
  ```bash
  SCRIPT_ID="dev-welcome"
  SCRIPT_NAME="Welcome"
  SCRIPT_DESCRIPTION="Show welcome message on container start"
  ```

### Validation

```bash
grep "^SCRIPT_ID=" .devcontainer/manage/dev-*.sh
```

User confirms all dev-*.sh files have SCRIPT_ID metadata.

---

## Phase 2: Update generate-manual.sh

Add function to discover manage scripts and generate commands.md.

### Tasks

- [ ] 2.1 Add `MANAGE_DIR` path constant

- [ ] 2.2 Add `discover_manage_scripts()` function to find dev-*.sh scripts

- [ ] 2.3 Add `generate_commands_md()` function to create commands.md content

- [ ] 2.4 Add `generate_commands_content()` to extract --help output from each script

- [ ] 2.5 Call `generate_commands_md()` in main generation logic

- [ ] 2.6 Update help text to mention commands.md output

### Validation

```bash
.devcontainer/manage/generate-manual.sh
cat docs/commands.md
```

User confirms commands.md is created with correct content.

---

## Phase 3: Update CI Workflow

Add commands.md to documentation check.

### Tasks

- [ ] 3.1 Update ci-tests.yml to check commands.md in docs-check job

### Validation

User confirms CI passes and checks commands.md is up to date.

---

## Acceptance Criteria

- [ ] All dev-*.sh scripts have SCRIPT_ID, SCRIPT_NAME, SCRIPT_DESCRIPTION
- [ ] generate-manual.sh produces docs/commands.md
- [ ] CI fails if commands.md is out of date
- [ ] Running generate-manual.sh updates all three files (tools.md, tools-details.md, commands.md)

---

## Files to Modify

**Add metadata:**
- `.devcontainer/manage/dev-setup.sh`
- `.devcontainer/manage/dev-help.sh`
- `.devcontainer/manage/dev-update.sh`
- `.devcontainer/manage/dev-services.sh`
- `.devcontainer/manage/dev-template.sh`
- `.devcontainer/manage/dev-check.sh`
- `.devcontainer/manage/dev-env.sh`
- `.devcontainer/manage/dev-clean.sh`
- `.devcontainer/manage/dev-welcome.sh`

**Update generator:**
- `.devcontainer/manage/generate-manual.sh`

**Update CI:**
- `.github/workflows/ci-tests.yml`

**Generated output:**
- `docs/commands.md` (will be auto-generated)
