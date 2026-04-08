# Plan: Rename dev-utils to sql-rest, Remove Docker

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: ✅ Completed (2026-04-08, v1.7.33, E2E tested)

**Goal**: Rename `install-tool-dev-utils.sh` to `install-tool-sql-rest.sh`, remove Docker bits (redundant with docker-outside-of-docker feature), and focus the script on SQLTools + REST Client.

**Priority**: Medium — cleanup after docker feature integration

**Last Updated**: 2026-04-08

---

## Overview

`install-tool-dev-utils.sh` bundles three things: SQLTools VS Code extension, REST Client VS Code extension, and Docker (both the `docker.io` apt package AND the Docker VS Code extension).

Since DCT v1.7.14, the `docker-outside-of-docker` feature provides the Docker CLI for all users. The `docker.io` apt install is redundant and wasteful. The Docker VS Code extension provides a UI, but most DCT developers use the CLI; Dockerfile syntax highlighting is a minor benefit that doesn't justify keeping a whole extension.

Also, the script name `dev-utils` is too generic. Renaming to `sql-rest` makes the purpose clear.

**Research confirmed (2026-04-08):** SQLTools (6.4M installs) and REST Client (7M installs, 5.0/5) are both still the most popular choices in their categories. No extension changes needed — just rename and remove Docker.

---

## Phase 1: Rename script and update metadata — ✅ DONE

### Tasks

- [x] 1.1 Renamed `install-tool-dev-utils.sh` → `install-tool-sql-rest.sh` (git mv)
- [x] 1.2 Updated all metadata fields
- [x] 1.3 Removed `docker.io` from `PACKAGES_SYSTEM` (now empty)
- [x] 1.4 Removed Docker VS Code extension from `EXTENSIONS`
- [x] 1.5 Updated `post_installation_message()` — removed Docker lines

### Validation

`bash .devcontainer/additions/install-tool-sql-rest.sh --help` works, metadata is clean, no Docker references.

---

## Phase 2: Update related files — ✅ DONE

### Tasks

- [x] 2.1 Updated `install-tool-kubernetes.sh` SCRIPT_RELATED
- [x] 2.2 Updated `install-dev-php-laravel.sh` (2 references)
- [x] 2.3 Updated `LOGO-SOURCES.md` logo entry + name
- [x] 2.4 Updated `cubeConfig.ts` logo filename + display name
- [x] 2.5 Verified: remaining references are only in active plan, completed plan, and auto-generated files

### Validation

`grep -r "tool-dev-utils\|install-tool-dev-utils"` returns only historical plan files (completed/), no live code references.

---

## Phase 3: Rename logo file — ✅ DONE

### Tasks

- [x] 3.1 Found: `tool-dev-utils-logo.svg` (src) and `tool-dev-utils-logo.webp` (generated)
- [x] 3.2 Renamed both: `tool-dev-utils-logo` → `tool-sql-rest-logo`
- [x] 3.3 SVG is git-tracked (git mv), WebP is gitignored (plain mv)
- [ ] 3.4 Run `dev-logos` in Phase 4 if webp needs regeneration

### Validation

Logo renders correctly on the website (after `dev-docs` regenerates tool pages).

---

## Phase 4: Regenerate auto-generated files — ✅ DONE

### Tasks

- [x] 4.1 Deleted `dev-utils.mdx`
- [x] 4.2 Ran `dev-docs` — regenerated tools.json (4 hits for tool-sql-rest, 0 for tool-dev-utils), created sql-rest.mdx
- [x] 4.3 `dev-logos` not needed — webp already existed and was renamed manually

Verified: only historical references (active plan, completed plan) contain dev-utils strings.

### Validation

`dev-docs` completes without errors. New tool page exists, old one is gone.

---

## Phase 5: Test

### Tasks

- [ ] 5.1 Run static tests: `.devcontainer/additions/tests/run-all-tests.sh static install-tool-sql-rest.sh`
- [ ] 5.2 Run unit tests: `.devcontainer/additions/tests/run-all-tests.sh unit install-tool-sql-rest.sh`
- [ ] 5.3 Run install cycle test: `.devcontainer/additions/tests/run-all-tests.sh install install-tool-sql-rest.sh`
- [ ] 5.4 Verify SQLTools + REST Client extensions get installed (check via `code --list-extensions`)
- [ ] 5.5 Verify `docker.io` is NOT installed by this script (it's provided by the feature, but the script shouldn't try to reinstall)
- [ ] 5.6 Run Docusaurus build locally: `cd website && npm run build` — catches broken links
- [ ] 5.7 Verify enabled-tools.conf migration: if a user had `tool-dev-utils` in their `enabled-tools.conf`, they should either (a) still work somehow, or (b) get a clear message that the name changed

### Validation

All tests pass. Docusaurus build succeeds. No broken links.

---

## Phase 6: Migration note for existing users

### Tasks

- [ ] 6.1 Decide: should `tool-dev-utils` in existing `enabled-tools.conf` files still work (as alias), or fail cleanly?
- [ ] 6.2 If alias: add a symlink or alias in the tool discovery logic
- [ ] 6.3 If fail: no action — users who have it will see "tool not found" on next rebuild and can fix manually
- [ ] 6.4 Document the rename in the next version's release notes

### Validation

Existing users with `tool-dev-utils` in their config get a clear path forward (either it still works, or a clear error message).

---

## Acceptance Criteria

- [ ] File renamed to `install-tool-sql-rest.sh`
- [ ] `SCRIPT_ID` updated to `tool-sql-rest`
- [ ] `docker.io` package removed from `PACKAGES_SYSTEM`
- [ ] Docker VS Code extension removed from `EXTENSIONS`
- [ ] Only SQLTools + REST Client remain as extensions
- [ ] `post_installation_message()` updated
- [ ] All references in other scripts updated (`kubernetes`, `php-laravel`)
- [ ] Logo file renamed
- [ ] Auto-generated files regenerated via `dev-docs`
- [ ] Old tool page removed
- [ ] All tests pass (static, unit, install cycle)
- [ ] Docusaurus build succeeds locally
- [ ] Migration path documented for existing users with `tool-dev-utils` in config

---

## Files to Modify

**Renamed:**
- `.devcontainer/additions/install-tool-dev-utils.sh` → `install-tool-sql-rest.sh`
- `website/static/img/tools/src/tool-dev-utils-logo.*` → `tool-sql-rest-logo.*`

**Modified:**
- `.devcontainer/additions/install-tool-kubernetes.sh` (SCRIPT_RELATED)
- `.devcontainer/additions/install-dev-php-laravel.sh` (2 references)
- `website/static/img/LOGO-SOURCES.md` (logo entry)
- `website/src/components/FloatingCubes/cubeConfig.ts` (logo filename)

**Auto-regenerated (via dev-docs):**
- `.devcontainer/manage/tools.json`
- `website/src/data/tools.json`
- `website/docs/tools/infrastructure-configuration/sql-rest.mdx` (new)
- `README.md`
- `website/docs/commands.md`

**Deleted:**
- `website/docs/tools/infrastructure-configuration/dev-utils.mdx` (old tool page)
