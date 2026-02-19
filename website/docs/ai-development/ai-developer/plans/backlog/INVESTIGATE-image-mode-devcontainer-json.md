# Investigate: Publish a standalone image-mode devcontainer.json

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Provide a single, downloadable, cross-platform `devcontainer.json` for image-mode users — separate from the build-mode file used for toolbox development.

**Last Updated**: 2026-02-17

---

## Problem

The devcontainer-toolbox repo has **two different use cases** that need different `devcontainer.json` files, but only the build-mode file exists in the repo as a downloadable file.

### Two use cases, two devcontainer.json files

| | Developing the toolbox | Using the toolbox in a project |
|---|---|---|
| **Who** | Toolbox contributors | Everyone else |
| **Mode** | Build mode — builds from `Dockerfile.base` | Image mode — pulls pre-built image from ghcr.io |
| **devcontainer.json** | `.devcontainer/devcontainer.json` in the repo | Embedded inside `install.sh` and `install.ps1` |
| **Contains** | `"build": {"dockerfile": "Dockerfile.base"}` | `"image": "ghcr.io/terchris/devcontainer-toolbox:latest"` |
| **Requires** | Full `.devcontainer/` directory (100+ files) | Just the one JSON file |

### What goes wrong

1. **External tools download the wrong file.** The organisation's deployment scripts (jamf project) download `devcontainer.json` from:
   ```
   https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/.devcontainer/devcontainer.json
   ```
   This is the **build-mode** file. It fails immediately because `Dockerfile.base` doesn't exist in user projects.

2. **The image-mode file has no stable URL.** The correct image-mode `devcontainer.json` only exists embedded inside `install.sh` and `install.ps1` as heredoc/here-string content. There is no URL to download it.

3. **Cross-platform `initializeCommand` issue.** The `install.sh` template had bash-syntax `initializeCommand` that fails on Windows (`cmd.exe`). The `install.ps1` template had cmd.exe-syntax that fails on Mac/Linux. A shared devcontainer.json **must not have platform-specific shell commands.** The `initializeCommand` has been removed from both install scripts to fix this.

4. **Two copies to maintain.** The image-mode template is duplicated in `install.sh` (bash heredoc) and `install.ps1` (PowerShell here-string). Any change must be made in both places, which is error-prone.

---

## Questions to Answer

### 1. Where should the image-mode devcontainer.json live in the repo?

**Decision: `devcontainer-user-template.json` at the repo root.**

- Immediately visible in the repo
- The name makes it clear it's a template, not the toolbox's own config
- Stable download URL:
  ```
  https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/devcontainer-user-template.json
  ```

### 2. Should install.sh and install.ps1 download it instead of embedding it?

**Decision: Yes — download it, same as the jamf `devcontainer-init` scripts do.**

The jamf project's `devcontainer-init.sh` and `devcontainer-init.ps1` already implement this correctly:
- Download `devcontainer-user-template.json` from GitHub
- Create `.devcontainer/devcontainer.json` from it
- Create `.vscode/extensions.json` with `ms-vscode-remote.remote-containers` (vital — this is what triggers VS Code to offer "Reopen in Container")
- Error handling, backup of existing `.devcontainer/`, file size validation

`install.sh` and `install.ps1` must do the same:
1. Download `devcontainer-user-template.json` (not embed it)
2. Create `.vscode/extensions.json` with the Dev Containers extension recommendation (currently missing)

Internet is already required for `docker pull`, so downloading one more file adds no new dependency.

### 3. Duplication: install.sh/install.ps1 vs devcontainer-init.sh/devcontainer-init.ps1

There are currently **four scripts** doing similar work across two repos:

| Script | Repo | Platform |
|--------|------|----------|
| `install.sh` | devcontainer-toolbox | Mac/Linux |
| `install.ps1` | devcontainer-toolbox | Windows |
| `scripts-mac/devcontainer-toolbox/devcontainer-init.sh` | jamf | Mac |
| `scripts-win/devcontainer-toolbox/devcontainer-init.ps1` | jamf | Windows |

**What they share:**
- Create `.devcontainer/devcontainer.json` in a project folder
- Backup existing `.devcontainer/` if present
- Check prerequisites (Docker)

**What's different:**

| | install.sh / install.ps1 | devcontainer-init.sh / devcontainer-init.ps1 |
|---|---|---|
| **How run** | `curl ... \| bash` / `irm ... \| iex` (one-liner from anywhere) | Installed as a local command by jamf/Intune |
| **devcontainer.json** | Embeds JSON as heredoc (wrong — should download) | Downloads from GitHub URL (right approach, wrong URL) |
| **.vscode/extensions.json** | Missing (bug) | Creates it (correct) |
| **Docker pull** | Yes — pulls the image | No — separate `devcontainer-pull` script handles it |
| **Error handling** | Basic | Detailed (error codes, logging, validation) |
| **Target folder** | Current directory only | Accepts folder argument, confirms with user |

**Key difference: `devcontainer-init` is a reusable command, `install.sh`/`install.ps1` are not.**

The jamf project installs `devcontainer-init` as a command on the user's machine (via Jamf on Mac, Intune on Windows). Once installed, the user can run it on any project folder:
```bash
devcontainer-init                      # initialize current directory
devcontainer-init /path/to/my-project  # initialize a specific folder
```

`install.sh`/`install.ps1` are one-shot scripts — `curl | bash` or `irm | iex`. They initialize the current directory and are gone. If the user wants to set up another project, they have to run the full curl/irm command again.

**Question:** Should the devcontainer-toolbox repo also provide a way to install `devcontainer-init` as a reusable command for users not managed by Jamf/Intune?

**Likely answer:** Out of scope for now. The jamf project handles org-managed machines. For individuals, `curl | bash` is the standard pattern (same as Homebrew, nvm, Rust, etc.). The important fix is that all paths download from `devcontainer-user-template.json`.

**Summary of the two installation paths:**

```
Organisation-managed machines (Jamf/Intune):
  Jamf/Intune deploys devcontainer-init command → user runs devcontainer-init per project
                                                → user runs devcontainer-pull separately

Individual developers:
  User runs curl|bash (install.sh) or irm|iex (install.ps1) per project
  (downloads template + pulls image in one step)

Both paths download from:
  https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/devcontainer-user-template.json
```

### 4. Should `.vscode/extensions.json` also be a downloadable template?

Currently the `ms-vscode-remote.remote-containers` extension recommendation is hardcoded in each script. Two places already create this file:

| Where | When | Purpose |
|-------|------|---------|
| Install scripts / devcontainer-init (HOST) | Before container starts | Triggers VS Code "Reopen in Container" prompt |
| `ensure-vscode-extensions.sh` (INSIDE container) | On every container start | Safety net if host-side file is missing |

**Option A: No template — keep hardcoding the extension ID.**
- The content is just one extension ID: `ms-vscode-remote.remote-containers`
- Unlikely to change
- Scripts need merge logic for existing files anyway (can't just overwrite)

**Option B: Yes — publish `vscode-extensions-template.json` at the repo root.**
- One source of truth if we add more host-side recommended extensions later
- Scripts download it as the default, merge with existing file if present
- Consistent with the `devcontainer-user-template.json` pattern

**Decision: Option A.** The extension ID is stable and the merge logic is the complex part, not the content. Revisit if we later need multiple host-side extensions.

### 5. Should the file include version metadata?

**Decision: No.** The `"_toolboxVersion": "TOOLBOX_VERSION_PLACEHOLDER"` in the build-mode file is a legacy from the old deploy system. It was used to force container rebuilds when users had all files locally in `.devcontainer/`. With the pre-built image approach, versioning is handled by the Docker image tag (`:latest`) and `scripts-version.txt` for script updates. No version metadata needed in the user template.

The legacy `_toolboxVersion` is still referenced in 3 active files:
- `.devcontainer/devcontainer.json` — has the placeholder
- `.github/workflows/zip_dev_setup.yml` — CI replaces placeholder with version
- `website/docs/contributors/releasing.md` — documents it

These can be cleaned up in a future plan, but they only affect the build-mode workflow, not image-mode users.

**TODO:** Remove `_toolboxVersion` / `TOOLBOX_VERSION_PLACEHOLDER` from `.devcontainer/devcontainer.json`, `zip_dev_setup.yml`, and `releasing.md` when implementing this plan.

### 6. How do we prevent future confusion?

**Decision: Document in multiple places — make it impossible to miss.**

1. **`website/docs/contributors/architecture/index.md`** — Add a "Two Deployment Modes" section explaining:
   - Build mode (`.devcontainer/devcontainer.json`) — for toolbox development only
   - Image mode (`devcontainer-user-template.json`) — for all user projects
   - Why they exist, who uses which, and what breaks if you mix them up
   - The single source of truth: `devcontainer-user-template.json` at repo root

2. **`.devcontainer/devcontainer.json`** — Add a comment at the top:
   ```
   // FOR TOOLBOX DEVELOPMENT ONLY — Do NOT use this in user projects.
   // User projects use the image-mode template: devcontainer-user-template.json
   ```

3. **`README.md`** — Ensure the install instructions clearly point to `install.sh`/`install.ps1` (which download `devcontainer-user-template.json`), not to `.devcontainer/devcontainer.json`

4. **`website/docs/contributors/index.md`** — Add note in "Quick Start" that `.devcontainer/devcontainer.json` is the build-mode file for development, not the template for user projects

---

## Current State

### Files involved

| File | What it does | Problem |
|------|-------------|---------|
| `.devcontainer/devcontainer.json` | Build-mode for toolbox development | External tools mistakenly download this |
| `install.sh` (line 37-82) | Embeds image-mode JSON as heredoc | Duplicate, was not cross-platform |
| `install.ps1` (line 40-87) | Embeds image-mode JSON as here-string | Duplicate, was not cross-platform |
| `image/Dockerfile` | Docker image build instructions | — |
| `image/entrypoint.sh` | Container startup script | Handles missing git identity gracefully |

### External consumers (known)

| Project | Script | Downloads from |
|---------|--------|---------------|
| jamf (organisation deployment) | `scripts-mac/devcontainer-toolbox/devcontainer-init.sh` | `raw.githubusercontent.com/.../main/.devcontainer/devcontainer.json` (WRONG) |
| jamf (organisation deployment) | `scripts-win/devcontainer-toolbox/devcontainer-init.ps1` | `raw.githubusercontent.com/.../main/.devcontainer/devcontainer.json` (WRONG) |

---

## Recommended Approach

1. Create `devcontainer-user-template.json` at the repo root — the single source of truth for image-mode
2. Update `install.sh`: remove embedded JSON, download `devcontainer-user-template.json`, create `.vscode/extensions.json` (follow jamf `devcontainer-init.sh` pattern)
3. Update `install.ps1`: remove embedded JSON, download `devcontainer-user-template.json`, create `.vscode/extensions.json` (follow jamf `devcontainer-init.ps1` pattern)
4. Remove `initializeCommand` — not cross-platform, entrypoint handles git identity
5. Document the two modes clearly in the repo README
6. Notify the jamf project to update the download URL to `devcontainer-user-template.json`

After investigation, create a PLAN with the implementation details.

---

## Related

- `PLAN-windows-install-image-mode.md` — rewrote install.ps1, discovered cross-platform initializeCommand issue
- `PLAN-dev-sync-command.md` — scripts update mechanism
- jamf project: `INVESTIGATE-devcontainer-json-download-url.md` (counterpart to this investigation)
