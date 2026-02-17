# Feature: dev-sync foundation — pre-commit hook + tools.json consolidation

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Add version tracking infrastructure and consolidate the two separate JSON generators into one.

**GitHub Issue**: #54 (Phase 1 of 5)

**Last Updated**: 2026-02-16

**Investigation**: [INVESTIGATE-dev-update-auto-pull.md](INVESTIGATE-dev-update-auto-pull.md) — Phase 1 (foundation)

---

## Overview

Issue #54 describes a multi-phase script-level sync system. This plan covers **Phase 1 only** — the version infrastructure that all future phases depend on.

**Requirement**: Development of devcontainer-toolbox is done inside the devcontainer itself (Linux). The pre-commit hook only needs to support GNU `sed` — no macOS portability concerns.

### Problem: Two separate JSON generators

Currently there are two scripts that independently extract metadata from install scripts:

| Script | Output | Used by |
|--------|--------|---------|
| `generate-tools-json.sh` | `.devcontainer/manage/tools.json` | Runtime (`dev-tools`, future `dev-sync`) |
| `dev-docs.sh` | `website/src/data/tools.json` | Website (React components) |

Both scan the same `install-*.sh` files but produce different JSON. The runtime version is actually more complete (includes packages, extensions, checkCommand, file) while the website version adds `logo` but misses those fields.

### Solution

Make `generate-tools-json.sh` the **single source of truth** for tool JSON data:

1. Enhance `generate-tools-json.sh` with `logo` field and `SCRIPT_VER` (version)
2. Refactor `dev-docs.sh` to call `generate-tools-json.sh` and copy its output to `website/src/data/tools.json`, instead of re-extracting metadata
3. `dev-docs.sh` keeps its MDX generation (needs to read scripts directly for package tables and `--help` output), but uses the shared JSON for `tools.json` and `categories.json`

### Four deliverables

1. **Pre-commit hook** (`.githooks/pre-commit`) — validates scripts and auto-bumps `SCRIPT_VER` patch version
2. **Script validation** — syntax check, required metadata fields, shellcheck on staged addition scripts
3. **Consolidated JSON generator** — one `generate-tools-json.sh` for both runtime and website
4. **Version fields in tools.json** — per-tool `"version"` from `SCRIPT_VER` + top-level `"version"`

---

## Phase 1: Pre-commit hook — ✅ DONE

### Tasks

- [x] 1.1 Create `.githooks/pre-commit` with the auto-bump logic from issue #54 (uses GNU `sed -i` — runs inside devcontainer)
- [x] 1.2 Make the hook executable (`chmod +x`)
- [x] 1.3 Add script validation (Job 1): syntax check (`bash -n`), required metadata fields, shellcheck (`--severity=error`)
- [x] 1.4 Validation checks 8 required fields: `SCRIPT_ID`, `SCRIPT_VER`, `SCRIPT_NAME`, `SCRIPT_DESCRIPTION`, `SCRIPT_CATEGORY`, `SCRIPT_CHECK_COMMAND`, `SCRIPT_TAGS`, `SCRIPT_ABSTRACT`
- [x] 1.5 Validation runs before version bump — blocks commit on failure
- [x] 1.6 Tested in devcontainer: valid scripts pass, scripts with missing fields are rejected

### Validation

```bash
chmod +x .githooks/pre-commit
git config core.hooksPath .githooks
# Stage a trivial change to a script with SCRIPT_VER, commit
# Verify SCRIPT_VER was auto-bumped in the committed file
```

User confirms phase is complete.

---

## Phase 2: Enhance generate-tools-json.sh — ✅ DONE

Add the missing fields so it can serve both runtime and website needs.

### Tasks

- [x] 2.1 Add `SCRIPT_VER` extraction — new `"version"` field per tool
- [x] 2.2 Add `SCRIPT_LOGO` extraction — new `"logo"` field per tool (currently only in website generator)
- [x] 2.3 Add top-level `"version"` field — start at `"1.0.0"`, CI/CD will auto-bump in future phases
- [x] 2.4 Extract `SCRIPT_VER` from config scripts and service scripts too
- [x] 2.5 Also generate `categories.json` in the same script (currently only in `dev-docs.sh`)
- [x] 2.6 Run the generator and verify the output has all fields needed by both runtime and website

### Validation

```bash
bash .devcontainer/manage/generate-tools-json.sh
# Verify tools.json has:
#   - top-level "version": "1.0.0"
#   - each tool has "version": "X.Y.Z"
#   - each tool has "logo" (when defined in script)
#   - packages, extensions, checkCommand still present
# Verify categories.json is generated
```

User confirms phase is complete.

---

## Phase 3: Refactor dev-docs.sh to use shared generator — ✅ DONE

Remove the duplicate `generate_tools_json()` and `generate_categories_json()` from `dev-docs.sh` and have it use the output from `generate-tools-json.sh` instead.

### Tasks

- [x] 3.1 In `dev-docs.sh`, replace `generate_tools_json()` call with: run `generate-tools-json.sh`, then copy its output to `website/src/data/tools.json`
- [x] 3.2 Similarly for `categories.json` — copy from the shared generator output
- [x] 3.3 Remove the duplicate `generate_tools_json()` and `generate_categories_json()` functions from `dev-docs.sh`
- [x] 3.4 Keep `dev-docs.sh`'s MDX generation unchanged (still reads scripts for package tables, help output)
- [x] 3.5 Run `dev-docs` and verify website JSON matches what the generator produces
- [x] 3.6 Verify the website builds correctly with the new JSON (if possible)

### Validation

```bash
dev-docs --verbose
# Verify website/src/data/tools.json and categories.json are generated
# Compare with .devcontainer/manage/tools.json — should have same tool data
# Verify MDX pages still generate correctly
```

User confirms phase is complete.

---

## Phase 4: Documentation — ✅ DONE

### Tasks

- [x] 4.1 Add a note to contributor docs about the pre-commit hook setup: `git config core.hooksPath .githooks`
- [x] 4.2 Document that `SCRIPT_VER` is auto-bumped — contributors don't need to manually update it
- [x] 4.3 Document that `generate-tools-json.sh` is the single source of truth for tool JSON
- [x] 4.4 Document the pre-commit script validation (what's checked, what fields are required)

### Validation

Documentation is clear and accurate.

User confirms phase is complete.

---

## Acceptance Criteria

- [x] `.githooks/pre-commit` exists and auto-bumps `SCRIPT_VER` on commit
- [x] Hook uses GNU `sed -i` (runs inside devcontainer, Linux only)
- [x] Hook only bumps when there are real content changes (not just version line)
- [x] Hook skips new files (not yet in HEAD)
- [x] Hook validates staged addition scripts (syntax, metadata, shellcheck)
- [x] Hook blocks commit if validation fails
- [x] `tools.json` has a top-level `"version"` field
- [x] Each tool entry in `tools.json` has a `"version"` field from `SCRIPT_VER`
- [x] Each tool entry in `tools.json` has a `"logo"` field (when defined)
- [x] `generate-tools-json.sh` is the single source of truth for tool JSON
- [x] `dev-docs.sh` no longer has its own JSON generation — uses the shared generator
- [x] `generate-tools-json.sh` also produces `categories.json`
- [x] Website JSON output matches runtime JSON (same data)
- [x] MDX page generation still works (reads scripts directly for package tables)
- [x] Contributor docs explain hook setup and version auto-bumping
- [x] Contributor docs explain script validation checks

---

## Files to Create/Modify

- `.githooks/pre-commit` — **new** — auto-bump hook
- `.devcontainer/manage/generate-tools-json.sh` — **modify** — add version, logo, categories
- `.devcontainer/manage/dev-docs.sh` — **modify** — remove duplicate JSON generation, use shared generator
- Contributor docs — **modify** — add hook setup instructions
