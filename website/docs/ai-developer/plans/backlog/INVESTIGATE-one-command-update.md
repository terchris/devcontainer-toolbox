# Investigate: One-Command DCT Update

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Make updating DCT a single command that any developer can run, regardless of whether they understand devcontainers, Docker, or VS Code.

**Priority**: High — current update flow requires Docker knowledge that most developers don't have

**Last Updated**: 2026-04-06

---

## Problem

DCT has two update mechanisms. Neither is a simple one-command experience:

### Update Type 1: Script Updates (`dev-sync`)

Updates scripts (new tools, bug fixes, new commands) WITHOUT rebuilding the container.

**Current flow:**
- Auto-runs on container start (entrypoint.sh, 10s timeout)
- Downloads `dev_containers.zip` from GitHub releases
- Swaps `manage/` and `additions/` directories atomically
- Has rollback support

**User experience:** Invisible — happens on startup. Works well. No complaints.

### Update Type 2: Container Updates (`dev-update`)

Updates the base image (OS packages, Node.js, Python, system tools).

**Current flow:**
1. User runs `dev-update` inside the container
2. DCT shows: "current: 1.7.16, latest: 1.7.17"
3. DCT tells user to run:
   ```
   docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest
   ```
4. DCT tells user to: VS Code → Command Palette → "Dev Containers: Rebuild Container"

**User experience:** Bad. The developer must:
- Understand what `docker pull` does
- Know how to open VS Code Command Palette
- Know what "Rebuild Container" means
- Accept that their terminal session will be killed mid-rebuild

Most developers using DCT don't know what a devcontainer is. They were told "open this folder in VS Code and click Reopen in Container". Asking them to `docker pull` and rebuild is a support burden.

---

## What Changed: Docker is Now Available Inside DCT

Since v1.7.14, the `docker-outside-of-docker` feature gives every DCT container:
- Docker CLI at `/usr/bin/docker`
- Access to the host Docker daemon via the shared socket

This means **from inside the container, we can:**
- `docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest` — pull the new image
- `docker images` — verify the pull succeeded
- Potentially trigger a rebuild

---

## Vision: `dev-update` Does Everything

```
$ dev-update

🔍 Checking for updates...
   Current: 1.7.16
   Latest:  1.7.17

📦 Downloading new image...
   Pulling ghcr.io/helpers-no/devcontainer-toolbox:latest...
   Done (2.86 GB)

🔄 Rebuilding container...
   This will restart your terminal session.
   Your files in /workspace are safe (they're mounted from your host).

   Press Enter to continue, or Ctrl+C to cancel.

   Rebuilding...
```

The developer runs one command. They don't need to know about Docker, images, pulls, or VS Code Command Palette.

---

## Technical Challenges

### Challenge 1: Triggering a container rebuild from inside the container

The container can pull a new image — that's just `docker pull`. But **rebuilding the devcontainer** is a VS Code operation, not a Docker operation. VS Code:
1. Stops the current container
2. Creates a new container from the (now updated) image
3. Applies devcontainer.json settings (features, mounts, env vars)
4. Runs postCreateCommand / postStartCommand
5. Reconnects

**Options to trigger rebuild:**

**Option A: VS Code CLI command**
VS Code has a `code` CLI available inside devcontainers. Check if there's a command to trigger rebuild:
```bash
code --remote-command "workbench.action.remote.containers.rebuildContainer"
```
If this exists, `dev-update` can call it after `docker pull`.

**Option B: devcontainers CLI**
The `@devcontainers/cli` npm package can build/start devcontainers:
```bash
npx @devcontainers/cli up --workspace-folder /workspace
```
But this runs on the HOST, not inside the container. Could the container invoke this on the host via Docker?

**Option C: Kill the container, let VS Code auto-reconnect**
```bash
docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest
# Container's own process exits — VS Code detects disconnect
# VS Code shows "Container stopped" — user clicks "Reopen"
```
Not truly one-command — user still clicks a button. But simpler than the current 3-step flow.

**Option D: Replace container via Docker API**
From inside the container, use the Docker socket to:
1. Pull new image
2. Create a new container with the same config
3. Stop/remove the current container
4. Start the new one
VS Code would reconnect to the new container.

Risk: the devcontainer.json config (mounts, features, env vars) is managed by VS Code, not just Docker. A raw `docker run` wouldn't apply the features layer.

**Option E: Edit `.devcontainer/devcontainer.json` to trigger VS Code rebuild prompt**
VS Code watches `.devcontainer/devcontainer.json` for changes. When it detects a modification, it shows a notification: "The devcontainer configuration has changed. Rebuild?". `dev-update` could:
1. `docker pull` the new image
2. Write a version comment into `.devcontainer/devcontainer.json` (e.g., `// DCT: updated to 1.7.18`)
3. VS Code detects the change and prompts the user
4. User clicks "Rebuild"

This is the simplest viable path: no CLI hacks, no extension API, no Docker socket tricks. Just leveraging VS Code's built-in file watcher. The `.devcontainer/devcontainer.json` is mounted from the host (via `workspaceMount`), so edits from inside the container are visible to VS Code on the host.

**Risk:** The file is in the user's git repo. Adding a comment changes it, which shows up in `git status`. Mitigations:
- Use a field VS Code ignores (e.g., a comment or a custom field)
- Immediately revert the change after VS Code detects it (race condition risk)
- Write to a separate file that VS Code also watches (if one exists)
- Accept the git noise — it's a one-line comment that shows the DCT version, which is useful metadata

**Testing results (2026-04-06, delete-test devcontainer):**

| Change | Triggers rebuild prompt? |
|--------|------------------------|
| Add comment `// DCT: updated to 1.7.17` | No |
| Add comment `//jalla` | No |
| Change `"init": true` → `false` | Yes (first time) |
| Change `"updateRemoteUserUID": true` → `false` | Yes (first time) |
| Change `"DCT_IMAGE_VERSION"` value in `remoteEnv` | **Yes** |

**Key finding:** VS Code only prompts once per session. After dismissing or ignoring the prompt, further changes don't re-trigger until the container is rebuilt. This is fine for `dev-update` — the user sees the prompt exactly once after the version change.

**Confirmed approach:** Add `"DCT_IMAGE_VERSION"` to `remoteEnv` in the user template. `dev-update` updates its value after `docker pull`. VS Code detects the change and shows "Configuration file(s) changed: devcontainer.json. The container might need to be rebuilt to apply the changes." with a **Rebuild** button.

The `remoteEnv` approach is ideal:
- Real config field that VS Code watches and triggers on
- The value is useful metadata (version available inside the container as `$DCT_IMAGE_VERSION`)
- Changes on every update (version string increments)
- No hacky toggles or race conditions
- The field should be added to `devcontainer-user-template.json` so new installs have it from the start

**Option F: Notify VS Code via extension API**
Write a tiny VS Code extension that listens for a signal (file, socket) from `dev-update` and triggers rebuild. Heavy solution for a simple problem.

**Option G: Stop container + clear VS Code rebuild prompt**
```bash
docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest
echo "✅ Image updated. Your container will now restart."
echo "   VS Code will reconnect automatically."
docker stop $(hostname)
```
When the container stops, VS Code shows a "Reconnect" dialog. When user clicks it, VS Code detects the image changed and offers "Rebuild". Two clicks, but no terminal commands.

---

## Research Needed — RESOLVED

All research questions answered by testing (2026-04-06). The `remoteEnv` + `DCT_IMAGE_VERSION` approach (Option E) works. No need to investigate Options A-D, F, G — they're documented as alternatives but not needed.

Remaining: one E2E test with `:latest` image to confirm the full loop.

---

## Proposed Approach

### Phase 1: `dev-update` pulls + triggers VS Code rebuild prompt

`dev-update` already detects new versions. Change it to:
1. `docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest` (automatic)
2. Edit `.devcontainer/devcontainer.json` to trigger VS Code's file watcher
3. VS Code shows "Configuration changed — Rebuild?" prompt
4. User clicks "Rebuild"

**From 3 manual steps → 1 click.** No Docker knowledge needed. The developer runs `dev-update`, waits for the pull, clicks "Rebuild" when VS Code asks.

**Needs testing first (in delete-test devcontainer):**
- Confirm VS Code prompts on a comment change from inside the container
- Confirm the rebuild picks up the new image
- Decide how to handle the git diff (version comment is useful metadata vs git noise)

### Phase 1b: Remove `dev-sync` — single update mechanism

`dev-sync` was created before Docker was available inside the container. It downloads script zips and swaps `manage/` + `additions/` on every startup — a workaround for not being able to pull and rebuild.

With `dev-update` doing `docker pull` + rebuild trigger, `dev-sync` is redundant. Remove it to get:
- **One version** (`version.txt` only — remove `scripts-version.txt`)
- **One update command** (`dev-update` only)
- **Predictable scripts** — always what's baked in the image, no startup overwrite
- **Simpler CI** — no more zip artifact generation (`zip_dev_setup.yml` can be simplified)
- **Faster startup** — no 10s sync check on every container start

**Additional problem discovered (2026-04-06):** `dev-sync` running on startup triggers VS Code's "Configuration changed — Rebuild?" prompt on every fresh container start, because it modifies files under `.devcontainer/`. This is a false positive that trains users to click "Ignore" — exactly the opposite of what we want when `dev-update` triggers a real rebuild prompt.

**What to remove:**
- `dev-sync.sh` command + symlink
- `scripts-version.txt` version file
- Auto-sync call in `image/entrypoint.sh`
- `zip_dev_setup.yml` workflow (or simplify — still needed for `install.sh` which downloads the zip for first-time setup)
- 24-hour cache logic, rollback logic

**What to keep:**
- `install.sh` / `install.ps1` still need to download initial files for first-time setup. But that's installation, not updating.

### Phase 2: Notification on startup

When the container starts and `dev-sync` detects a newer IMAGE (not just scripts), show a visible notification:
```
⚠️  A newer DCT container image is available (1.7.17 → 1.7.18)
    Run: dev-update
```

Currently users only see this if they manually run `dev-update`. Most never do.

### Phase 3: Fully automatic (stretch goal)

If Phase 1 testing shows that VS Code reliably prompts on file changes from inside the container, explore making the pull happen on startup (background, non-blocking) with a notification when ready. The developer would just see "Update ready — click Rebuild" without running any command.

---

## Impact

| Current | After Phase 1 | After Phase 3 (stretch) |
|---------|---------------|------------------------|
| `dev-update` → shows instructions | `dev-update` → pulls + VS Code prompts | Startup pulls in background, prompts when ready |
| User runs `docker pull` manually | Automatic | Automatic |
| User opens Command Palette | VS Code prompts automatically | VS Code prompts automatically |
| User clicks "Rebuild Container" | User clicks "Rebuild" on prompt | User clicks "Rebuild" on prompt |
| **3 manual steps** | **1 command + 1 click** | **0 commands, 1 click** |

---

## Testing Log (2026-04-06)

### Test round 1: VS Code file watcher behavior (devcontainer-toolbox:local)

| # | Test | Result |
|---|------|--------|
| 1 | Add comment to devcontainer.json | No prompt |
| 2 | Change `"init": true` → `false` | Prompt appears |
| 3 | Change `"updateRemoteUserUID": true` → `false` | Prompt appears |
| 4 | Change `DCT_IMAGE_VERSION` in `remoteEnv` | Prompt appears |
| 5 | Multiple changes in same session after dismissing | No re-prompt (once per session) |

**Conclusion:** VS Code triggers on real config field changes, not comments. `remoteEnv` changes trigger. Only prompts once per session (fine — `dev-update` only runs once).

### Test round 2: docker pull from inside container

```
vscode ➜ /workspace $ docker pull ghcr.io/helpers-no/devcontainer-toolbox:latest
latest: Pulling from helpers-no/devcontainer-toolbox
...
Status: Downloaded newer image for ghcr.io/helpers-no/devcontainer-toolbox:latest
```

**Conclusion:** docker-outside-of-docker allows pulling images from inside the container. New image lands in the host's Docker store.

### Test round 3: Fresh container with ghcr.io v1.7.16

Set up `delete-test` with `"image": "ghcr.io/helpers-no/devcontainer-toolbox:1.7.16"` and `"DCT_IMAGE_VERSION": "1.7.16"`. Container started successfully. Welcome message shows: *"Container update available: v1.7.17"*.

**Issue discovered:** `dev-sync` runs on startup and modifies files, which triggers a **false** VS Code rebuild prompt before the user does anything. User sees "Configuration changed — Rebuild?" on first open — caused by sync, not by an actual update. This trains users to click "Ignore", undermining the real rebuild prompt from `dev-update`. **Strong argument for removing `dev-sync` in Phase 3 of the plan.**

### Design issue: pinned image tag vs `:latest`

The test container uses `"image": "ghcr.io/.../devcontainer-toolbox:1.7.16"` (pinned tag). If `dev-update` pulls `:latest` (v1.7.17) and triggers rebuild, VS Code rebuilds from tag `1.7.16` — the pull is wasted because the image field still points to the old tag.

**In production this isn't a problem:** `devcontainer-user-template.json` uses `:latest`, so pulling `:latest` updates the local tag and rebuild picks it up.

**For `dev-update` to handle pinned tags:** it would need to also update the `image` field in devcontainer.json (e.g., `1.7.16` → `1.7.17` or → `:latest`). This is a design decision for Phase 2:
- **Option A:** Always update image field to `:latest` after pull. Simple, but removes the user's pin.
- **Option B:** Update image field to the new version tag (e.g., `1.7.17`). Preserves pinning style.
- **Option C:** Only pull + edit `DCT_IMAGE_VERSION` if image is already `:latest`. If pinned, show instructions instead. Respects intentional pins.

**Recommendation:** Option C — don't override a user's intentional version pin. Most users have `:latest` (from the template) and the flow works. Pinned users made a deliberate choice and should update manually.

### E2E test setup

For a proper E2E test, the tester's devcontainer.json should use `:latest` (matching production). To simulate an outdated state:
1. `docker pull ghcr.io/helpers-no/devcontainer-toolbox:1.7.16`
2. `docker tag ghcr.io/helpers-no/devcontainer-toolbox:1.7.16 ghcr.io/helpers-no/devcontainer-toolbox:latest` (override local `:latest` with the old version)
3. Open container — runs v1.7.16 even though image field says `:latest`
4. Run `dev-update` — pulls real `:latest` from ghcr.io (v1.7.17), overwrites local tag
5. Edit `DCT_IMAGE_VERSION` → VS Code prompts → Rebuild → now running v1.7.17

---

## Open Problem: Template Drift for Existing Users

`dev-update` pulls the new image and updates `DCT_IMAGE_VERSION`, but does NOT add new fields to devcontainer.json. When we add features to the template (e.g., `DEV_HOST_*` env vars, new extensions, new features), existing users don't get them.

**Example:** v1.7.20 added `DEV_HOST_USER`, `DEV_HOST_USERNAME`, `DEV_HOST_OS`, `DEV_HOST_HOME` to the template. The tester (existing install) didn't get these — only new installs via `install.sh` get them.

**Options to solve:**

**Option A: `dev-update` replaces devcontainer.json entirely**
Download the latest template, overwrite the local file. Simple but dangerous — any user customizations (added extensions, custom runArgs, network settings) would be lost.

**Option B: `dev-update` merges new fields**
Download the template, compare with local file, add missing fields. Complex — need JSON merge logic (jq can't handle JSONC, but our file is now clean JSON). Would need to handle:
- New remoteEnv entries → add
- Removed entries → leave or warn?
- Changed values → keep local or use template?
- New top-level fields (features, etc.) → add

**Option C: `dev-update --sync-template`**
Separate flag that downloads the latest template and shows a diff:
```
dev-update --sync-template

Template changes available:
  + remoteEnv.DEV_HOST_USER: "${localEnv:USER}"
  + remoteEnv.DEV_HOST_USERNAME: "${localEnv:USERNAME}"
  + remoteEnv.DEV_HOST_OS: "${localEnv:OS}"
  + remoteEnv.DEV_HOST_HOME: "${localEnv:HOME}"

Apply? [y/N]
```
Interactive, safe, user sees what changes.

**Option D: Full template replacement with backup**
```
dev-update --sync-template
  → Downloads latest template
  → Backs up current to devcontainer.json.backup
  → Replaces with template
  → Restores DCT_IMAGE_VERSION from backup
  → Shows diff of what changed
```
Simple, safe (backup exists), handles all cases. User customizations in the backup can be manually re-applied.

**Recommendation:** Option D — simple, complete, safe with backup. The devcontainer.json should be treated as DCT-managed (per our docs: "developers should not need to edit this file"). If they did customize, the backup preserves their changes.

**This should be Phase 6 of the plan.**

---

## Next Steps

- [x] **Test**: VS Code triggers on `remoteEnv` config changes, not comments (2026-04-06)
- [x] **Test**: `docker pull` works from inside devcontainer (2026-04-06)
- [x] **Test**: ghcr.io versioned tags work as image source (2026-04-06)
- [x] **Finding**: `dev-sync` causes false rebuild prompt on startup — must be removed (2026-04-06)
- [x] **Finding**: pinned image tags need special handling in `dev-update` (2026-04-06)
- [x] **E2E test**: Full flow v1.7.19 → v1.7.20: notification → dev-update → pull → rebuild prompt (2026-04-06)
- [x] **E2E test**: No false prompt on clean start (confirmed — earlier false prompt was test artifact)
- [x] **Implement**: Phase 1-5 per PLAN-one-command-update.md
- [ ] **Open**: Template drift — existing users don't get new devcontainer.json fields (needs Phase 6)

---

## Gap Analysis (2026-04-06)

Reviewed for implementation readiness. Status of each gap:

### 1. End-to-end test with `:latest` — OPEN

Tester's devcontainer.json uses `"image": "devcontainer-toolbox:local"`. Must switch to `"image": "ghcr.io/helpers-no/devcontainer-toolbox:latest"` for real E2E test of pull → rebuild → verify.

### 2. Editing devcontainer.json from inside the container — RESOLVED

Confirmed working. The user tested the `DCT_IMAGE_VERSION` change via VS Code connected to the devcontainer (the edit at `/workspace/.devcontainer/devcontainer.json` inside the container is visible to VS Code on the host via the bind mount). VS Code prompted rebuild.

### 3. JSONC editing (comments in devcontainer.json) — NEEDS SOLUTION

`devcontainer.json` is JSONC (JSON with comments). `jq` cannot parse it. `dev-update` needs to update `DCT_IMAGE_VERSION` safely without destroying comments.

**Options:**
- **`sed`**: Target the specific line with a regex: `sed -i 's/"DCT_IMAGE_VERSION": ".*"/"DCT_IMAGE_VERSION": "1.7.18"/' .devcontainer/devcontainer.json`. Simple, fast, doesn't touch comments. Works as long as the field name is unique in the file (it will be).
- **`node -e`**: Use Node.js (already in the image) with a JSONC-aware parser. Heavier but correct.
- **Python `json5`**: Not in the image by default.

**Recommendation:** `sed` — one line, handles the specific field, doesn't interfere with comments. The pattern `"DCT_IMAGE_VERSION": "..."` is unique and predictable.

### 4. Existing users without `DCT_IMAGE_VERSION` — NOT NEEDED

No backward compatibility required. Only users with the field in their `devcontainer.json` get the auto-prompt. Others get the current behavior (manual instructions). The field will be in `devcontainer-user-template.json` for new installs, and `dev-sync` could add it to existing installs as a migration step if desired later.

### 5. Git noise from version changes — ACCEPTED

Changing `DCT_IMAGE_VERSION` in `devcontainer.json` shows in `git status`. This is **accepted and desired** — it tracks which DCT version each project uses. The version field is useful metadata for the team.

### 6. Network/size notification — OK AS-IS

Docker's own pull output shows progress bars, layer sizes, and download status. No need for `dev-update` to add extra progress UI. A "Downloading update (~750MB)..." message before the pull is sufficient.
