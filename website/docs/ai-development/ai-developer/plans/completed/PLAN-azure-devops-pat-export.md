# Fix: Azure DevOps PAT not exported as environment variable

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Ensure `AZURE_DEVOPS_EXT_PAT` is automatically exported on container start so `az devops` commands work without manual setup.

**GitHub Issue**: #48

**Last Updated**: 2026-02-16

**Completed**: 2026-02-16

---

## Problem

The Azure DevOps PAT is stored at `.devcontainer.secrets/env-vars/azure-devops-pat` but is never exported as the `AZURE_DEVOPS_EXT_PAT` environment variable on container startup. This means `az devops` commands fail with authentication errors until the user manually exports it.

The `verify_azure_devops()` function in `config-azure-devops.sh` already handles loading the PAT from storage, exporting it as `AZURE_DEVOPS_EXT_PAT`, and writing it to `~/.bashrc` for new shells. However, the entrypoint (`image/entrypoint.sh`) never calls `config-azure-devops.sh --verify`.

By contrast, git identity is correctly restored because the entrypoint calls `config-git.sh --verify`.

## Solution

Add a call to `config-azure-devops.sh --verify` in the entrypoint, following the same pattern as the existing `config-git.sh --verify` call.

---

## Phase 1: Add Azure DevOps restore to entrypoint — ✅ DONE

### Tasks

- [x] 1.1 In `image/entrypoint.sh`, add a call to `config-azure-devops.sh --verify` after the git identity section (after the `config-git.sh --verify` block around line 69) ✓
- [x] 1.2 Follow the existing pattern: check if the script exists, run with `--verify`, use `|| true` to prevent failures from blocking startup ✓
- [x] 1.3 Add a log line (e.g., "Restoring Azure DevOps configuration...") consistent with the git identity log style ✓

### Validation

Review the entrypoint change and verify:
- The new block follows the same pattern as the git identity block
- It won't fail if `config-azure-devops.sh` doesn't exist (the `if [ -f ... ]` guard)
- It won't block container startup on errors (`|| true`)

User confirms phase is complete.

---

## Acceptance Criteria

- [x] `config-azure-devops.sh --verify` is called from `entrypoint.sh` on container start
- [x] The call is guarded (script existence check + `|| true`)
- [x] When `.devcontainer.secrets/env-vars/azure-devops-pat` exists, `AZURE_DEVOPS_EXT_PAT` is available in shell sessions after container start
- [x] When no PAT file exists, startup proceeds without errors
- [x] Pattern is consistent with existing `config-git.sh --verify` call

---

## Files to Modify

- `image/entrypoint.sh` — add `config-azure-devops.sh --verify` call
