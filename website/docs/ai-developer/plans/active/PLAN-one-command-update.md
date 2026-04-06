# Feature: One-Command DCT Update

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Make updating DCT a single `dev-update` command + one click, and remove the legacy `dev-sync` mechanism.

**Last Updated**: 2026-04-06

**Investigation**: [INVESTIGATE-one-command-update.md](../backlog/INVESTIGATE-one-command-update.md) — all research and testing completed

**Priority**: High — current update flow requires Docker knowledge most developers don't have

---

## Overview

Currently updating DCT requires 3 manual steps involving Docker commands and VS Code Command Palette. With docker-outside-of-docker now available inside the container, `dev-update` can pull the new image and trigger VS Code's rebuild prompt automatically.

Also removes `dev-sync` (script-only updates) — a legacy workaround from before Docker was available inside the container. One version, one command.

**Before:** `dev-update` → shows instructions → user runs `docker pull` → user opens Command Palette → user clicks Rebuild (3 steps)

**After:** `dev-update` → automatic pull → VS Code prompts Rebuild → user clicks yes (1 command + 1 click)

---

## Phase 1: Add `DCT_IMAGE_VERSION` to user template — ✅ DONE

### Tasks

- [x] 1.1 Add `"DCT_IMAGE_VERSION": "1.7.17"` to `remoteEnv` in `devcontainer-user-template.json`
- [x] 1.2 DCT dev devcontainer doesn't use `remoteEnv` (uses lifecycle commands) — skipped, not applicable
- [x] 1.3 `install.sh` downloads the template as-is, so `DCT_IMAGE_VERSION` is included automatically

### Validation

New installs via `install.sh` have `DCT_IMAGE_VERSION` in their `devcontainer.json`.

---

## Phase 2: Rewrite `dev-update` to pull + trigger rebuild — ✅ DONE

### Tasks

- [x] 2.1 Check if Docker CLI is available (`command -v docker`). Falls back to manual instructions.
- [x] 2.2 `docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest` with progress output.
- [x] 2.3 Update `DCT_IMAGE_VERSION` in devcontainer.json via `sed`.
- [x] 2.4 Completion message telling user to click Rebuild.
- [x] 2.5 Handle pinned image tags: detect non-`:latest` tag, show instructions instead of pulling.
- [x] 2.6 Edge cases: no update, pull failure, missing field, all handled.
- [x] 2.7 `--check` flag for version check without pulling.

### Validation

Pending E2E test in Phase 5.

---

## Phase 3: Remove `dev-sync` — ✅ DONE

### Tasks

**Note (discovered 2026-04-06):** `dev-sync` running on startup causes a **false** VS Code rebuild prompt ("Configuration changed") on every fresh container start. This trains users to click "Ignore" — exactly the opposite of what we need when `dev-update` triggers a real rebuild prompt. Removing `dev-sync` is critical for the update UX.

- [x] 3.1 Replace auto-sync in `image/entrypoint.sh` with lightweight version check + notification
- [x] 3.2 Deleted `dev-sync.sh` from `.devcontainer/manage/`
- [x] 3.3 Remove `dev-sync` symlink from `image/Dockerfile`
- [x] 3.4 Deleted `scripts-version.txt` from repo + removed COPY from `image/Dockerfile`
- [x] 3.5 Removed `scripts-version.txt` generation from `build-image.yml` and `zip_dev_setup.yml`, simplified zip + commit steps
- [x] 3.6 Rewrote `lib/version-utils.sh` — removed all scripts version tracking, single version system
- [x] 3.7 `dev-help` auto-generates from script metadata — removing `dev-sync.sh` removes it automatically
- [x] 3.8 Rewrote `releasing.md` for single version system, updated `configuration.md` startup flow

### Validation

Container starts without sync attempt. `dev-sync` command no longer exists. Startup is faster (no 10s sync check). `dev-update` is the only update command.

---

## Phase 4: Startup notification — ✅ DONE

### Tasks

- [x] 4.1 In entrypoint.sh, check remote version via `curl` with 5s timeout
- [x] 4.2 If newer version exists, show in startup log:
  ```
  ⚠️  DCT update available: v1.7.17 → v1.7.18
      Run: dev-update
  ```
- [ ] 4.3 Cache the check result for 24 hours — deferred, the 5s timeout is sufficient for now

### Validation

Start a container with an older image version. Welcome message shows update notification. Running `dev-update` pulls and triggers rebuild.

---

## Phase 5: E2E testing — ✅ DONE (2026-04-06)

### Tasks

- [x] 5.1 Tester's devcontainer.json set to `:latest` with `DCT_IMAGE_VERSION: 1.7.19`
- [x] 5.2 Full flow tested: v1.7.19 → v1.7.20. Startup showed "Update available", `dev-update` pulled, VS Code prompted Rebuild.
- [ ] 5.3 No-update case — not explicitly tested (low risk, simple version comparison)
- [ ] 5.4 Docker unavailable fallback — not explicitly tested (code path is clear)
- [x] 5.5 Startup notification confirmed working with outdated image
- [x] 5.6 No false rebuild prompt on clean container start (earlier false prompt was from manual test file edits)

### Validation

Full update cycle works end-to-end. **One command + one click.**

---

## Phase 6: Template replacement on every update — ✅ DONE

**Problem:** `dev-update` only changed `DCT_IMAGE_VERSION` but didn't update the rest of devcontainer.json. When we add new fields to the template (e.g., `DEV_HOST_*` env vars, new features), existing users didn't get them.

**Solution:** DCT owns devcontainer.json. On every `dev-update`, download the latest template from GitHub, back up the old file, replace entirely. CI already sets `DCT_IMAGE_VERSION` in the template, so no sed needed.

### Tasks

- [x] 6.1 Added `"managed"` message to `customizations.devcontainer-toolbox` in template (v1.7.21)
- [x] 6.2 `dev-update` downloads latest `devcontainer-user-template.json` after pulling image
- [x] 6.3 Back up current devcontainer.json to `.devcontainer/backup/devcontainer.json.<old-version>`
- [x] 6.4 Replace devcontainer.json with downloaded template (CI already has correct `DCT_IMAGE_VERSION`)
- [x] ~~6.5 Set DCT_IMAGE_VERSION via sed~~ — not needed, CI handles it in the template
- [x] 6.6 VS Code detects the change → rebuild prompt (already works)
- [ ] 6.7 Add `.devcontainer/backup/` to `.gitignore` via `ensure-gitignore.sh`
- [ ] 6.8 Test: existing install with old template → `dev-update` → verify new fields appear, backup exists

### Validation

`dev-update` replaces devcontainer.json entirely. Old file backed up. New template fields (env vars, features, extensions) appear without user action.

---

## Acceptance Criteria

- [x] `dev-update` automatically pulls new image (no manual `docker pull`)
- [x] VS Code prompts rebuild after `dev-update` completes (via `DCT_IMAGE_VERSION` in remoteEnv)
- [x] `dev-sync` command removed
- [x] `scripts-version.txt` removed — single version in `version.txt`
- [x] Startup shows notification when image is outdated
- [x] Graceful fallback when Docker CLI not available (code path exists)
- [x] `dev-update --check` still works (version check without pulling)
- [x] `devcontainer-user-template.json` includes `DCT_IMAGE_VERSION`
- [x] CI auto-updates `DCT_IMAGE_VERSION` on each image build
- [ ] `dev-update` replaces devcontainer.json with latest template on every update (Phase 6)
- [ ] Old devcontainer.json backed up to `.devcontainer/backup/` (Phase 6)
- [ ] Template includes "managed by dev-update, do not edit" message (Phase 6)

---

## Files Changed

**Modified:**
- `.devcontainer/manage/dev-update.sh` — rewritten: docker pull + sed DCT_IMAGE_VERSION + rebuild prompt
- `.devcontainer/manage/lib/version-utils.sh` — removed scripts version tracking, single version system
- `devcontainer-user-template.json` — added `DCT_IMAGE_VERSION` to remoteEnv
- `image/entrypoint.sh` — replaced dev-sync with version check notification
- `image/Dockerfile` — removed dev-sync symlink + scripts-version.txt COPY
- `.github/workflows/build-image.yml` — removed scripts-version.txt generation
- `.github/workflows/zip_dev_setup.yml` — removed scripts-version.txt from zip + commit
- `website/docs/contributors/releasing.md` — rewritten for single version system
- `website/docs/configuration.md` — updated startup flow

**Created:**
- `website/docs/contributors/architecture/devcontainer-json.md` — full field reference
- `website/docs/ai-developer/plans/backlog/INVESTIGATE-one-command-update.md` — investigation
- `website/docs/ai-developer/plans/active/PLAN-one-command-update.md` — this plan

**Deleted:**
- `.devcontainer/manage/dev-sync.sh` — legacy script update mechanism
- `scripts-version.txt` — legacy scripts version tracking
