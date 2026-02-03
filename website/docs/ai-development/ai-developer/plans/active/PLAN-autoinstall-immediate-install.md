# Feature: Auto-Install Tools — Install Immediately on Toggle

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: When users toggle tools on/off in the "Manage Auto-Install Tools" checklist, install newly enabled tools immediately instead of waiting for container rebuild.

**Last Updated**: 2026-02-03

---

## Overview

The `dev-setup` menu option "Manage Auto-Install Tools" (option 7) lets users select which tools should auto-install on container rebuild. Currently it only updates `.devcontainer.extend/enabled-tools.conf` — it does **not** install or uninstall anything. Users have to rebuild the container to get the tools they just enabled.

Users expect that enabling a tool in the checklist installs it right away.

### Current behavior

1. User opens `dev-setup` → option 7
2. Checklist shows all tools with current enabled/disabled state
3. User toggles tools and saves
4. `enabled-tools.conf` is updated
5. **Nothing else happens** — tools install only on next container rebuild

### Desired behavior

1–4 same as above, then:
5. Newly enabled tools are **installed immediately** (same as "Browse & Install")
6. Newly disabled tools are **uninstalled immediately** via `--uninstall` flag (all install scripts support it via the common framework)
7. User sees a summary of what was installed/uninstalled/skipped/failed

### How the dialog works

The checklist is a standard `dialog --checklist` widget. An `[*]` next to a tool means it is currently listed in `enabled-tools.conf`. The user interaction is:

1. **SPACE** — toggles a single item on/off. This only changes the visual state in the dialog; nothing is saved or installed yet.
2. **ENTER (OK)** — confirms all selections. The code compares the previous state against the new state, updates `enabled-tools.conf`, installs newly checked tools, and uninstalls newly unchecked tools.
3. **ESC / Cancel** — discards all changes. Nothing is saved or installed.

All install/uninstall actions happen **after the user presses OK**, not on individual toggles. This lets the user review the full set of changes before committing.

---

## Phase 1: Modify `manage_autoinstall_tools()` — IN PROGRESS

### Tasks

- [x] 1.1 Before showing the checklist dialog, record which tools are currently enabled (snapshot the old state)
- [x] 1.2 After the user saves, compare old vs new state to determine:
  - Newly enabled tools (were off, now on)
  - Newly disabled tools (were on, now off)
  - Unchanged tools
- [x] 1.3 Update `enabled-tools.conf` (same logic as today — disable all, enable selected)
- [x] 1.4 For each newly enabled tool:
  - Check if already installed via `SCRIPT_CHECK_COMMAND` → skip if so
  - Check prerequisites via `check_prerequisite_configs` → skip with message if not met
  - Run `bash "$script_path"` (same as `execute_tool_installation`)
  - Log success/failure
- [x] 1.5 Show summary: installed count, skipped count, failed count, disabled tools list
- [x] 1.6 Update the checklist dialog description to say "Checked tools will be installed now and on every rebuild"
- [x] 1.7 For each newly disabled tool:
  - Run `bash "$script_path" --uninstall` (all scripts support this via the common install framework)
  - Log success/failure
- [x] 1.8 Update summary to include uninstall counts

### Validation

- User opens `dev-setup` → option 7
- Enables a tool that isn't installed → tool installs immediately
- Enables a tool that is already installed → shows "already installed", skips
- Disables a tool → uninstalled immediately and removed from `enabled-tools.conf`
- No changes → shows "no changes" message
- User confirms phase is complete

### Files to modify

- `.devcontainer/manage/dev-setup.sh` — function `manage_autoinstall_tools()` (around line 1204)

---

## Acceptance Criteria

- [ ] Enabling a tool in the checklist installs it immediately
- [ ] Already-installed tools are skipped (not re-installed)
- [ ] Prerequisites are checked before installing
- [ ] Disabling a tool uninstalls it immediately via `--uninstall`
- [ ] Summary is shown after save
- [ ] Existing "Browse & Install" flow is unchanged
- [ ] Entrypoint startup still reads `enabled-tools.conf` normally

---

## Implementation Notes

- The install logic should match what `execute_tool_installation()` does (lines 2264-2330 in dev-setup.sh), but without the interactive dialog wrapper — just direct console output since we may be installing multiple tools in sequence.
- `install_single_tool()` from `tool-installation.sh` could also be used, but it requires sourcing multiple libraries that may not be loaded in the dev-setup context. Simpler to inline the check-and-run pattern.
- All 24 install scripts support `--uninstall` via the common install framework (`lib/install-common.sh`). Uninstall is run for all newly disabled tools.
