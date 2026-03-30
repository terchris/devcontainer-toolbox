# Fix: Make dev-template work without a git repo

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Allow `dev-template` to run on fresh machines without requiring a git repo or GitHub login.

**Last Updated**: 2026-02-19

**GitHub Issue**: #63 (follow-up)

**Investigation**: [INVESTIGATE-dev-template-no-git-required.md](INVESTIGATE-dev-template-no-git-required.md)

**Priority**: High — the zip download fix alone is not enough for fresh machines

---

## Problem

`dev-template` calls `detect_github_info()` at startup which exits if not inside a git repo. On a fresh machine, users can't even browse templates. The `{{GITHUB_USERNAME}}` and `{{REPO_NAME}}` placeholders in manifest and workflow files are already replaced by GitHub Actions at CI/CD time — the replacement in `dev-template` is redundant.

---

## Phase 1: Remove all git dependencies from dev-template — ✅ DONE

### Tasks

- [x] 1.1 Remove `detect_github_info()` function
- [x] 1.2 Remove `replace_placeholders()` function
- [x] 1.3 Remove `process_essential_files()` function
- [x] 1.4 Remove the calls from main execution
- [x] 1.5 Bump `SCRIPT_VERSION` to 1.5.0

### Validation

```bash
# Run from a directory with no git repo — should work end to end
cd /tmp && mkdir test && cd test && dev-template
```

---

## Acceptance Criteria

- [x] No `git` commands anywhere in the script
- [ ] `dev-template` runs on a fresh machine with no git repo
- [ ] Templates can be browsed, selected, and copied without any dependency on git or GitHub auth
- [x] Template files are copied as-is (CI/CD handles placeholder replacement at build time)

---

## Files to Modify

- `.devcontainer/manage/dev-template.sh` — remove `detect_github_info()`, `replace_placeholders()`, `process_essential_files()`
