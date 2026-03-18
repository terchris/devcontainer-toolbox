# Plan: Update dev-template.sh after urbalurba-dev-templates rename

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Update all references from `urbalurba-dev-templates` to `dev-templates` after the repo is renamed on GitHub.

**Priority**: High

**Last Updated**: 2026-03-18

**Completed**: 2026-03-18

**Overall plan**: See `/Users/terje.christensen/learn/projects-2026/testing/github-helpers-no/INVESTIGATE-move-repos-to-helpers-no.md`

**Report back**: After completing, update the overall plan file above.

---

## Prerequisites

- **urbalurba-dev-templates must be transferred to helpers-no AND renamed to `dev-templates`** before this plan is implemented
- Check that `https://github.com/helpers-no/dev-templates` exists before starting

---

## Problem

The `dev-template.sh` script and several docs/plans reference the repo as `urbalurba-dev-templates`. After the repo is renamed to `dev-templates` under `helpers-no`, these references need updating. GitHub redirects will cover the old name temporarily, but the code should use the canonical name.

---

## Phase 1: Update references — ✅ DONE

### Tasks

- [x] 1.1 Update `dev-template.sh` runtime reference:
  - `.devcontainer/manage/dev-template.sh` line 111: `local template_repo="urbalurba-dev-templates"` → `local template_repo="dev-templates"`
- [x] 1.2 Search for any other runtime references — zero other runtime hits
- [x] 1.3 Update docs/plan references:
  - `ISSUE-urbalurba-dev-templates-cicd.md` — updated title and download URL
  - `PLAN-007-templates-integration.md` — updated all references
  - Completed plans left as-is (historical)
- [x] 1.4 Commit changes

### Validation

`grep -r "urbalurba-dev-templates" --include="*.sh" --include="*.ps1" --include="*.json" --include="*.ts" .` returns zero hits.

---

## Acceptance Criteria

- [x] `dev-template.sh` uses `dev-templates` as the repo name
- [ ] Template download works: `dev-template` command successfully fetches from `helpers-no/dev-templates` (needs testing in devcontainer)
- [x] No remaining `urbalurba-dev-templates` in runtime scripts

---

## Files to Modify

**Critical:**
- `.devcontainer/manage/dev-template.sh`

**Docs (update for correctness):**
- `website/docs/ai-development/ai-developer/plans/backlog/ISSUE-urbalurba-dev-templates-cicd.md`
- `website/docs/ai-development/ai-developer/plans/backlog/PLAN-007-templates-integration.md`
- Completed plan/investigation files that reference the old name
