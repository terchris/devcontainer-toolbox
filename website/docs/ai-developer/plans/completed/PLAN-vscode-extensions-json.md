# Feature: Entrypoint creates .vscode/extensions.json for Dev Containers extension

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Ensure every workspace has `.vscode/extensions.json` recommending the Dev Containers extension, so new users on fresh machines get prompted to install it.

**GitHub Issue**: #49

**Last Updated**: 2026-02-16

**Completed**: 2026-02-16

---

## Problem

When a user opens a devcontainer-toolbox project in VS Code on a fresh machine, VS Code does not detect the `.devcontainer` folder because the **Dev Containers** extension (`ms-vscode-remote.remote-containers`) is not installed. Without the extension, no "Reopen in Container" prompt appears.

The solution is to have `.vscode/extensions.json` in the workspace with the extension in `recommendations`. This file must be committed to the repo so it's available when cloned.

### Complications

1. **Many projects have `.vscode/` in `.gitignore`** — this blocks committing `extensions.json`
2. **JSON manipulation** — `jq` is not installed; use pure bash (`cat`, `grep`, `sed`) consistent with the rest of the project
3. **Must handle three cases**: file doesn't exist, file exists without the extension, file already has it
4. **Must be idempotent** — safe to run on every container start

---

## Investigation Summary

| Finding | Detail |
|---------|--------|
| `.vscode/extensions.json` exists in project? | No |
| `jq` in container image? | No — use pure bash (cat, grep, sed) like the rest of the project |
| Closest pattern | `lib/ensure-gitignore.sh` — sourced by entrypoint |
| Best location | EVERY START section in `image/entrypoint.sh` (after `ensure-gitignore.sh`) |
| Gitignore challenge | End-user projects may have `.vscode/` in `.gitignore`, blocking the commit |

### Gitignore approach

If a project's `.gitignore` has `.vscode/`, the `extensions.json` file can't be committed. The entrypoint should update the gitignore to use:

```
.vscode/*
!.vscode/extensions.json
```

This ignores everything in `.vscode/` except `extensions.json`. The pattern:
- Replace `.vscode/` with `.vscode/*` + `!.vscode/extensions.json`
- If `.vscode/` is not in `.gitignore`, no change needed
- Must preserve existing gitignore content

### JSON manipulation approach

Use pure bash (`cat`, `grep`, `sed`) consistent with the rest of the project:
- **No file:** `cat` a heredoc to create it (same pattern as `ensure-gitignore.sh`)
- **File exists, missing extension:** `grep` to check, `sed` to insert into the `recommendations` array
- **Already present:** `grep` detects it, do nothing

---

## Phase 1: Create the library script — ✅ DONE

### Tasks

- [x] 1.1 Create `.devcontainer/additions/lib/ensure-vscode-extensions.sh` following the `ensure-gitignore.sh` pattern ✓
- [x] 1.2 Implement `_ensure_vscode_extensions()` function that:
  - Creates `.vscode/` directory if it doesn't exist
  - Creates `extensions.json` with `ms-vscode-remote.remote-containers` if file doesn't exist
  - Adds the extension to existing `recommendations` array if not already present
  - Uses pure bash (`cat` heredoc, `grep`, while-loop) consistent with the rest of the project ✓
- [x] 1.3 Make the function idempotent — safe to run multiple times with no side effects ✓

### Validation

Run the script manually and verify:
- Creates correct file when `.vscode/extensions.json` doesn't exist
- Adds extension to existing file without removing other recommendations
- Does nothing when extension is already present

User confirms phase is complete.

---

## Phase 2: Handle gitignore for end-user projects — ✅ DONE

### Tasks

- [x] 2.1 In the same library script, add `_ensure_vscode_gitignore()` function that:
  - If `.gitignore` contains `.vscode/` (blanket ignore), replace with `.vscode/*` and add `!.vscode/extensions.json`
  - If `.gitignore` doesn't mention `.vscode/`, do nothing
  - Preserve all other gitignore content ✓
- [x] 2.2 Call `_ensure_vscode_gitignore()` from the main function ✓

### Validation

Test with different gitignore scenarios:
- `.gitignore` has `.vscode/` → replaced correctly
- `.gitignore` has no `.vscode/` entry → unchanged
- `.gitignore` already has `.vscode/*` + negation → unchanged

User confirms phase is complete.

---

## Phase 3: Wire into entrypoint — ✅ DONE

### Tasks

- [x] 3.1 In `image/entrypoint.sh`, source the new library after `ensure-gitignore.sh` (around line 45) ✓
- [x] 3.2 Follow the same pattern: `source "$ADDITIONS_DIR/lib/ensure-vscode-extensions.sh"` with existence guard ✓

### Validation

Review the entrypoint change. Verify the source line follows the existing pattern.

User confirms phase is complete.

---

## Acceptance Criteria

- [x] `.vscode/extensions.json` is created with `ms-vscode-remote.remote-containers` recommendation
- [x] Existing recommendations in `extensions.json` are preserved
- [x] End-user `.gitignore` with `.vscode/` is updated to allow `extensions.json`
- [x] Script is idempotent (safe to run on every container start)
- [x] No new dependencies (pure bash only)
- [x] Pattern is consistent with `ensure-gitignore.sh`

---

## Files to Create/Modify

- `.devcontainer/additions/lib/ensure-vscode-extensions.sh` — new library script
- `image/entrypoint.sh` — source the new library

---

## Implementation Notes

### Bash approach for JSON manipulation

```bash
EXTENSION="ms-vscode-remote.remote-containers"
EXTENSIONS_FILE="$workspace/.vscode/extensions.json"

# Case 1: File doesn't exist — create with heredoc
if [ ! -f "$EXTENSIONS_FILE" ]; then
    mkdir -p "$workspace/.vscode"
    cat > "$EXTENSIONS_FILE" <<EOF
{
  "recommendations": [
    "$EXTENSION"
  ]
}
EOF
    return 0
fi

# Case 3: Already present — do nothing
if grep -q "$EXTENSION" "$EXTENSIONS_FILE" 2>/dev/null; then
    return 0
fi

# Case 2: File exists, missing extension — insert with sed
# Insert after the "recommendations": [ line
sed -i '/\"recommendations\".*\[/a\    "'"$EXTENSION"'",' "$EXTENSIONS_FILE"
```
