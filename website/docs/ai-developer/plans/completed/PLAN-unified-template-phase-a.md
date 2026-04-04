# Feature: Unified dev-template with Registry Browsing (Phase A)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-04-04

**Goal**: Merge `dev-template.sh` and `dev-template-ai.sh` into one unified `dev-template` command that uses `template-registry.json` for browsing and supports `install_type` routing (app/overlay).

**Last Updated**: 2026-04-04

**Investigation**: `helpers-no/dev-templates` -> `INVESTIGATE-unified-template-system.md` (all three contributors confirmed)

**Depends on**: TMP Phase 1 -- `template-registry.json` published on live Docusaurus site

**No UIS dependency** -- this phase works without UIS. Phase B (separate plan) adds service integration.

---

## Overview

Replace two scripts with one. Replace sparse-checkout-for-browsing with curl-a-small-JSON-file. Route installation by `install_type` field instead of by which script is running.

**Before:**
- `dev-template` -- app templates only, sparse-checkouts entire `templates/` folder
- `dev-template-ai` -- AI templates only, sparse-checkouts entire `ai-templates/` folder
- Two commands, two scripts, hardcoded category routing

**After:**
- `dev-template` -- all DCT templates (app, AI, doc, rules), browses from registry JSON
- `dev-template-ai` -- removed (symlink to `dev-template` with `--context ai` or just removed)
- One command, one script, `install_type` routes to handlers

**Flow:**
1. `curl` registry JSON from TMP Docusaurus site (small file, instant)
2. Filter by `context: dct`, build two-level menu with `jq`
3. User picks category -> template -> details -> confirm
4. Sparse-checkout only the selected template's folder
5. Read `template-info.yaml` for `install_type`, `tools`, `readme`
6. Route to handler: `app` or `overlay`
7. Install tools, replace placeholders, show completion

---

## Phase 1: Fetch and parse registry JSON

### Tasks

- [x] 1.1 Add `fetch_registry()` to `template-common.sh`:
  - Primary: `curl -sL "https://tmp.sovereignsky.no/data/template-registry.json"`
  - Fallback: `curl -sL "https://raw.githubusercontent.com/helpers-no/dev-templates/main/website/src/data/template-registry.json"`
  - Save to `$TEMP_DIR/registry.json`
  - Error handling: clear message if both URLs fail
- [x] 1.2 Add `parse_registry_categories()` -- extract DCT categories using `jq`:
  - Filter by `context: dct`
  - Build `CAT_IDS[]`, `CAT_NAMES[]`, `CAT_EMOJIS[]`, `CAT_COUNTS[]` from JSON
- [x] 1.3 Add `parse_registry_templates()` -- extract templates per category:
  - Build `TEMPLATE_DIRS[]`, `TEMPLATE_NAMES[]`, `TEMPLATE_DESCRIPTIONS[]` etc. from JSON
  - Populate `CAT_TEMPLATES[]` with indices per category
- [x] 1.4 Remove `load_template_categories()` (was sourcing bash `TEMPLATE_CATEGORIES`)
- [x] 1.5 Replace `scan_templates()` with registry-based parsing (no directory scanning)

### Validation

Menu builds from registry JSON. No git operations for browsing.

---

## Phase 2: Download only the selected template

### Tasks

- [x] 2.1 After user confirms selection, sparse-checkout only that template's folder:
  - Read `folder` field from registry: `jq -r '.templates[] | select(.id == "...") | .folder'`
  - `git sparse-checkout set "$folder"`
- [x] 2.2 Read `template-info.yaml` from the downloaded template (replaces bash `TEMPLATE_INFO`)
  - Parse with a simple YAML-to-variable approach (or rely on registry JSON which already has all fields)
- [x] 2.3 Copy `template-info.yaml` to project root for all install types (Decision #12)
- [x] 2.4 Remove full-folder sparse-checkout (was downloading everything upfront)

### Validation

Only the selected template folder is downloaded. `template-info.yaml` copied to project.

---

## Phase 3: install_type routing

### Tasks

- [x] 3.1 Add `install_type` handler dispatch in `template-common.sh`:
  ```
  case "$install_type" in
    app)     install_app_template ;;
    overlay) install_overlay_template ;;
  esac
  ```
- [x] 3.2 Move `dev-template.sh` app-specific logic into `install_app_template()`:
  - `verify_template()` -- check manifests/deployment.yaml
  - `copy_template_files()` -- copy to root
  - `setup_github_workflows()` -- copy .github/
  - `merge_gitignore()` -- merge .gitignore
  - `process_template_files()` -- replace `&#123;&#123;GITHUB_USERNAME&#125;&#125;` and `&#123;&#123;REPO_NAME&#125;&#125;` in YAML
- [x] 3.3 Move `dev-template-ai.sh` overlay-specific logic into `install_overlay_template()`:
  - `verify_template()` -- check template/ subdirectory
  - `copy_template_files()` -- copy template/ preserving paths, safe re-run
  - `handle_claude_md()` -- CLAUDE.md conflict handling
  - `rename_project_template()` -- rename project-TEMPLATE.md
  - `process_template_files()` -- replace `&#123;&#123;REPO_NAME&#125;&#125;` in .md files
- [x] 3.4 Both handlers call shared: `install_template_tools()`, show completion with README

### Validation

App templates and overlay templates both work through the unified command.

---

## Phase 4: Merge into one script

### Tasks

- [x] 4.1 Create unified `dev-template.sh` with:
  - `fetch_registry()` instead of `download_template_repo()`+`scan_templates()`
  - `select_template()` using registry-based two-level menu
  - `install_type` dispatch after selection
  - Both `detect_and_validate_repo_info()` variants (app needs GIT_ORG, overlay only needs GIT_REPO)
  - Both `cleanup_and_complete()` variants (app vs overlay completion messages)
- [x] 4.2 Remove `dev-template-ai.sh`
- [x] 4.3 Remove `dev-template-ai` symlink from Dockerfile
- [x] 4.4 Update `--help` text to show all template types
- [x] 4.5 Keep backward compatibility: `dev-template plan-based-workflow` (direct selection by name still works across all template types)

### Validation

One `dev-template` command handles all DCT template types.

---

## Phase 5: Testing

### Tasks

- [x] 5.1 Test `dev-template` interactive -- two-level menu shows all DCT categories (app + AI)
- [x] 5.2 Test `dev-template python-basic-webserver` -- direct selection, app install_type
- [x] 5.3 Test `dev-template plan-based-workflow` -- direct selection, overlay install_type
- [x] 5.4 Test `dev-template jalla` -- error lists all available templates
- [x] 5.5 Test ESC navigation at all levels
- [x] 5.6 Test tool install (TEMPLATE_TOOLS) works for both types
- [x] 5.7 Test TEMPLATE_README shows in completion for both types
- [x] 5.8 Test CLAUDE.md conflict handling (overlay type)
- [x] 5.9 Test `--help` shows unified help
- [x] 5.10 Verify `dev-template-ai` command no longer exists
- [x] 5.11 Test registry fallback URL when primary fails

### Validation

All tests pass. One command replaces two. No regression.

---

## Acceptance Criteria

- [x] Single `dev-template` command handles app and overlay templates
- [x] Registry JSON fetched via curl -- no git operations for browsing
- [x] Only selected template downloaded via sparse-checkout
- [x] `install_type: app` routes to app handler (manifests, workflows, gitignore)
- [x] `install_type: overlay` routes to overlay handler (template/ copy, CLAUDE.md, safe re-run)
- [x] `template-info.yaml` copied to project root for all types
- [x] Direct selection by name works across all template types
- [x] Tool install and README display work for both types
- [x] `dev-template-ai` removed
- [x] `--help` updated
- [x] Backward compatible -- existing templates work unchanged

---

## Files to Modify

- `.devcontainer/manage/lib/template-common.sh` -- registry parsing, install_type dispatch, handlers
- `.devcontainer/manage/dev-template.sh` -- unified script
- `.devcontainer/manage/dev-template-ai.sh` -- **deleted**
- `image/Dockerfile` -- remove `dev-template-ai` symlink
