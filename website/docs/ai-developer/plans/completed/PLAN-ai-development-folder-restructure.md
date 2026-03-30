# Feature: Restructure ai-development folder

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Completed**: 2026-03-30

**Goal**: Move `ai-developer/` up to `website/docs/ai-developer/`, delete duplicate files, and remove `ai-development/` entirely.

**Last Updated**: 2026-03-30

**Investigation**: [INVESTIGATE-ai-development-folder-restructure.md](INVESTIGATE-ai-development-folder-restructure.md)

---

## Overview

The current `website/docs/ai-developer/` nesting is confusing. This plan:
1. Moves `ai-developer/` up one level to `website/docs/ai-developer/`
2. Merges unique content from `ai-development/` into it
3. Deletes 3 duplicate files
4. Removes `ai-development/` entirely
5. Updates all references (CLAUDE.md, React components, internal links, plan files)

**Before:**
```
website/docs/ai-development/
+-- index.md                    -- unique intro page
+-- creating-plans.md           -- DUPLICATE of ai-developer/PLANS.md
+-- workflow.md                 -- DUPLICATE of ai-developer/WORKFLOW.md
+-- ai-developer/               -- the real content
|   +-- PLANS.md, WORKFLOW.md, etc.
|   +-- plans/
+-- ai-docs/
    +-- developing-using-ai.md  -- DUPLICATE of index.md
    +-- CREATING-RECORDINGS.md  -- unique
```

**After:**
```
website/docs/ai-developer/
+-- index.md                    -- moved from ai-development/index.md
+-- PLANS.md                    -- kept
+-- WORKFLOW.md                 -- kept
+-- CREATING-SCRIPTS.md         -- kept
+-- CREATING-TOOL-PAGES.md      -- kept
+-- CREATING-RECORDINGS.md      -- moved from ai-docs/
+-- README.md                   -- kept
+-- _category_.json             -- updated
+-- plans/                      -- kept (backlog, active, completed)
```

---

## Phase 1: Move files and delete duplicates -- DONE

### Tasks

- [x] 1.1 Move `website/docs/ai-development/ai-developer/` to `website/docs/ai-developer/`
- [x] 1.2 Move `website/docs/ai-development/index.md` to `website/docs/ai-developer/index.md`
- [x] 1.3 Move `website/docs/ai-development/ai-docs/CREATING-RECORDINGS.md` to `website/docs/ai-developer/CREATING-RECORDINGS.md`
- [x] 1.4 Delete `website/docs/ai-development/` entirely
- [x] 1.5 Update `website/docs/ai-developer/_category_.json`

### Validation

Folder structure matches the "After" diagram above.

---

## Phase 2: Update CLAUDE.md -- DONE

### Tasks

- [x] 2.1 Update all 6 path references in `CLAUDE.md`

### Validation

CLAUDE.md paths are correct.

---

## Phase 3: Update React components and contributor docs -- DONE

### Tasks

- [x] 3.1 Update `website/src/components/AiDemo/index.tsx`
- [x] 3.2 Update `website/src/components/HomepageFeatures/index.tsx`
- [x] 3.3 Update `website/docs/contributors/website.md`

### Validation

Component links are correct.

---

## Phase 4: Update internal doc links -- DONE

### Tasks

- [x] 4.1 Update `website/docs/ai-developer/WORKFLOW.md` -- fix relative links
- [x] 4.2 Update `website/docs/ai-developer/PLANS.md` -- fix relative links
- [x] 4.3 Update `website/docs/ai-developer/index.md` -- fix links to PLANS and WORKFLOW
- [x] 4.4 Fix `../../contributors/` to `../contributors/` in CREATING-SCRIPTS.md, WORKFLOW.md, README.md (broken by moving up one level)

### Validation

Links work, Docusaurus build succeeds.

---

## Phase 5: Update plan files (historical references) -- DONE

### Tasks

- [x] 5.1 Update path references in 6 plan files (bulk replace)

### Validation

Grep confirms no remaining `ai-development/ai-developer` references.

---

## Phase 6: Build and verify -- DONE

### Tasks

- [x] 6.1 Docusaurus build succeeds (CI Deploy Documentation passed)
- [x] 6.2 Sidebar shows "AI Development" at correct position
- [x] 6.3 No remaining references to old path (except historical notes in completed plans)

### Validation

Build succeeds with no broken link errors. Site deployed to GitHub Pages.

---

## Acceptance Criteria

- [x] `website/docs/ai-developer/` exists with all content
- [x] `website/docs/ai-development/` is completely removed
- [x] No duplicate files remain
- [x] CLAUDE.md paths are correct
- [x] Homepage links work (`/docs/ai-developer`)
- [x] Docusaurus build succeeds (no broken links)
- [x] No remaining references to old path
- [x] Sidebar shows "AI Development" category at correct position
