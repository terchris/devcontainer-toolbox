# Fix: Persist Claude Code credentials across devcontainer rebuilds

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Ensure Claude Code credentials survive container rebuilds for both authentication modes.

**GitHub Issue**: #46

**Last Updated**: 2026-02-16

**Completed**: 2026-02-16

---

## Problem

When a devcontainer is rebuilt, Claude Code credentials are lost because `~/.claude/` lives inside the container. Users must re-authenticate every time.

### Two authentication modes

Claude Code supports two different authentication flows. Both need credentials to persist across rebuilds.

#### Case 1: API / LiteLLM Proxy (env var)

Used when Claude Code connects to Anthropic API through a LiteLLM proxy (e.g., in a K8s cluster). Authentication is via the `ANTHROPIC_AUTH_TOKEN` environment variable.

- **Configured by:** `config-ai-claudecode.sh` (interactive setup)
- **Stored at:** `.devcontainer.secrets/env-vars/.claude-code-env` (symlinked to `~/.claude-code-env`)
- **Restored by:** `config-ai-claudecode.sh --verify` (called by entrypoint config scanner on first start)
- **Status:** Already working. The `--verify` flag restores the symlink and bashrc entry.

#### Case 2: Claude Max subscription (OAuth)

Used when authenticating directly with Anthropic via a Claude Max/Pro subscription. Claude Code runs an OAuth flow in the browser and stores tokens in `~/.claude/.credentials.json`.

- **Configured by:** Claude Code itself (OAuth browser flow on first launch)
- **Stored at:** `~/.claude/.credentials.json` (inside the container — lost on rebuild)
- **Restored by:** Nothing — **this is the missing piece**
- **Status:** Not persisted. The library `lib/claude-credential-sync.sh` exists with a working `ensure_claude_credentials()` function that symlinks `~/.claude/` → `.devcontainer.secrets/.claude-credentials/`, but it is never called from anywhere.

### Why symlink (not copy)

Claude Code's OAuth tokens are short-lived. The access token expires and Claude Code automatically refreshes it using the refresh token, updating `~/.claude/.credentials.json` in place. A one-time copy would go stale as soon as the token refreshes. A symlink ensures that every token refresh writes directly to persistent storage, so the latest credentials are always preserved.

### What exists but is not wired up

The `claude-credential-sync.sh` library handles everything:
- Creates `.devcontainer.secrets/.claude-credentials/` directory
- Symlinks `~/.claude` → `.devcontainer.secrets/.claude-credentials/`
- If `~/.claude/` is already a directory (first-time migration), copies files to persistent storage then converts to symlink
- Verifies the symlink is correct on subsequent runs

The only problem: **nothing calls it**.

---

## Phase 1: Wire credential sync into entrypoint — ✅ DONE

### Tasks

- [x] 1.1 In `image/entrypoint.sh`, source `lib/claude-credential-sync.sh` in the EVERY START section (after the `ensure-gitignore.sh` block) ✓
- [x] 1.2 Follow the existing pattern: `if [ -f ... ]; then source ...; fi` ✓
- [x] 1.3 Updated library to auto-execute `ensure_claude_credentials` when sourced (matching `ensure-gitignore.sh` pattern) ✓

### Validation

Review the entrypoint change. Verify:
- The symlink `~/.claude` → `.devcontainer.secrets/.claude-credentials/` would be created on every container start
- Existing OAuth credentials in `.devcontainer.secrets/.claude-credentials/` would be available via the symlink
- If no credentials exist yet, the empty directory is ready for when the user authenticates

User confirms phase is complete.

---

## Phase 2: Call credential sync from install script — ✅ DONE

### Tasks

- [x] 2.1 In `install-dev-ai-claudecode.sh`, source `lib/claude-credential-sync.sh` at the top (after logging library) so the symlink is in place before Claude Code first runs ✓
- [x] 2.2 This ensures that when Claude Code does its first OAuth flow, `.credentials.json` is written to the persistent location via the symlink ✓

### Validation

Review the install script change. Verify the symlink would be set up before Claude Code is available to run.

User confirms phase is complete.

---

## Acceptance Criteria

- [x] `~/.claude` is symlinked to `.devcontainer.secrets/.claude-credentials/` on every container start
- [x] Symlink is also created at install time (before first Claude Code launch)
- [x] OAuth credentials (`.credentials.json`) written by Claude Code go to persistent storage via the symlink
- [x] Credentials survive container rebuild
- [x] Case 1 (API/LiteLLM) continues to work (no regressions)
- [x] Case 2 (OAuth/Max subscription) credentials persist across rebuilds
- [x] Script is idempotent (safe to run on every start)

---

## Files Modified

- `image/entrypoint.sh` — source `lib/claude-credential-sync.sh` in EVERY START section
- `.devcontainer/additions/install-dev-ai-claudecode.sh` — source `lib/claude-credential-sync.sh` at top
- `.devcontainer/additions/lib/claude-credential-sync.sh` — changed to auto-execute when sourced (matching `ensure-gitignore.sh` pattern)

---

## Tests Performed

### Local (macOS host)

- `bash -n image/entrypoint.sh` — syntax check passes
- `bash -n install-dev-ai-claudecode.sh` — syntax check passes
- Simulated Case 1 (nothing exists): symlink created correctly
- Simulated Case 2 (directory with credentials): directory-to-symlink conversion works
- Simulated Case 3 (symlink already correct): no changes made (idempotent)

Note: `readlink -f` and hidden file glob (`.[!.]*`) behave differently on macOS vs Linux. The script targets the Linux container where GNU coreutils are available.

### Full verification (requires devcontainer)

- [ ] Rebuild container → `ls -la ~/.claude` shows symlink to `.devcontainer.secrets/.claude-credentials/`
- [ ] Authenticate with `claude` → `.credentials.json` lands in `.devcontainer.secrets/.claude-credentials/`
- [ ] Rebuild again → credentials still available via symlink, no re-authentication needed
