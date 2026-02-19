# Feature: Add uv as default Python package manager

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Add `uv` (extremely fast Python package and project manager) to the Python install script as requested by contributor.

**Last Updated**: 2026-02-19

**GitHub Issue**: #62

**Priority**: Low — enhancement, not a bug fix

---

## Problem

Issue #62 requests adding `uv` to the Python development tools install script. `uv` is an extremely fast Python package and project manager written in Rust by Astral (the team behind Ruff). It's available on PyPI and can be installed via `pip install uv`.

---

## Phase 1: Add uv to Python install script — ✅ DONE

### Tasks

- [x] 1.1 Add `"uv"` to `PACKAGES_PYTHON` array
- [x] 1.2 Update `SCRIPT_DESCRIPTION` to mention uv
- [x] 1.3 Update `SCRIPT_TAGS` to include uv
- [x] 1.4 Update `SCRIPT_ABSTRACT` to mention uv
- [x] 1.5 Update `SCRIPT_SUMMARY` to mention uv
- [x] 1.6 Update `post_installation_message()` to mention uv
- [x] 1.7 Bump `SCRIPT_VER` from `0.0.1` to `0.0.2`

### Validation

```bash
bash .devcontainer/additions/install-dev-python.sh --help
# Should list uv in the Python packages section
```

---

## Acceptance Criteria

- [x] `uv` is in the `PACKAGES_PYTHON` array
- [x] Script metadata (DESCRIPTION, TAGS, ABSTRACT, SUMMARY) updated to mention uv
- [x] Post-installation message mentions uv
- [x] `--help` output shows uv in the package list
- [x] SCRIPT_VER bumped

---

## Files to Modify

- `.devcontainer/additions/install-dev-python.sh` — add uv to packages and update metadata
