# Feature: Dynamic Template Categories with Two-Level Menu

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-04-02

**Goal**: Replace hardcoded template categories with dynamic categories from `TEMPLATE_CATEGORIES` file, and implement a two-level menu (category then template) matching dev-setup.sh UX.

**Last Updated**: 2026-04-01

**Investigation**: [INVESTIGATE-template-categories-dynamic.md](INVESTIGATE-template-categories-dynamic.md)

---

## Overview

Both `dev-template.sh` and `dev-template-ai.sh` have hardcoded categories (`WEB_SERVER`, `WEB_APP`, `WORKFLOW`, `OTHER`) with hardcoded emojis. The dev-templates repo has renamed `WEB_SERVER` to `BASIC_WEB_SERVER` -- the current code is broken for web server templates.

**Solution:** Source `TEMPLATE_CATEGORIES` from the downloaded repo and build menus dynamically. Implement a two-level menu matching dev-setup.sh's "Browse and Install Tools" pattern:

1. **Category menu** -- "Basic Web Server Templates (6 templates)"
2. **Template menu** -- templates within selected category
3. **Details dialog** -- confirm selection

Most of the code moves to `lib/template-common.sh` since both scripts need identical behavior. Each script reduces to: set title + subdirectory, call shared functions.

---

## Phase 1: — DONE

Original heading: Add category parsing to shared library

### Tasks

- [x] 1.1 Add `load_template_categories()` function to `template-common.sh`:
  - Source `$TEMPLATE_REPO_DIR/$subdir/TEMPLATE_CATEGORIES`
  - Parse `TEMPLATE_CATEGORY_TABLE` into arrays:
    - `CAT_IDS[]` -- category IDs in display order
    - `CAT_NAMES[]` -- display names (indexed by ID)
    - `CAT_EMOJIS[]` -- emojis (indexed by ID)
    - `CAT_COUNTS[]` -- template count per category (populated during scan)
  - Called by `scan_templates()` before the scan loop

### Validation

Category data loaded from file. `echo ${CAT_NAMES[BASIC_WEB_SERVER]}` returns "Basic Web Server Templates".

---

## Phase 2: — DONE

Original heading: Move scan_templates() to shared library

### Tasks

- [x] 2.1 Move `scan_templates()` to `template-common.sh` -- takes subdirectory as parameter
- [x] 2.2 Call `load_template_categories()` at the start
- [x] 2.3 Replace hardcoded `case` statement with dynamic category grouping:
  - For each template, look up its `INFO_CATEGORY` in `CAT_IDS`
  - Increment `CAT_COUNTS[$category]`
  - Store template index in a per-category list
- [x] 2.4 Remove duplicated `scan_templates()` from both scripts

### Validation

Templates scanned and grouped by dynamic categories. No hardcoded category arrays.

---

## Phase 3: — DONE

Original heading: Implement two-level menu in shared library

### Tasks

- [x] 3.1 Create `show_template_category_menu()` in `template-common.sh`:
  - Takes `title` parameter ("Project Templates" or "AI Workflow Templates")
  - Iterate `CAT_IDS[]` in order, skip categories with 0 templates
  - Show: `"emoji category_name"` with `"N template(s)"` as help text
  - ESC returns non-zero (caller exits)
  - Returns selected category ID
- [x] 3.2 Create `show_templates_in_category()` in `template-common.sh`:
  - Takes `category_id` and `title` parameters
  - Show templates filtered by category
  - On selection, show `show_template_details_dialog()` (already exists)
  - "Yes" sets `TEMPLATE_INDEX`, `SELECTED_TEMPLATE`, `TEMPLATE_PATH` and returns 0
  - "No" goes back to template list
  - ESC returns non-zero (caller goes back to category menu)
- [x] 3.3 Create `select_template_interactive()` in `template-common.sh`:
  - Outer loop: show category menu
  - Inner loop: show templates in category
  - ESC at category level returns non-zero (script exits)
  - ESC at template level goes back to category menu
  - Confirmation breaks out of both loops
  - Sets globals: `TEMPLATE_INDEX`, `SELECTED_TEMPLATE`, `TEMPLATE_PATH`

### Validation

Two-level menu works: category -> template -> details -> confirm. Back navigation works at all levels.

---

## Phase 4: — DONE

Original heading: Move select_template() to shared library

### Tasks

- [x] 4.1 Create shared `select_template()` in `template-common.sh`:
  - Takes: `param_name` (CLI arg or empty), `templates_subdir`, `title`
  - **Direct selection** (param_name set): find by directory name, set globals, error with available list if not found
  - **Interactive** (param_name empty): call `select_template_interactive()`
  - Sets globals: `TEMPLATE_INDEX`, `SELECTED_TEMPLATE`, `TEMPLATE_PATH`
  - Shows "Selected: template_name" and abstract after selection
- [x] 4.2 Remove duplicated `select_template()` from both scripts
- [x] 4.3 Remove duplicated `show_template_menu()` from both scripts

### Validation

Both direct and interactive selection work. Globals set correctly for tool install and README display.

---

## Phase 5: — DONE

Original heading: Simplify both scripts

### Tasks

- [x] 5.1 Update `dev-template.sh`:
  - Remove: `scan_templates()`, `show_template_menu()`, `select_template()`, hardcoded categories
  - Main flow becomes:
    ```
    download_template_repo "templates"
    scan_templates "templates"
    select_template "$SELECTED_TEMPLATE_ARG" "templates" "Project Templates"
    verify_template    # stays -- checks manifests/deployment.yaml
    ...rest unchanged
    ```
- [x] 5.2 Update `dev-template-ai.sh`:
  - Remove: `scan_templates()`, `show_template_menu()`, `select_template()`, hardcoded categories
  - Main flow becomes:
    ```
    download_template_repo "$TEMPLATES_SUBDIR"
    scan_templates "$TEMPLATES_SUBDIR"
    select_template "$SELECTED_TEMPLATE" "$TEMPLATES_SUBDIR" "AI Workflow Templates"
    verify_template    # stays -- checks template/ subdirectory
    ...rest unchanged
    ```
- [x] 5.3 Verify `verify_template()` stays in each script (different validation rules)

### Validation

Both scripts work with minimal code. Shared library handles all menu and scan logic.

---

## Phase 6: — DONE

Original heading: Testing

### Tasks

- [x] 6.1 Test `dev-template` interactive -- two-level menu shows categories then templates
- [x] 6.2 Test `dev-template-ai` interactive -- single category (WORKFLOW), still shows category menu
- [x] 6.3 Test `dev-template python-basic-webserver` -- direct selection bypasses menu
- [x] 6.4 Test `dev-template-ai plan-based-workflow` -- direct selection bypasses menu
- [x] 6.5 Test `dev-template jalla` -- error lists available templates
- [x] 6.6 Test ESC at category level -- exits cleanly with temp dir cleanup
- [x] 6.7 Test ESC at template level -- goes back to category menu
- [x] 6.8 Test "No" at details dialog -- goes back to template list
- [x] 6.9 Test category BASIC_WEB_SERVER appears (renamed from WEB_SERVER)
- [x] 6.10 Verify tool install and README display still work after selection
- [x] 6.11 Verify `--help` still works for both scripts

### Validation

All tests pass. Two-level menu works. No regression in tool install or README.

---

## Acceptance Criteria

- [x] Categories loaded dynamically from `TEMPLATE_CATEGORIES` file
- [x] Two-level menu: category then template (matching dev-setup.sh UX)
- [x] Category names, emojis, and order from `TEMPLATE_CATEGORY_TABLE`
- [x] Empty categories skipped in menu
- [x] ESC navigation: category=exit, template=back to categories, details No=back to templates
- [x] Direct selection by name still works
- [x] Invalid name shows available templates with names
- [x] `TEMPLATE_INDEX`, `SELECTED_TEMPLATE`, `TEMPLATE_PATH` set correctly
- [x] `verify_template()` stays script-specific
- [x] `scan_templates()`, `select_template()`, menu functions all in shared library
- [x] Both scripts reduced to minimal (set title + subdirectory, call shared functions)
- [x] New categories added to dev-templates automatically appear in menu
- [x] Tool install and TEMPLATE_README still work after refactor
- [x] `--help` works for both scripts

---

## Files to Modify

- `.devcontainer/manage/lib/template-common.sh` -- add category parsing, scan, menu, and select functions
- `.devcontainer/manage/dev-template.sh` -- remove duplicated functions, simplify main flow
- `.devcontainer/manage/dev-template-ai.sh` -- remove duplicated functions, simplify main flow
