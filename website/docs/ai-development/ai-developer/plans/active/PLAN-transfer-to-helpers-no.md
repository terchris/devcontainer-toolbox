# Plan: Transfer devcontainer-toolbox to helpers-no

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Transfer this repo from `terchris/devcontainer-toolbox` to `helpers-no/devcontainer-toolbox` with zero downtime.

**Priority**: High — must be done first, other repos depend on the container image.

**Last Updated**: 2026-03-18

**Overall plan**: See `/Users/terje.christensen/learn/projects-2026/testing/github-helpers-no/INVESTIGATE-move-repos-to-helpers-no.md`

**Report back**: After completing each phase, update the overall plan's checklist in the file above. Mark the devcontainer-toolbox line as complete when all phases are done.

---

## Prerequisites

- None — this repo transfers first

**Blocks**: All other repo transfers depend on this completing (container image at `ghcr.io/helpers-no/`)

---

## Problem

The repo lives under `terchris/devcontainer-toolbox` but needs to be under the `helpers-no` org. There are 119 references to `terchris` across 44 files, including critical runtime references in install scripts and the container image path.

---

## Phase 1: Create branch and fix references — ✅ DONE

### Tasks

- [x] 1.1 Create branch `move-to-helpers-no`
- [x] 1.2 Replace `terchris/devcontainer-toolbox` → `helpers-no/devcontainer-toolbox` in critical scripts:
  - `install.sh`
  - `install.ps1`
  - `.devcontainer/manage/dev-sync.sh`
  - `.devcontainer/manage/dev-update.sh`
  - `.devcontainer/manage/dev-template.sh`
  - `.devcontainer/manage/lib/version-utils.sh`
  - `.devcontainer/additions/cmd-publish-github.sh` (kept `# Author: terchris` — person name)
  - `.devcontainer/additions/install-dev-ai-claudecode.sh`
- [x] 1.3 Replace `ghcr.io/terchris/devcontainer-toolbox` → `ghcr.io/helpers-no/devcontainer-toolbox` in:
  - `devcontainer-user-template.json`
  - GH Actions workflow files (no terchris refs found — already use variables)
- [x] 1.4 Replace `terchris` → `helpers-no` in docs/website files (~35 files)
  - `README.md`
  - `website/docusaurus.config.ts`
  - `website/blog/authors.yml` (kept author name `terchris`, updated repo URL)
  - Website docs and blog posts
  - Kept completed plans as-is (historical)
  - Kept `authors: [terchris]` in blog posts (person name)
- [x] 1.5 Update `.gitignore` (`terchris/` → `personal/`)
- [x] 1.6 Commit all changes to branch (do NOT merge)

### Validation

User confirms all references are updated. Run: `grep -r "terchris" --include="*.sh" --include="*.ps1" --include="*.json" --include="*.ts" .` should return zero critical hits.

---

## Phase 2: Transfer repo and publish container image

### Tasks

- [ ] 2.1 Transfer repo on GitHub: Settings → Transfer → `helpers-no`
- [ ] 2.2 Verify GitHub redirect works: `https://github.com/terchris/devcontainer-toolbox` → `https://github.com/helpers-no/devcontainer-toolbox`
- [ ] 2.3 Check GH Actions workflow has permissions to publish to `ghcr.io/helpers-no/devcontainer-toolbox`
- [ ] 2.4 Merge `move-to-helpers-no` branch
- [ ] 2.5 Trigger container image build — verify `ghcr.io/helpers-no/devcontainer-toolbox:latest` is published
- [ ] 2.6 Test: `docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest`

### Validation

Container image pulls successfully from `ghcr.io/helpers-no/devcontainer-toolbox:latest`.

---

## Phase 3: Re-enable GitHub Pages

### Tasks

- [ ] 3.1 Go to repo Settings → Pages → re-enable GitHub Pages deployment
- [ ] 3.2 Re-add custom domain: `uis.sovereignsky.no`
- [ ] 3.3 Verify site is live at https://uis.sovereignsky.no/

### Validation

User confirms website loads correctly.

---

## Phase 4: Update local clones

### Tasks

- [ ] 4.1 Update local git remote: `git remote set-url origin https://github.com/helpers-no/devcontainer-toolbox.git`
- [ ] 4.2 Notify users (<10) to update their remotes and rebuild devcontainers

### Validation

`git remote -v` shows `helpers-no/devcontainer-toolbox`.

---

## Acceptance Criteria

- [ ] Repo is at `https://github.com/helpers-no/devcontainer-toolbox`
- [ ] `ghcr.io/helpers-no/devcontainer-toolbox:latest` image is published and pullable
- [ ] `install.sh` and `install.ps1` work from the new location
- [ ] Website is live at `uis.sovereignsky.no`
- [ ] No remaining `terchris` references in critical scripts
- [ ] Old URL redirects work

---

## Files to Modify

**Critical scripts:**
- `install.sh`
- `install.ps1`
- `devcontainer-user-template.json`
- `.devcontainer/manage/dev-sync.sh`
- `.devcontainer/manage/dev-update.sh`
- `.devcontainer/manage/dev-template.sh`
- `.devcontainer/manage/lib/version-utils.sh`
- `.devcontainer/additions/cmd-publish-github.sh`
- `.devcontainer/additions/install-dev-ai-claudecode.sh`

**Config/docs:**
- `README.md`
- `.gitignore`
- `website/docusaurus.config.ts`
- `website/blog/authors.yml`
- ~30 website doc/blog files
