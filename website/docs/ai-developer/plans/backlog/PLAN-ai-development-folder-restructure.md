# Feature: Restructure ai-development folder

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

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
├── index.md                    ← unique intro page
├── creating-plans.md           ← DUPLICATE of ai-developer/PLANS.md
├── workflow.md                 ← DUPLICATE of ai-developer/WORKFLOW.md
├── ai-developer/               ← the real content
│   ├── PLANS.md, WORKFLOW.md, etc.
│   └── plans/
└── ai-docs/
    ├── developing-using-ai.md  ← DUPLICATE of index.md
    └── CREATING-RECORDINGS.md  ← unique
```

**After:**
```
website/docs/ai-developer/
├── index.md                    ← moved from ai-development/index.md
├── PLANS.md                    ← kept
├── WORKFLOW.md                 ← kept
├── CREATING-SCRIPTS.md         ← kept
├── CREATING-TOOL-PAGES.md      ← kept
├── CREATING-RECORDINGS.md      ← moved from ai-docs/
├── README.md                   ← kept
├── _category_.json             ← updated
└── plans/                      ← kept (backlog, active, completed)
```

---

## Phase 1: Move files and delete duplicates

### Tasks

- [ ] 1.1 Move `website/docs/ai-developer/` to `website/docs/ai-developer/`
- [ ] 1.2 Move `website/docs/ai-development/index.md` to `website/docs/ai-developer/index.md`
- [ ] 1.3 Move `website/docs/ai-development/ai-docs/CREATING-RECORDINGS.md` to `website/docs/ai-developer/CREATING-RECORDINGS.md`
- [ ] 1.4 Delete `website/docs/ai-development/` entirely (duplicates: `creating-plans.md`, `workflow.md`, `ai-docs/developing-using-ai.md`, and category json files)
- [ ] 1.5 Update `website/docs/ai-developer/_category_.json`:
  - Change label from "AI Developer (Internal)" to "AI Development"
  - Update doc ID from `ai-developer/README` to `ai-developer/README`
  - Set position to 5 (same as old ai-development category)

### Validation

Verify folder structure matches the "After" diagram above.

---

## Phase 2: Update CLAUDE.md

### Tasks

- [ ] 2.1 Update all 6 path references in `CLAUDE.md`:
  - `website/docs/ai-developer/PLANS.md` → `website/docs/ai-developer/PLANS.md`
  - `website/docs/ai-developer/WORKFLOW.md` → `website/docs/ai-developer/WORKFLOW.md`
  - `website/docs/ai-developer/CREATING-SCRIPTS.md` → `website/docs/ai-developer/CREATING-SCRIPTS.md`
  - `website/docs/ai-developer/plans/` → `website/docs/ai-developer/plans/`
  - `website/docs/ai-developer/` → `website/docs/ai-developer/`

### Validation

Verify CLAUDE.md paths are correct.

---

## Phase 3: Update React components and contributor docs

### Tasks

- [ ] 3.1 Update `website/src/components/AiDemo/index.tsx` line 24:
  - `to="/docs/ai-development"` → `to="/docs/ai-developer"`
- [ ] 3.2 Update `website/src/components/HomepageFeatures/index.tsx` line 44:
  - `link: '/docs/ai-development/'` → `link: '/docs/ai-developer/'`
- [ ] 3.3 Update `website/docs/contributors/website.md` line 47:
  - `ai-development/` → `ai-developer/` in directory tree

### Validation

User confirms component links are correct.

---

## Phase 4: Update internal doc links

### Tasks

- [ ] 4.1 Update `website/docs/ai-developer/WORKFLOW.md` — replace `ai-developer/` with `ai-developer/` in 3 references
- [ ] 4.2 Update `website/docs/ai-developer/PLANS.md` — replace `ai-developer/` with `ai-developer/` in 2 references
- [ ] 4.3 Update `website/docs/ai-developer/index.md` — fix any relative links that broke from the move (links to `creating-plans` and `workflow` should now point to `PLANS` and `WORKFLOW` since duplicates are gone)

### Validation

User confirms links work.

---

## Phase 5: Update plan files (historical references)

### Tasks

- [ ] 5.1 Update path references in plan files — bulk replace `ai-developer/` with `ai-developer/` in:
  - 9 completed plan files
  - 2 backlog plan files
  - The investigation file itself

### Validation

Grep confirms no remaining `ai-development/ai-developer` references.

---

## Phase 6: Build and verify

### Tasks

- [ ] 6.1 Run `cd website && npm run build` to verify no broken links
- [ ] 6.2 Verify Docusaurus sidebar shows "AI Development" at correct position
- [ ] 6.3 Grep entire repo for any remaining `ai-development` references

### Validation

Build succeeds with no broken link errors.

---

## Acceptance Criteria

- [ ] `website/docs/ai-developer/` exists with all content
- [ ] `website/docs/ai-development/` is completely removed
- [ ] No duplicate files remain
- [ ] CLAUDE.md paths are correct
- [ ] Homepage links work (`/docs/ai-developer`)
- [ ] Docusaurus build succeeds (no broken links)
- [ ] No remaining references to old `ai-developer/` path
- [ ] Sidebar shows "AI Development" category at correct position

---

## Files to Modify

**Move:**
- `website/docs/ai-developer/` → `website/docs/ai-developer/`
- `website/docs/ai-development/index.md` → `website/docs/ai-developer/index.md`
- `website/docs/ai-development/ai-docs/CREATING-RECORDINGS.md` → `website/docs/ai-developer/CREATING-RECORDINGS.md`

**Delete:**
- `website/docs/ai-development/` (entire folder after moves)

**Update:**
- `CLAUDE.md`
- `website/src/components/AiDemo/index.tsx`
- `website/src/components/HomepageFeatures/index.tsx`
- `website/docs/contributors/website.md`
- `website/docs/ai-developer/_category_.json`
- `website/docs/ai-developer/WORKFLOW.md`
- `website/docs/ai-developer/PLANS.md`
- `website/docs/ai-developer/index.md`
- 11 plan files in backlog/ and completed/
