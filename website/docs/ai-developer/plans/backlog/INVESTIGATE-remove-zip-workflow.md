# Investigate: Remove dev_containers.zip Workflow

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Remove the unused `dev_containers.zip` creation and GitHub release from the CI pipeline.

**Priority**: Low — no user impact, just CI cleanup

**Last Updated**: 2026-04-07

---

## Problem

The `zip_dev_setup.yml` workflow creates `dev_containers.zip` and publishes it as a GitHub release on every successful CI run. But nothing downloads this zip anymore:

- `install.sh` downloads `devcontainer-user-template.json` directly from GitHub (not from the zip)
- `install.ps1` does the same
- `dev-sync` was removed (it was the only consumer of the zip)

The workflow still does two useful things that should be preserved:
1. Replaces `TOOLBOX_REPO_PLACEHOLDER` in `install.sh` / `install.ps1` with the actual repo URL
2. Commits the updated install scripts

## What to Remove

- Zip creation (`zip -r dev_containers.zip .devcontainer .devcontainer.extend`)
- GitHub release creation (delete old release + create new one with zip)
- Upload artifact step
- `.devcontainer/.version` file creation (was read by `dev-sync`, no longer needed)

## What to Keep

- `install.sh` / `install.ps1` repo URL replacement (still needed)
- Commit updated install scripts (still needed)

## What to Rename

The workflow is called "Zip and Upload Artifacts" — should be renamed to something like "Update Install Scripts" since that's all it will do.

---

## Next Steps

- [ ] Verify: confirm nothing else downloads `dev_containers.zip` (search GitHub for references)
- [ ] Simplify `zip_dev_setup.yml`: remove zip, release, artifact upload, .version file
- [ ] Rename workflow to "Update Install Scripts"
- [ ] Update `ci-pipeline.md` documentation
- [ ] Remove the existing `latest` GitHub release (cleanup)
