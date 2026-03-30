# Feature: dev-template-ai.sh — AI Workflow Template Installer

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Create `dev-template-ai.sh` that installs AI workflow templates from `helpers-no/dev-templates` into any project, following the same UX as `dev-template.sh`.

**Last Updated**: 2026-03-30

**Investigation**: [INVESTIGATE-ai-workflow-installer.md](../completed/INVESTIGATE-ai-workflow-installer.md) (to be moved to completed)

---

## Overview

`dev-template-ai.sh` is a parallel script to `dev-template.sh` v1.6.0 that installs AI workflow templates instead of app templates. It downloads from the same `helpers-no/dev-templates` repo but scans `ai-templates/` instead of `templates/`.

**Key differences from `dev-template.sh`:**
- Scans `ai-templates/` instead of `templates/`
- Copies `template/` subdirectory contents (not template root)
- No `manifests/deployment.yaml` validation
- No `.gitignore` merge, no `.github/workflows` copy
- Only `{{REPO_NAME}}` placeholder in `.md` files (not YAML)
- Special CLAUDE.md conflict handling
- Safe re-run: overwrite template-owned docs, never overwrite user plans
- Renames `project-TEMPLATE.md` to `project-{repo-name}.md`

**First template available:** `plan-based-workflow` — structured AI development with plans, phases, and validation.

---

## Phase 1: Create script skeleton with metadata and prerequisites

### Tasks

- [ ] 1.1 Create `.devcontainer/manage/dev-template-ai.sh` with script metadata:
  - `SCRIPT_ID="dev-template-ai"`
  - `SCRIPT_NAME="AI Templates"`
  - `SCRIPT_DESCRIPTION="Install AI workflow templates into your project"`
  - `SCRIPT_CATEGORY="SYSTEM_COMMANDS"`
  - `SCRIPT_VERSION="1.0.0"`
- [ ] 1.2 Add path resolution block (same pattern as `dev-template.sh`):
  - `CALLER_DIR`, `SCRIPT_DIR`, `DEVCONTAINER_DIR`, `ADDITIONS_DIR`
- [ ] 1.3 Source `git-identity.sh` from `$ADDITIONS_DIR/lib/`
- [ ] 1.4 Add `check_prerequisites()` — require `dialog` and `unzip`
- [ ] 1.5 Add `detect_and_validate_repo_info()` — only needs `GIT_REPO` (not `GIT_ORG`)
- [ ] 1.6 Add `display_intro()` banner
- [ ] 1.7 Make script executable

### Validation

`dev-template-ai.sh --help` works, prerequisites check runs.

---

## Phase 2: Template download and scanning

### Tasks

- [ ] 2.1 Add `download_templates()` — download `helpers-no/dev-templates` zip (same as `dev-template.sh`)
- [ ] 2.2 Add `read_template_info()` — read `TEMPLATE_INFO` from each subfolder (reuse pattern)
- [ ] 2.3 Add `scan_templates()` — scan `ai-templates/*/` directories instead of `templates/*/`
  - Build parallel arrays: `TEMPLATE_DIRS`, `TEMPLATE_NAMES`, `TEMPLATE_DESCRIPTIONS`, `TEMPLATE_CATEGORIES`, `TEMPLATE_PURPOSES`
- [ ] 2.4 Add `verify_template()` — check `template/` subdirectory exists (no manifests check)

### Validation

Script downloads repo, finds `plan-based-workflow` template, reads its TEMPLATE_INFO.

---

## Phase 3: Dialog menu and template selection

### Tasks

- [ ] 3.1 Add `show_template_menu()` — dialog menu grouped by category (reuse pattern from `dev-template.sh`)
- [ ] 3.2 Add `show_template_details()` — show name, category, description, purpose; confirm selection
- [ ] 3.3 Add `select_template()` — loop until user confirms or cancels
- [ ] 3.4 Support direct selection via command-line argument: `dev-template-ai.sh plan-based-workflow`

### Validation

User can browse templates, see details, and confirm selection.

---

## Phase 4: File copy with safe re-run logic

### Tasks

- [ ] 4.1 Add `copy_template_files()` — copy `template/` contents to `$CALLER_DIR/` preserving directory structure, with rules:
  - Always overwrite template-owned docs: `README.md`, `WORKFLOW.md`, `PLANS.md`, `DEVCONTAINER.md`, `GIT.md`, `TALK.md`, `project-TEMPLATE.md`
  - Never overwrite user-renamed `project-*.md` files (anything other than `project-TEMPLATE.md`)
  - Never overwrite anything in `plans/` subdirectories (backlog/, active/, completed/) — user's work
  - Create `plans/` directories with `.gitkeep` only if they don't exist
- [ ] 4.2 Add `handle_claude_md()` — CLAUDE.md conflict handling:
  - If `$CALLER_DIR/CLAUDE.md` exists: delete the copied one, keep `docs/ai-developer/CLAUDE-template.md`, print merge instructions
  - If no existing CLAUDE.md: keep the copied one, delete `CLAUDE-template.md`
- [ ] 4.3 Add `rename_project_template()` — rename `project-TEMPLATE.md` to `project-{GIT_REPO}.md` if it was copied

### Validation

User confirms: files copied correctly, CLAUDE.md handling works both ways, project file renamed.

---

## Phase 5: Placeholder replacement and cleanup

### Tasks

- [ ] 5.1 Add `replace_placeholders()` — replace `{{REPO_NAME}}` with `$GIT_REPO` in `.md` files
- [ ] 5.2 Add `process_template_files()` — process all `.md` files under `$CALLER_DIR/docs/ai-developer/` and `$CALLER_DIR/CLAUDE.md`
- [ ] 5.3 Add `cleanup_and_complete()` — remove temp dir, show completion message with next steps
- [ ] 5.4 Wire up the main execution flow:
  1. Parse args
  2. `check_prerequisites`
  3. `detect_and_validate_repo_info`
  4. `display_intro`
  5. `download_templates`
  6. `scan_templates`
  7. `select_template`
  8. `verify_template`
  9. `copy_template_files`
  10. `handle_claude_md`
  11. `rename_project_template`
  12. `process_template_files`
  13. `cleanup_and_complete`

### Validation

Full end-to-end run: template installed, placeholders replaced, CLAUDE.md handled, cleanup done.

---

## Phase 6: Testing

### Tasks

- [ ] 6.1 Test in devcontainer with interactive dialog selection
- [ ] 6.2 Test direct selection: `dev-template-ai.sh plan-based-workflow`
- [ ] 6.3 Test CLAUDE.md conflict: run in project WITH existing CLAUDE.md
- [ ] 6.4 Test CLAUDE.md no-conflict: run in project WITHOUT CLAUDE.md
- [ ] 6.5 Test safe re-run: run twice, verify plans/ not overwritten
- [ ] 6.6 Test placeholder replacement: verify `{{REPO_NAME}}` replaced in all `.md` files
- [ ] 6.7 Verify `dev-help` shows the new command

### Validation

All tests pass.

---

## Acceptance Criteria

- [ ] `dev-template-ai.sh` installs AI workflow template to `docs/ai-developer/`
- [ ] Downloads from `helpers-no/dev-templates` `ai-templates/` folder
- [ ] Interactive dialog menu with category grouping
- [ ] Direct selection via command-line argument
- [ ] `{{REPO_NAME}}` replaced in all `.md` files
- [ ] CLAUDE.md conflict handling works correctly
- [ ] Safe re-runs: template docs overwritten, user plans preserved
- [ ] `project-TEMPLATE.md` renamed to `project-{repo-name}.md`
- [ ] Prerequisites checked (dialog, unzip)
- [ ] Cleanup removes temp directory
- [ ] Script metadata present for component scanner
- [ ] Visible in `dev-help`

---

## Files to Create/Modify

- `.devcontainer/manage/dev-template-ai.sh` (new)
