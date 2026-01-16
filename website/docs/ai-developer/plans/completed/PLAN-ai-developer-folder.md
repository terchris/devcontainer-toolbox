# Plan: AI Developer Documentation Folder

## Status: Completed

**Goal**: Create a dedicated `docs/ai-developer/` folder for AI coding assistants (Claude, Copilot, etc.) with workflow and plan documentation.

**Priority**: High

**Completed**: 2026-01-15

---

## Problem

Current state:
- `PLANS.md` and `WORKFLOW.md` are in `docs/contributors/` mixed with human-focused docs
- `CLAUDE.md` references `docs/contributors/PLANS.md`
- The `plans/` folder is under `docs/contributors/`

Goal:
- Separate AI-specific workflow docs into `docs/ai-developer/`
- Keep human contributor docs focused on technical documentation
- Make it clear where AI assistants should look for instructions

---

## Phase 1: Create AI Developer Folder Structure — ✅ DONE

### Tasks

- [x] 1.1 Create `docs/ai-developer/` folder

- [x] 1.2 Move `docs/contributors/PLANS.md` to `docs/ai-developer/PLANS.md`

- [x] 1.3 Move `docs/contributors/WORKFLOW.md` to `docs/ai-developer/WORKFLOW.md`

- [x] 1.4 Move `docs/contributors/plans/` folder to `docs/ai-developer/plans/`

### Validation

```bash
ls -la docs/ai-developer/
ls -la docs/ai-developer/plans/
```

User confirms folder structure is correct.

---

## Phase 2: Create AI Developer README — ✅ DONE

### Tasks

- [x] 2.1 Create `docs/ai-developer/README.md` with:
  - Purpose of the folder (instructions for AI coding assistants)
  - Index of documents (PLANS.md, WORKFLOW.md)
  - Link to plans/ folder structure
  - Quick reference for common tasks

### Validation

User confirms README.md provides clear navigation for AI assistants.

---

## Phase 3: Update References — ✅ DONE

### Tasks

- [x] 3.1 Update `CLAUDE.md` to reference `docs/ai-developer/` instead of `docs/contributors/`

- [x] 3.2 Update `docs/contributors/README.md`:
  - Remove PLANS.md and WORKFLOW.md from structure listing
  - Remove from Workflow table
  - Add link to `docs/ai-developer/` for AI workflow docs
  - Keep plans section but note location moved

- [x] 3.3 Update any internal links in moved files (PLANS.md, WORKFLOW.md)

### Validation

```bash
grep -r "contributors/PLANS" docs/ CLAUDE.md
grep -r "contributors/WORKFLOW" docs/ CLAUDE.md
```

User confirms no broken references remain.

---

## Acceptance Criteria

- [x] `docs/ai-developer/` folder exists with PLANS.md, WORKFLOW.md, README.md
- [x] `docs/ai-developer/plans/` contains backlog/, active/, completed/
- [x] `CLAUDE.md` references the new location
- [x] `docs/contributors/README.md` updated with link to ai-developer/
- [x] No broken internal links

---

## Final Structure

```
docs/ai-developer/
├── README.md                 # Index for AI assistants
├── PLANS.md                  # How to write and manage plans
├── WORKFLOW.md               # Issue to implementation flow
└── plans/
    ├── active/               # Currently being worked on
    ├── backlog/              # Planned but not started
    └── completed/            # Implemented plans
```

---

## Files to Create

- `docs/ai-developer/README.md`

## Files to Move

- `docs/contributors/PLANS.md` → `docs/ai-developer/PLANS.md`
- `docs/contributors/WORKFLOW.md` → `docs/ai-developer/WORKFLOW.md`
- `docs/contributors/plans/` → `docs/ai-developer/plans/`

## Files to Modify

- `CLAUDE.md`
- `docs/contributors/README.md`
