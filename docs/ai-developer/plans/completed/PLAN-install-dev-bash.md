# Plan: Create install-dev-bash.sh

## Status: Complete

**Goal**: Add Bash development tools (shellcheck, shfmt, VS Code extensions) as an installable dev environment

**Last Updated**: 2026-01-15

**Priority**: Medium

---

## Problem Summary

- `dev-test lint` requires ShellCheck but it's not installed in base container
- No bash development tools available via `dev-setup`
- Contributors need to manually install shellcheck to run linting
- Other dev languages (python, golang, rust, etc.) have install scripts, but bash doesn't

---

## What to Install

| Tool | Purpose | Install Method |
|------|---------|----------------|
| `shellcheck` | Static analysis / linting | apt-get |
| `shfmt` | Code formatter | apt-get or binary |
| `bash-language-server` | Autocomplete, go-to-definition, hover docs | npm (Node.js already in base) |
| VS Code extension: `timonwong.shellcheck` | Inline shellcheck warnings | VS Code |
| VS Code extension: `foxundermoon.shell-format` | Format on save | VS Code |
| VS Code extension: `mads-hartmann.bash-ide-vscode` | Language server integration | VS Code |

---

## Phase 1: Create the Script — ✅ DONE

### Tasks

- [x] Create `.devcontainer/additions/install-dev-bash.sh`
- [x] Add required metadata (SCRIPT_ID, SCRIPT_NAME, etc.)
- [x] Use category: `LANGUAGE_DEV`
- [x] Implement `--help` flag
- [x] Implement `--uninstall` flag
- [x] Install shellcheck via apt-get
- [x] Install shfmt via apt-get (or download binary if not available)
- [x] Install bash-language-server via npm
- [x] Install VS Code extensions (shellcheck, shell-format, bash-ide)
- [x] Add auto-enable/auto-disable support
- [x] Set SCRIPT_CHECK_COMMAND to `shellcheck --version`

### Validation

Run in devcontainer:
```bash
.devcontainer/additions/install-dev-bash.sh
shellcheck --version
shfmt --version
bash-language-server --version
```

---

## Phase 2: Test — ✅ DONE

### Tasks

- [x] Run `dev-test lint` and verify shellcheck works
- [x] Run `dev-test` to ensure all tests pass
- [x] Test `--uninstall` removes the tools
- [ ] Test auto-enable persists across container rebuild (skipped - requires container rebuild)

### Validation

```bash
.devcontainer/additions/install-dev-bash.sh --uninstall
# Verify tools removed
.devcontainer/additions/install-dev-bash.sh
# Verify tools installed again
```

---

## Phase 3: Documentation — ✅ DONE

### Tasks

- [x] Run `dev-docs` to regenerate documentation
- [x] Verify bash appears in tools.md
- [x] Verify bash appears in tools-details.md
- [ ] Commit all changes (will do after Phase 4)

### Validation

Check that `docs/tools.md` lists "Bash" under Development Tools.

---

## Phase 4: Clean Up Investigation Files — ✅ DONE

### Tasks

- [x] Delete `INVESTIGATE-shellcheck-in-devcontainer.md` (resolved by this plan)
- [x] Update `dev-test.sh` message if shellcheck not installed to suggest `install-dev-bash.sh`

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `.devcontainer/additions/install-dev-bash.sh` | Create |
| `.devcontainer/manage/dev-test.sh` | Update message |
| `docs/tools.md` | Auto-generated |
| `docs/tools-details.md` | Auto-generated |
| `docs/commands.md` | Auto-generated |

---

## Reference: Similar Script

Use `install-dev-python.sh` as a template - it's one of the simpler install scripts.

```bash
cat .devcontainer/additions/install-dev-python.sh
```

---

## Notes

- ShellCheck is ~5MB, shfmt is ~3MB - acceptable for optional install
- apt-get packages: `shellcheck`, `shfmt` (Ubuntu 22.04+)
- If shfmt not in apt, download from: https://github.com/mvdan/sh/releases
- bash-language-server: `npm install -g bash-language-server` (Node.js 22 already in base container)
- For uninstall: `npm uninstall -g bash-language-server`
