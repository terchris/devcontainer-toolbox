# Investigate: Persist GitHub CLI credentials across devcontainer rebuilds

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Determine how to persist `gh` CLI credentials across devcontainer rebuilds using the existing symlink pattern.

**Last Updated**: 2026-02-17

**GitHub Issue**: #59

---

## Questions to Answer

1. What is the existing pattern for credential persistence?
2. Where does `gh` store its credentials?
3. Where should the persistent storage go?
4. How should it be wired into the startup sequence?
5. Does `gh` need an install script or just the sync library?

---

## Current State

### The problem

GitHub CLI (`gh`) stores authentication tokens in `~/.config/gh/` (primarily `hosts.yml`). When the container is rebuilt, this directory is lost. The user must re-run `gh auth login` every time.

### gh is already pre-installed

The `gh` CLI is installed in the base image (`image/Dockerfile` lines 66-71). No install script is needed.

### Existing credential persistence pattern

The toolbox already persists credentials for Claude Code using a symlink approach in `.devcontainer/additions/lib/claude-credential-sync.sh`:

| Aspect | How it works |
|--------|-------------|
| **Persistent location** | `/workspace/.devcontainer.secrets/.claude-credentials/` |
| **Home location** | `~/.claude` |
| **Mechanism** | Symlink: `~/.claude` → `.devcontainer.secrets/.claude-credentials/` |
| **Migration** | If `~/.claude` is a directory, copies contents then converts to symlink |
| **Idempotent** | Safe to run multiple times — verifies symlink, fixes if wrong |
| **Auto-executes** | Runs when sourced (no explicit function call needed) |

### Where claude-credential-sync.sh is wired in

Two integration points:

1. **Entrypoint** (`image/entrypoint.sh` lines 52-55) — runs on every container start:
   ```bash
   if [ -f "$ADDITIONS_DIR/lib/claude-credential-sync.sh" ]; then
       source "$ADDITIONS_DIR/lib/claude-credential-sync.sh"
   fi
   ```

2. **Install script** (`install-dev-ai-claudecode.sh` lines 45-47) — runs at install time:
   ```bash
   source "${SCRIPT_DIR}/lib/claude-credential-sync.sh"
   ```

### Entrypoint startup sequence (every start)

1. Git safe directory + config (`entrypoint.sh` lines 37-40)
2. `ensure-gitignore.sh` — ensures `.devcontainer.secrets/` is gitignored (line 44)
3. `ensure-vscode-extensions.sh` — VS Code extension recommendation (line 49)
4. **`claude-credential-sync.sh`** — Claude credentials symlink (line 54)
5. **← gh-credential-sync.sh would go here**
6. Git identity restoration from host files (lines 57-72)
7. Config scripts `--verify` (lines 75-86)
8. Service startup (lines 89-132)

### Other credentials in .devcontainer.secrets

| Directory | What | Symlinked from |
|-----------|------|---------------|
| `.claude-credentials/` | Claude Code OAuth tokens | `~/.claude` |
| `env-vars/` | Git identity, host info, Claude env | Various |
| `.kube/` | Kubernetes kubeconfig | `~/.kube` |
| `nginx-config/` | Nginx backend config | N/A |

### Entrypoint gh auth detection

The entrypoint already checks if `gh` is authenticated (`entrypoint.sh` lines 273-290) and suggests `gh auth login` if not. This check would still work with symlinked credentials — after the first login, credentials would persist and the check would pass on subsequent starts.

---

## Answers

### 1. What is the existing pattern?

Symlink from home directory to `.devcontainer.secrets/` subdirectory, implemented as a library script in `.devcontainer/additions/lib/` that auto-executes when sourced. The `claude-credential-sync.sh` is the reference implementation.

### 2. Where does gh store its credentials?

`~/.config/gh/` — contains:
- `hosts.yml` — host configurations and auth tokens
- `config.yml` — user settings

### 3. Where should persistent storage go?

**Decision: `/workspace/.devcontainer.secrets/.gh-config/`**

Follows the naming convention of other credential directories (`.claude-credentials/`, `.kube/`).

### 4. How should it be wired into startup?

**Decision: Same as Claude — entrypoint source + no separate install script.**

Since `gh` is pre-installed in the base image (not via an install script), there's no install script to add the sync call to. The entrypoint integration alone is sufficient:

```bash
# Ensure GitHub CLI credentials symlink for persistence across rebuilds (issue #59)
if [ -f "$ADDITIONS_DIR/lib/gh-credential-sync.sh" ]; then
    source "$ADDITIONS_DIR/lib/gh-credential-sync.sh"
fi
```

This goes after the Claude credential sync (line 55) in `image/entrypoint.sh`.

### 5. Does gh need an install script?

**Decision: No.** The `gh` CLI is pre-installed in the Dockerfile. The credential sync is a library script only — no `install-*.sh` or `config-*.sh` needed.

---

## Recommended Approach

Create `gh-credential-sync.sh` as a direct adaptation of `claude-credential-sync.sh`:

1. **Create** `.devcontainer/additions/lib/gh-credential-sync.sh`
   - Symlink `~/.config/gh` → `/workspace/.devcontainer.secrets/.gh-config/`
   - Smart migration: if `~/.config/gh` is a directory, copy contents then convert to symlink
   - Auto-execute on source
   - Idempotent

2. **Wire into entrypoint** (`image/entrypoint.sh`)
   - Add after claude-credential-sync.sh (after line 55)

3. **Update Dockerfile** (`image/Dockerfile`)
   - The Dockerfile copies `.devcontainer/additions/` into the image, so the new lib file will be included automatically — no Dockerfile change needed.

### Key difference from Claude pattern

The symlink target is different:
- Claude: `~/.claude` (a top-level home directory)
- gh: `~/.config/gh` (nested under `~/.config/`)

This means the sync script needs to `mkdir -p ~/.config` before creating the symlink, and must handle the case where `~/.config/gh` already exists as a directory within `~/.config/`.

---

## Next Steps

- [ ] Create PLAN-gh-credential-persistence.md with the implementation details
