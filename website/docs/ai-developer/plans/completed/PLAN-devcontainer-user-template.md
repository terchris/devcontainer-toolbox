# Plan: Publish devcontainer-user-template.json as single source of truth

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Create `devcontainer-user-template.json` at the repo root as the single source of truth for image-mode devcontainer configuration, and update all consumers to download from it.

**Last Updated**: 2026-02-17

**Investigation**: [INVESTIGATE-image-mode-devcontainer-json.md](INVESTIGATE-image-mode-devcontainer-json.md)

**Priority**: High — external deployment scripts (jamf) are downloading the wrong file

---

## Problem

The image-mode `devcontainer.json` (for user projects) has no stable URL. It's embedded as duplicated copies inside `install.sh` and `install.ps1`. External tools (jamf `devcontainer-init`) mistakenly download the build-mode `.devcontainer/devcontainer.json` which fails because it references `Dockerfile.base`.

See the investigation for full analysis.

---

## Phase 1: Create the template file — ✅ DONE

### Tasks

- [x] 1.1 Create `devcontainer-user-template.json` at the repo root ✓
- [x] 1.2 Verify the file is valid JSONC ✓

### Validation

File exists at `https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/devcontainer-user-template.json` after push.

---

## Phase 2: Update install.sh — ✅ DONE

### Tasks

- [x] 2.1 Remove embedded JSON heredoc ✓
- [x] 2.2 Add `TEMPLATE_URL` variable pointing to `devcontainer-user-template.json` ✓
- [x] 2.3 Download the template using `curl` (with `wget` fallback) ✓
- [x] 2.4 Add file size validation (not empty) ✓
- [x] 2.5 Add `.vscode/extensions.json` creation ✓
- [x] 2.6 Handle existing `.vscode/extensions.json` (merge via python3, or warn) ✓

### Validation

Run `install.sh` on Mac/Linux and verify:
- `.devcontainer/devcontainer.json` contains `"image":` (not `"build":`)
- `.vscode/extensions.json` contains `ms-vscode-remote.remote-containers`
- Docker image is pulled

---

## Phase 3: Update install.ps1 — ✅ DONE

### Tasks

- [x] 3.1 Remove embedded JSON here-string ✓
- [x] 3.2 Add `$templateUrl` variable pointing to `devcontainer-user-template.json` ✓
- [x] 3.3 Download the template using `Invoke-WebRequest` ✓
- [x] 3.4 Add TLS 1.2 enforcement and file size validation ✓
- [x] 3.5 Add `.vscode/extensions.json` creation ✓
- [x] 3.6 Handle existing `.vscode/extensions.json` (merge via ConvertFrom-Json) ✓

### Validation

Review that `install.ps1` follows the same pattern as jamf `devcontainer-init.ps1` for download and validation.

---

## Phase 4: Clean up legacy `_toolboxVersion` — ✅ DONE

### Tasks

- [x] 4.1 Remove `"_toolboxVersion": "TOOLBOX_VERSION_PLACEHOLDER"` from `.devcontainer/devcontainer.json` ✓
- [x] 4.2 Remove the `sed` replacement in `.github/workflows/zip_dev_setup.yml` (line 50) ✓
- [x] 4.3 Update `website/docs/contributors/releasing.md` — remove `_toolboxVersion` reference ✓ from files table

### Validation

CI passes without the version placeholder logic.

---

## Phase 5: Document the two deployment modes — ✅ DONE

### Tasks

- [x] 5.1 Add "Two Deployment Modes" section to `website/docs/contributors/architecture/index.md` ✓
- [x] 5.2 Add warning comment to `.devcontainer/devcontainer.json` ✓
- [x] 5.3 Verify `README.md` install instructions point to `install.sh`/`install.ps1` ✓ (already correct)
- [x] 5.4 Add note in `website/docs/contributors/index.md` Quick Start section ✓

### Validation

User confirms documentation is clear and complete.

---

## Acceptance Criteria

- [ ] `devcontainer-user-template.json` exists at repo root — the single source of truth
- [ ] `install.sh` downloads from `devcontainer-user-template.json` (no embedded JSON)
- [ ] `install.ps1` downloads from `devcontainer-user-template.json` (no embedded JSON)
- [ ] Both install scripts create `.vscode/extensions.json` with Dev Containers extension
- [ ] No `initializeCommand` in the user template (cross-platform safe)
- [ ] Legacy `_toolboxVersion` / `TOOLBOX_VERSION_PLACEHOLDER` removed
- [ ] Contributor docs explain the two deployment modes
- [ ] `.devcontainer/devcontainer.json` has warning comment
- [ ] CI passes

---

## Files to Create

- `devcontainer-user-template.json` — image-mode template (repo root)

## Files to Modify

- `install.sh` — remove embedded JSON, download template, add `.vscode/extensions.json`
- `install.ps1` — remove embedded JSON, download template, add `.vscode/extensions.json`
- `.devcontainer/devcontainer.json` — add warning comment, remove `_toolboxVersion`
- `.github/workflows/zip_dev_setup.yml` — remove `_toolboxVersion` sed replacement
- `website/docs/contributors/releasing.md` — remove `_toolboxVersion` reference
- `website/docs/contributors/architecture/index.md` — add "Two Deployment Modes" section
- `website/docs/contributors/index.md` — add note about build-mode vs image-mode

## External changes needed (jamf project)

After this plan is merged, the jamf project needs to update the download URL in:
- `scripts-mac/devcontainer-toolbox/devcontainer-init.sh` line 38
- `scripts-win/devcontainer-toolbox/devcontainer-init.ps1` line 43

See jamf project: `INVESTIGATE-devcontainer-json-download-url.md`
