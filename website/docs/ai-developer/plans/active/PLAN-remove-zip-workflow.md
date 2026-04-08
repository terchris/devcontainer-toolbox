# Plan: Remove Zip Workflow and Clean Up Dead Code

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Remove the unused `zip_dev_setup.yml` workflow and all related dead code. Clean up documentation.

**Priority**: Medium — dead CI running on every merge, outdated docs confusing contributors

**Last Updated**: 2026-04-07

**Investigation**: [INVESTIGATE-remove-zip-workflow.md](../backlog/INVESTIGATE-remove-zip-workflow.md) — all questions answered

---

## Overview

The `zip_dev_setup.yml` workflow is entirely dead:
- The zip is not downloaded by anything (`dev-sync` removed, `install.sh` uses direct download)
- The `TOOLBOX_REPO_PLACEHOLDER` replacement is a no-op (already hardcoded in install scripts)
- The `.devcontainer/.version` file is not read by anything useful
- The GitHub release with `dev_containers.zip` is not consumed

This wastes CI minutes on every merge and confuses contributors reading the docs.

---

## Phase 1: Remove workflow and dead files — IN PROGRESS

### Tasks

- [x] 1.1 Deleted `.github/workflows/zip_dev_setup.yml`
- [x] 1.2 `.devcontainer/.version` does not exist in repo — confirmed
- [x] 1.3 Hardcoded `TOOLBOX_REPO` in `version-utils.sh`, removed `.devcontainer/.version` read path
- [ ] 1.4 Remove the `latest` GitHub release and tag from the repo (manual task — needs `gh release delete latest`)
- [x] 1.5 Verified: only `zip_dev_setup.yml` references `workflow_run` — no other workflow depends on it

### Validation

CI no longer runs zip workflow. `dev-help` still shows correct version.

---

## Phase 2: Update documentation — IN PROGRESS

### Tasks

- [x] 2.1 Deleted `website/docs/contributors/ci-cd.md`
- [x] 2.1b Updated 6 files that linked to ci-cd: CREATING-SCRIPTS.md, README.md, WORKFLOW.md, testing.md, contributors/index.md
- [x] 2.2 Updated `ci-pipeline.md`: removed Workflow 3, updated mermaid diagram, removed zip from auto-generated files table, workflow files table, race conditions section, "Four" → "Three"
- [x] 2.3 Updated `releasing.md`: removed zip/release references, replaced .devcontainer/.version row with deploy-docs row
- [x] 2.4 `configuration.md` has no zip references — confirmed

### Validation

All contributor docs accurately describe the 3-workflow CI pipeline.

---

## Phase 3: Verify nothing breaks — IN PROGRESS

### Tasks

- [x] Static check: `version-utils.sh` syntax OK
- [x] Static check: `_load_version_info` returns correct version (1.7.31) and hardcoded TOOLBOX_REPO
- [x] Grep: no live code references `zip_dev_setup`, `TOOLBOX_REPO_PLACEHOLDER`, or `.devcontainer/.version` (only historical completed plans)
- [ ] 3.1 Push changes, verify CI Tests + Build Image + Deploy Docs all pass
- [ ] 3.2 Run `dev-help` in a container — version shows correctly (after rebuild)
- [ ] 3.3 Run `dev-update --check` — update check works (TOOLBOX_REPO fallback)
- [ ] 3.4 Run `install.sh` on a fresh folder — still works (no zip dependency)

### Validation

All CI green, all commands work, install script works.

---

## Acceptance Criteria

- [ ] `zip_dev_setup.yml` deleted
- [ ] `.devcontainer/.version` removed
- [ ] `version-utils.sh` has hardcoded `TOOLBOX_REPO` fallback
- [ ] `ci-cd.md` deleted (replaced by `ci-pipeline.md`)
- [ ] `ci-pipeline.md` updated for 3 workflows
- [ ] `releasing.md` updated — no zip references
- [ ] CI passes, `dev-help` works, `dev-update --check` works, `install.sh` works
- [ ] `latest` GitHub release removed
