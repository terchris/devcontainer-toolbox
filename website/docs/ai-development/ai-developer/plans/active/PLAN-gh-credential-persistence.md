# Plan: Persist GitHub CLI credentials across devcontainer rebuilds

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Persist `gh` CLI credentials across devcontainer rebuilds by symlinking `~/.config/gh` to `.devcontainer.secrets/.gh-config/`.

**Last Updated**: 2026-02-17

**GitHub Issue**: #59

**Investigation**: [INVESTIGATE-gh-credential-persistence.md](INVESTIGATE-gh-credential-persistence.md)

**Priority**: Medium — affects every developer who uses `gh` CLI

---

## Problem

GitHub CLI stores auth tokens in `~/.config/gh/`. When the container is rebuilt, credentials are lost and the user must re-run `gh auth login`. The toolbox already solves this for Claude Code credentials using a symlink pattern — the same approach should be applied to `gh`.

---

## Phase 1: Create the credential sync library — ✅ DONE

### Tasks

- [x] 1.1 Create `.devcontainer/additions/lib/gh-credential-sync.sh` following the `claude-credential-sync.sh` pattern: ✓
  - Symlink `~/.config/gh` → `/workspace/.devcontainer.secrets/.gh-config/`
  - `mkdir -p ~/.config` before creating the symlink (gh uses a nested path)
  - Smart migration: if `~/.config/gh` is a directory, copy contents then convert to symlink
  - Handle all edge cases: symlink exists but points wrong, file exists, doesn't exist
  - Auto-execute `ensure_gh_credentials` when sourced
  - Idempotent — safe to run multiple times

### Validation

```bash
# Source the script manually and verify:
source .devcontainer/additions/lib/gh-credential-sync.sh
ls -la ~/.config/gh  # Should show symlink → /workspace/.devcontainer.secrets/.gh-config/
```

---

## Phase 2: Wire into the entrypoint — ✅ DONE

### Tasks

- [x] 2.1 Add to `image/entrypoint.sh` after the Claude credential sync (after line 55): ✓
  ```bash
  # Ensure GitHub CLI credentials symlink for persistence across rebuilds (issue #59)
  if [ -f "$ADDITIONS_DIR/lib/gh-credential-sync.sh" ]; then
      source "$ADDITIONS_DIR/lib/gh-credential-sync.sh"
  fi
  ```

### Validation

Review that the entrypoint sources the script in the correct location (after `claude-credential-sync.sh`, before git identity restoration).

---

## Acceptance Criteria

- [ ] `gh-credential-sync.sh` exists in `.devcontainer/additions/lib/`
- [ ] Entrypoint sources it on every container start
- [ ] `~/.config/gh` is a symlink to `/workspace/.devcontainer.secrets/.gh-config/`
- [ ] Existing `~/.config/gh` directory contents are migrated on first run
- [ ] After `gh auth login`, credentials survive a container rebuild
- [ ] Script passes shellcheck
- [ ] Script is idempotent

---

## Files to Create

- `.devcontainer/additions/lib/gh-credential-sync.sh` — credential sync library

## Files to Modify

- `image/entrypoint.sh` — add source call after Claude credential sync
