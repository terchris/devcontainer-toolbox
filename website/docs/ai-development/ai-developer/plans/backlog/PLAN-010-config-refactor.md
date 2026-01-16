# Feature: Config Files Refactor

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal:** Separate user/contributor local configuration from project defaults so contributors can install tools locally without accidentally committing personal config.

**Last Updated:** 2026-01-16

---

**Prerequisites:** None
**Blocks:** PLAN-003 (contributors need this to install dev-imagetools locally)
**Priority:** High

---

## Problem

Currently `.devcontainer.extend/*.conf` files are:
1. Committed to git (project defaults)
2. Updated when contributors install tools locally
3. Risk of accidentally committing personal tool installations

**Example scenario:**
1. Contributor installs `dev-imagetools` to test logo processing locally
2. `tools.conf` is updated with `dev-imagetools`
3. Contributor commits and pushes
4. Now ALL users get `dev-imagetools` installed by default (unintended)

---

## Solution

Separate local config from project defaults:

```
.devcontainer.extend/
├── tools.conf.defaults      # Project defaults (committed)
├── tools.conf               # User's local config (gitignored)
├── ports.conf.defaults      # Project defaults (committed)
├── ports.conf               # User's local config (gitignored)
└── ...
```

**Behavior:**
- `.conf.defaults` files are committed (project-wide settings)
- `.conf` files are gitignored (user's local overrides)
- On first run, scripts copy `.defaults` to `.conf` if `.conf` doesn't exist
- Scripts read from `.conf` (which includes defaults + local changes)

---

## Phase 1: Update Scripts to Support Two-Tier Config

### Tasks

- [ ] 1.1 Identify all scripts that read/write `.conf` files:
  - `dev-setup.sh`
  - `install-*.sh` scripts
  - Any other manage scripts

- [ ] 1.2 Create helper function in library for config handling:
  ```bash
  # Ensures .conf exists, copying from .defaults if needed
  ensure_config() {
    local conf_file="$1"
    local defaults_file="${conf_file}.defaults"
    if [ ! -f "$conf_file" ] && [ -f "$defaults_file" ]; then
      cp "$defaults_file" "$conf_file"
    fi
  }
  ```

- [ ] 1.3 Update all scripts to use the helper function before reading config

### Validation

Scripts work correctly with both new and existing setups.

---

## Phase 2: Rename Existing Config Files

### Tasks

- [ ] 2.1 Rename committed `.conf` files to `.conf.defaults`:
  - `tools.conf` → `tools.conf.defaults`
  - `ports.conf` → `ports.conf.defaults`
  - `secrets.conf` → `secrets.conf.defaults`
  - Any other `.conf` files

- [ ] 2.2 Add `.conf` files to `.gitignore`:
  ```
  # User's local config (not committed)
  .devcontainer.extend/*.conf
  !.devcontainer.extend/*.conf.defaults
  ```

- [ ] 2.3 Remove `.conf` files from git tracking:
  ```bash
  git rm --cached .devcontainer.extend/*.conf
  ```

### Validation

- `.conf.defaults` files are committed
- `.conf` files are gitignored
- Existing functionality still works

---

## Phase 3: Update Documentation

### Tasks

- [ ] 3.1 Update contributor documentation explaining:
  - `.conf.defaults` = project defaults (commit changes here)
  - `.conf` = local overrides (never committed)

- [ ] 3.2 Update `CREATING-SCRIPTS.md` with new config pattern

- [ ] 3.3 Add note to README about config file structure

### Validation

Documentation is clear and complete.

---

## Phase 4: Test and Deploy

### Tasks

- [ ] 4.1 Test fresh clone - verify `.conf` files are created from `.defaults`
- [ ] 4.2 Test existing setup - verify migration works smoothly
- [ ] 4.3 Test tool installation - verify `.conf` updates are local only
- [ ] 4.4 Commit and push
- [ ] 4.5 Verify in Chrome on deployed site

### Validation

- Fresh clones work correctly
- Existing users aren't broken
- Contributors can install tools without committing config

---

## Acceptance Criteria

- [ ] `.conf.defaults` files contain project defaults (committed)
- [ ] `.conf` files are gitignored (local only)
- [ ] Scripts auto-create `.conf` from `.defaults` on first run
- [ ] Contributors can install tools locally without config pollution
- [ ] Existing users experience smooth migration
- [ ] Documentation updated

---

## Files to Modify

**Config files:**
- `.devcontainer.extend/*.conf` → rename to `.conf.defaults`

**Git:**
- `.gitignore` (add `.conf` exclusion)

**Scripts:**
- `.devcontainer/manage/dev-setup.sh`
- `.devcontainer/additions/install-*.sh` (all install scripts)
- `.devcontainer/additions/lib-commonfunctions.sh` (add helper)

**Documentation:**
- `website/docs/contributors/` (update relevant docs)
- `website/docs/ai-developer/CREATING-SCRIPTS.md`

---

## Migration Notes

**For existing users:**
- Their current `.conf` files will be untracked after `git pull`
- Files remain on disk, continue working
- No action needed from users

**For new users:**
- Clone repo (no `.conf` files)
- Run `dev-setup` → `.conf` created from `.defaults`
- Works seamlessly

**For contributors:**
- Install tools locally → updates `.conf` (not committed)
- To add project defaults → edit `.conf.defaults` and commit
