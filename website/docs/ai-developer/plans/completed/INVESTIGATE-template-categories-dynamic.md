# Investigate: Dynamic Template Categories from TEMPLATE_CATEGORIES File

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-04-02

**Goal**: Replace hardcoded template categories in `dev-template.sh` and `dev-template-ai.sh` with dynamic categories read from the `TEMPLATE_CATEGORIES` file provided by the dev-templates repo.

**Priority**: High

**Last Updated**: 2026-04-01

**Related**:
- `helpers-no/dev-templates` → `website/docs/ai-developer/plans/backlog/INVESTIGATE-dct-template-metadata-update.md` — the dev-templates side investigation documenting all metadata changes
- The `TEMPLATE_CATEGORIES` file is now available in `templates/TEMPLATE_CATEGORIES` and `ai-templates/TEMPLATE_CATEGORIES` (auto-synced by CI from `scripts/lib/TEMPLATE_CATEGORIES`)

---

## Problem

Both `dev-template.sh` and `dev-template-ai.sh` have **hardcoded categories**:

**`dev-template.sh` (lines ~120-180):**
```bash
declare -g -A CATEGORY_WEB_SERVER
declare -g -A CATEGORY_WEB_APP
declare -g -A CATEGORY_OTHER

case "$INFO_CATEGORY" in
    WEB_SERVER)
        CATEGORY_WEB_SERVER["$(basename "$dir")"]=$idx
        ;;
    WEB_APP)
        CATEGORY_WEB_APP["$(basename "$dir")"]=$idx
        ;;
    *)
        CATEGORY_OTHER["$(basename "$dir")"]=$idx
        ;;
esac
```

**`dev-template-ai.sh`** has the same pattern with `CATEGORY_WORKFLOW` and `CATEGORY_OTHER`.

**The category `WEB_SERVER` has been renamed to `BASIC_WEB_SERVER`** in dev-templates. Templates now use this new value. The hardcoded `WEB_SERVER)` case match will fail and all web server templates will show under "Other".

---

## Solution: Source TEMPLATE_CATEGORIES

The dev-templates repo now provides a `TEMPLATE_CATEGORIES` file in both `templates/` and `ai-templates/`. This file is available after sparse-checkout — no extra download needed.

### File location after download

```
$TEMPLATE_REPO_DIR/templates/TEMPLATE_CATEGORIES
$TEMPLATE_REPO_DIR/ai-templates/TEMPLATE_CATEGORIES
```

### File format

DCT-style `CATEGORY_TABLE` — pipe-delimited, can be sourced as bash:

```bash
# Format: ORDER|ID|NAME|DESCRIPTION|TAGS|LOGO|EMOJI
readonly TEMPLATE_CATEGORY_TABLE="
0|BASIC_WEB_SERVER|Basic Web Server Templates|Minimal web server templates...|webserver backend...|webserver-logo.svg|🌐
1|WEB_APP|Web Application Templates|Frontend web application...|webapp frontend...|webapp-logo.svg|📱
2|WORKFLOW|Workflow Templates|AI-assisted development...|ai workflow...|workflow-logo.svg|🤖
"
```

### How to use it

1. Source the file: `source "$TEMPLATE_REPO_DIR/templates/TEMPLATE_CATEGORIES"`
2. Parse `TEMPLATE_CATEGORY_TABLE` to build dynamic category grouping
3. Use the emoji field for menu display
4. Use the name field for dialog headers
5. No more hardcoded case statements — any new category added to dev-templates automatically works

### Suggested implementation

Move the category parsing to `lib/template-common.sh` since both `dev-template.sh` and `dev-template-ai.sh` need it. Create a function like:

```bash
build_category_groups() {
    # Parse TEMPLATE_CATEGORY_TABLE and create associative arrays dynamically
    # For each category: CATEGORY_<ID> associative array
    # Store category metadata (name, emoji) for menu rendering
}
```

---

## Additional findings from gap analysis

### 1. `show_template_menu()` dialog legend is hardcoded

Line 204 in `dev-template.sh`:
```
"Choose a template (ESC to cancel):\n\n🌐=Web Server  📱=Web App  📦=Other"
```

This legend must be generated dynamically from category emojis and names in `TEMPLATE_CATEGORY_TABLE`.

### 2. `scan_templates()` is duplicated and should become one shared function

Both scripts have nearly identical `scan_templates()` functions. The only difference is the subdirectory path. With dynamic categories, the category grouping code becomes identical too. Move to `lib/template-common.sh` as a function that takes the subdirectory as parameter:

```bash
scan_templates() {
    local templates_subdir="$1"  # "templates" or "ai-templates"
    # ... rest is identical
}
```

This eliminates ~80 lines of duplication.

### 3. `TEMPLATE_CATEGORIES` is available after sparse-checkout

The file is at `$TEMPLATE_REPO_DIR/templates/TEMPLATE_CATEGORIES` (or `ai-templates/TEMPLATE_CATEGORIES`). Source it in `scan_templates()` before the scan loop — no special download needed.

### 4. Match dev-setup.sh category menu pattern

`dev-setup.sh` has a two-level menu: first pick a category, then pick a tool within that category. The template menu currently shows all templates in a flat list grouped by emoji prefix.

dev-setup.sh pattern (from `show_category_menu()` at line 2050):
- Iterates category IDs in defined order (`get_all_category_ids`)
- Skips empty categories (`CATEGORY_COUNTS`)
- Shows category name and count as help text
- Returns selected category key
- Then shows items within that category

**Decision:** Two-level menu, same as dev-setup.sh's "Browse & Install Tools":

1. **Category menu** — shows categories with template count (e.g., "Basic Web Server Templates  (6 templates)")
2. **Template menu** — shows templates within selected category

This matches the existing dev-setup UX. The user already knows this pattern from "Browse & Install Tools" → category → tool. Templates follow the same flow: "Create project from template" → category → template.

Functions needed (following dev-setup.sh pattern):
- `show_template_category_menu()` — like `show_category_menu()` in dev-setup.sh
- `show_templates_in_category()` — like `show_tools_in_category()` in dev-setup.sh
- Loop: category menu → template list → details → confirm (back to category if cancelled)

### 5. Replace `show_template_menu()` with two-level menu in shared library

The current flat `show_template_menu()` is replaced by two functions in `lib/template-common.sh`:

```bash
show_template_category_menu() {
    local title="$1"   # "Project Templates" or "AI Workflow Templates"
    # Show categories with template count, skip empty categories
    # Returns selected category ID
}

show_templates_in_category() {
    local category_id="$1"
    local title="$2"
    # Show templates filtered by category
    # Show template details on selection
    # Returns to category menu if cancelled
}
```

The main selection loop in both scripts becomes:
```bash
while true; do
    category=$(show_template_category_menu "Project Templates")
    show_templates_in_category "$category" "Project Templates"
done
```

### 6. `select_template()` must move to shared library and handle both paths

Both scripts have nearly identical `select_template()` functions. With two-level menu, the interactive path changes but direct selection stays the same. This becomes one shared function:

```bash
select_template() {
    local param_name="$1"
    local templates_subdir="$2"
    local title="$3"

    if [ -n "$param_name" ]; then
        # Direct selection: find by name, error with list if not found
    else
        # Interactive: two-level menu (category → template → details → confirm)
    fi

    # Sets globals: TEMPLATE_INDEX, SELECTED_TEMPLATE, TEMPLATE_PATH
}
```

**Critical:** The function must set `TEMPLATE_INDEX` as a global — the calling script needs it to access `TEMPLATE_TOOLS_LIST[$TEMPLATE_INDEX]`, `TEMPLATE_README_LIST[$TEMPLATE_INDEX]`, etc.

It should also set `TEMPLATE_PATH` since both scripts build the same path: `$TEMPLATE_REPO_DIR/$subdir/$SELECTED_TEMPLATE`.

### 7. ESC/back navigation flow

The full navigation must handle ESC at every level:

```
outer loop:
    category menu → ESC exits script (clean up temp dir)
    inner loop:
        template list in category → ESC goes back to category menu
        template details dialog → "No" goes back to template list
        template details dialog → "Yes" breaks out of both loops
```

### 8. `verify_template()` stays script-specific

`dev-template.sh` checks for `manifests/deployment.yaml`. `dev-template-ai.sh` checks for `template/` subdirectory. These are different validation rules and must stay in each script — they do NOT move to the shared library.

### 9. Single-category note

When there's only 1 category with templates (e.g., `dev-template-ai` currently has only WORKFLOW), the category menu shows just one option. This is consistent with dev-setup.sh behavior — no special handling needed. The user still picks the category, then the template.

---

## Tasks

### Shared library (`lib/template-common.sh`)
- [ ] Source `TEMPLATE_CATEGORIES` in `scan_templates()` from `$TEMPLATE_REPO_DIR/$subdir/TEMPLATE_CATEGORIES`
- [ ] Move `scan_templates()` to shared library — takes subdirectory as parameter
- [ ] Parse `TEMPLATE_CATEGORY_TABLE` dynamically — build category arrays, emoji/name lookup, template counts per category
- [ ] Create `show_template_category_menu()` — show categories with counts, skip empty, ESC exits
- [ ] Create `show_templates_in_category()` — show templates in selected category, details dialog, ESC goes back to categories
- [ ] Move `select_template()` to shared library — handles both direct (by name) and interactive (two-level menu)
- [ ] `select_template()` sets globals: `TEMPLATE_INDEX`, `SELECTED_TEMPLATE`, `TEMPLATE_PATH`
- [ ] Implement full ESC/back navigation: category → templates → details → confirm

### Both scripts
- [ ] Remove hardcoded category arrays, case statements, flat menu, and duplicated functions
- [ ] Both scripts reduce to: set title + subdirectory, call shared `select_template()`
- [ ] `verify_template()` stays in each script (different validation rules)

### Testing
- [ ] Test with current dev-templates categories (BASIC_WEB_SERVER, WEB_APP, WORKFLOW)
- [ ] Test that new categories added to dev-templates automatically appear in category menu
- [ ] Test direct selection by name still works (bypasses menu entirely)
- [ ] Test ESC at category level exits cleanly
- [ ] Test ESC at template level goes back to categories
- [ ] Test "No" at details goes back to template list
- [ ] Test single-category scenario (dev-template-ai with only WORKFLOW)
