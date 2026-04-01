# Feature: Show template README instructions after install

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-04-01

**Goal**: After template install, tell the user exactly how to read the template's README with a copy-paste command.

**Last Updated**: 2026-03-30

---

## Problem

After installing a template, the user sees tool-specific post-install messages (e.g., PHP installer says `composer run dev` which doesn't work for a basic PHP template). The template's README has the correct instructions, but the user isn't told to read it.

Additionally, when tools are installed, the user needs to run `source ~/.bashrc` to update their PATH — but this is buried in the tool output.

## Important: completion message must be the last output

Tool install scripts (e.g., PHP) print their own verbose `post_installation_message()` during install — including potentially wrong instructions like `composer run dev`. This output can be very long (tool download, extensions, etc.). The template installer's `✅ Template setup complete!` message with the correct next steps MUST be the final thing the user sees, so it's not lost in the scroll. The current code already puts `cleanup_and_complete()` last in the flow, which is correct. The key is that the completion message overrides/replaces any confusing tool-specific instructions with the template-specific ones.

## Solution

Add `TEMPLATE_README` field to `TEMPLATE_INFO`. The template installer shows clear copy-paste instructions at the end:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Template setup complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Next steps:

   1. Update your terminal (tools were installed):
      source ~/.bashrc

   2. Read the template instructions:
      cat README-php-basic-webserver.md
```

Step 1 only shown if tools were installed. Step 2 only shown if `TEMPLATE_README` is set.

---

## Phase 1: Add TEMPLATE_README to shared library (DCT side) -- DONE

### Tasks

- [x] 1.1 Update `read_template_info()` in `template-common.sh`:
  - Add `INFO_README=""` default
  - Add `TEMPLATE_README` to unset before/after sourcing
  - Read `INFO_README="${TEMPLATE_README:-$INFO_README}"`
  - Rename `TEMPLATE_PURPOSE` → `TEMPLATE_ABSTRACT`: change `INFO_PURPOSE` to `INFO_ABSTRACT`, read from `TEMPLATE_ABSTRACT` instead of `TEMPLATE_PURPOSE` (dev-templates repo is renaming this field simultaneously — no backward compatibility needed)
- [x] 1.2 Add `TEMPLATE_README_LIST=()` array to `scan_templates()` in both scripts
- [x] 1.3 Update `cleanup_and_complete()` in `dev-template.sh`:
  - If tools were installed, show: `source ~/.bashrc`
  - If `TEMPLATE_README_LIST[$TEMPLATE_INDEX]` is set, show: `cat {readme-filename}`
- [x] 1.4 Update `cleanup_and_complete()` in `dev-template-ai.sh` — same pattern

### Validation

Completion message shows correct copy-paste commands.

---

## Phase 2: Add TEMPLATE_README to templates (dev-templates side) -- DONE

### Tasks

- [x] 2.1 Add `TEMPLATE_README="README-php-basic-webserver.md"` to PHP template
- [x] 2.2 Add `TEMPLATE_README` to all other app templates
- [x] 2.3 AI templates: add `TEMPLATE_README` if applicable

### Validation

Each template's TEMPLATE_INFO has the correct README filename.

---

## Phase 3: Testing -- DONE

### Tasks

- [x] 3.1 Test PHP template — completion message shows `cat README-php-basic-webserver.md`
- [x] 3.2 Test AI template — no README instruction if not set (backward compatible)
- [x] 3.3 Test template with tools — `source ~/.bashrc` instruction shown
- [x] 3.4 Test template without tools — no `source ~/.bashrc` instruction

### Validation

All tests pass.

---

## Acceptance Criteria

- [x] `TEMPLATE_README` field read from `TEMPLATE_INFO`
- [x] Completion message shows `source ~/.bashrc` when tools were installed
- [x] Completion message shows `cat {readme}` when `TEMPLATE_README` is set
- [x] Backward compatible — templates without `TEMPLATE_README` work as before
- [x] Works in both `dev-template.sh` and `dev-template-ai.sh`

---

## Files to Modify

**DCT side:**
- `.devcontainer/manage/lib/template-common.sh` — read `TEMPLATE_README`
- `.devcontainer/manage/dev-template.sh` — show README in completion, add `TEMPLATE_README_LIST`
- `.devcontainer/manage/dev-template-ai.sh` — same

**dev-templates side (companion):**
- All `TEMPLATE_INFO` files — add `TEMPLATE_README` field
