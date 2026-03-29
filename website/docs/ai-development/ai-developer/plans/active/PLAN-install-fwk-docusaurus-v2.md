# Feature: Convert Docusaurus to Install Script with CI/CD

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Convert `cmd-fwk-docusaurus.sh` to `install-fwk-docusaurus.sh` and add GitHub Pages CI/CD workflow generation.

**Last Updated**: 2026-03-30

---

## Overview

The current `cmd-fwk-docusaurus.sh` scaffolds a Docusaurus site but doesn't set up the CI/CD pipeline for GitHub Pages deployment. An install script is the right pattern because:

- Install/uninstall semantics — can cleanly remove everything it creates
- Shows in "Browse & Install Tools" under FRAMEWORKS (alongside Hugo)
- Uses the standard install template with `EXTENSIONS` array, `auto_enable_tool`, etc.
- Can include CI/CD setup as part of the installation

**What the install script does (beyond current cmd script):**
1. Everything the current cmd script does (scaffold `website/`, npm install, VS Code extensions)
2. **NEW**: Generates `.github/workflows/deploy-docs.yml` for GitHub Pages deployment
3. **NEW**: `--uninstall` removes `website/` and the workflow file
4. **NEW**: `SCRIPT_CHECK_COMMAND` checks if `website/` directory exists
5. **NEW**: Auto-enables for container rebuild via `auto_enable_tool`

**Generated CI/CD workflow** (generic version of this repo's `deploy-docs.yml`):
- Triggers on push to `main` when `website/**` changes
- Sets up Node.js 20, runs `npm ci`, builds, deploys to GitHub Pages
- No project-specific steps (no dev-logos, dev-docs, dev-cubes)
- Includes proper permissions for GitHub Pages deployment
- Concurrency control to prevent parallel deployments

---

## Phase 1: Convert to Install Script — DONE

### Tasks

- [x] 1.1 Create `.devcontainer/additions/install-fwk-docusaurus.sh` based on the install template
- [x] 1.2 Move all file generation functions from `cmd-fwk-docusaurus.sh` to the new script
- [x] 1.3 Update metadata
- [x] 1.4 Set up `EXTENSIONS` array (MDX, Front Matter CMS)
- [x] 1.5 Define `SCRIPT_COMMANDS` array with standard install actions
- [x] 1.6 Implement `pre_installation_setup()`
- [x] 1.7 Implement `process_installations()` with site scaffold + CI/CD workflow
- [x] 1.8 Implement uninstall mode
- [x] 1.9 Implement `post_installation_message()` with GitHub Pages and custom domain instructions
- [x] 1.10 Delete `cmd-fwk-docusaurus.sh`

### Validation

User confirms script structure looks correct.

---

## Phase 2: Add CI/CD Workflow Generation — DONE (merged into Phase 1)

### Tasks

- [x] 2.1 Add `generate_deploy_workflow()` function
- [x] 2.2 Create `.github/workflows/` directory if it doesn't exist
- [x] 2.3 Ensure uninstall removes the workflow file

### Validation

User confirms generated workflow looks correct.

---

## Phase 3: Testing — IN PROGRESS

### Tasks

- [x] 3.1 Verify `--help` flag works
- [x] 3.2 Bash syntax check passes
- [ ] 3.3 Test install inside devcontainer — verify all files created including workflow
- [ ] 3.4 Test uninstall — verify all files removed
- [ ] 3.5 Test idempotency — second install is a no-op

### Validation

User confirms tests pass.

---

## Acceptance Criteria

- [ ] `install-fwk-docusaurus.sh` scaffolds a working Docusaurus site in `website/`
- [ ] `.github/workflows/deploy-docs.yml` is generated and would deploy to GitHub Pages
- [ ] `--uninstall` removes `website/` and the workflow file
- [ ] `--help` flag works
- [ ] Script is idempotent (safe to run twice)
- [ ] VS Code extensions installed automatically via `EXTENSIONS` array
- [ ] `auto_enable_tool` / `auto_disable_tool` work correctly
- [ ] Shows in dev-setup under FRAMEWORKS category
- [ ] `cmd-fwk-docusaurus.sh` is deleted
- [ ] All core and extended metadata fields are set
- [ ] No shellcheck warnings

---

## Files to Modify

- `.devcontainer/additions/install-fwk-docusaurus.sh` (new)
- `.devcontainer/additions/cmd-fwk-docusaurus.sh` (delete)
