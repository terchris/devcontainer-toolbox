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

~~The workflow still does two useful things that should be preserved:~~

**Update (2026-04-07):** Further analysis shows the ENTIRE workflow is a no-op:
- `install.sh` already has `REPO="helpers-no/devcontainer-toolbox"` hardcoded (line 6)
- `install.ps1` already has `$repo = "helpers-no/devcontainer-toolbox"` hardcoded (line 8)
- `TOOLBOX_REPO_PLACEHOLDER` no longer exists in either file
- The CI replacement step replaces nothing, the commit step commits nothing

**The entire workflow can be deleted.** Nothing to keep, nothing to rename.

---

## Questions to Answer

### 1. Is copy-mode still supported?

**ANSWERED: No.** All users use the pre-built image. Copy-mode (clone repo + build from `Dockerfile.base`) is only for DCT contributors developing the toolbox itself.

This means `.devcontainer/.version` can be fully removed — no users depend on it.

### 2. Does `version-utils.sh` work without `.devcontainer/.version`?

**ANSWERED: Yes, with one fix.** The fallback chain works:
1. ~~`.devcontainer/.version`~~ — will be removed
2. `$DCT_HOME/version.txt` — image-mode (works, this is the primary path)
3. `../version.txt` — dev devcontainer (works)

But `TOOLBOX_REPO` is only set from `.devcontainer/.version`. Without it, `_check_for_updates()` can't check GitHub for newer versions.

**Fix:** Hardcode `TOOLBOX_REPO` as fallback. It's always `helpers-no/devcontainer-toolbox`. No one forks DCT, and if they did they'd need to change many things anyway.

### 3. What about `website/docs/contributors/ci-cd.md`?

**ANSWERED: Delete it.** `ci-pipeline.md` (created today) replaces it with current, accurate documentation.

### 4. Does Docusaurus use `.devcontainer/.version`?

**ANSWERED: No.** Docusaurus reads `version.txt` (repo root, single version number) at build time via `docusaurus.config.ts`. The `.devcontainer/.version` file (key-value format with VERSION/REPO/UPDATED) is a completely separate file only used by `version-utils.sh`.

### 4. Files that reference the zip (code, not docs)

| File | Reference | Action needed |
|------|-----------|---------------|
| `.github/workflows/zip_dev_setup.yml` | Creates the zip | Simplify workflow |
| `.devcontainer/manage/lib/version-utils.sh` | Reads `.devcontainer/.version` | Add `TOOLBOX_REPO` fallback |
| `website/docs/contributors/ci-cd.md` | Documents the zip | Delete or update |
| `website/docs/contributors/ci-pipeline.md` | Documents Workflow 3 | Update |
| `website/docs/contributors/releasing.md` | References zip + release | Update |
| Completed plans (6 files) | Historical references | No changes needed |

---

## Next Steps

- [x] Verify: nothing downloads `dev_containers.zip` — confirmed (install.sh uses direct download)
- [x] Verify: Docusaurus reads `version.txt`, not `.devcontainer/.version` — confirmed
- [x] All questions answered (2026-04-07)
- [ ] Delete `zip_dev_setup.yml` entirely (everything in it is a no-op)
- [ ] Hardcode `TOOLBOX_REPO="helpers-no/devcontainer-toolbox"` fallback in `version-utils.sh`
- [ ] Remove `.devcontainer/.version` file from repo (if it exists)
- [ ] Delete `website/docs/contributors/ci-cd.md` (replaced by `ci-pipeline.md`)
- [ ] Update `ci-pipeline.md` — remove Workflow 3, update mermaid diagram
- [ ] Update `releasing.md` — remove references to zip and GitHub release
- [ ] Remove the existing `latest` GitHub release from GitHub (cleanup)
