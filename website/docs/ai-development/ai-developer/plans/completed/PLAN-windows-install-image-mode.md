# Feature: Rewrite install.ps1 for Image Mode

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Rewrite `install.ps1` for the pre-built image approach (matching `install.sh`) and update all documentation with correct installation instructions for both platforms.

**Last Updated**: 2026-02-03

**Related**: [PLAN-011-prebuilt-container-image.md](../active/PLAN-011-prebuilt-container-image.md) (Phase 5 completed `install.sh`; this plan covers the Windows equivalent)

---

## Overview

The current `install.ps1` downloads a zip from GitHub releases and extracts 100+ files into `.devcontainer/`. This is the old approach. The new image-based approach (already implemented in `install.sh`) creates a single `.devcontainer/devcontainer.json` referencing the pre-built Docker image on ghcr.io.

### Current install.ps1

1. Downloads `dev_containers.zip` from GitHub releases
2. Extracts to temp directory
3. Checks for existing `.devcontainer/` — refuses to overwrite if `.version` exists, backs up otherwise
4. Copies `.devcontainer/` and `.devcontainer.extend/` from zip
5. Cleans up temp files

### New install.ps1 (matching install.sh)

1. Check Docker is installed (`docker` command available)
2. Backup existing `.devcontainer/` to `.devcontainer.backup/`
3. Create `.devcontainer/devcontainer.json` with the same template as `install.sh`
4. Pull the Docker image: `docker pull ghcr.io/terchris/devcontainer-toolbox:latest`
5. Print next steps
6. Do NOT create `.devcontainer.extend/` — entrypoint creates it on first start

### Windows-specific considerations

- The `initializeCommand` in `devcontainer.json` uses bash syntax (`git config > file 2>/dev/null || true`). On Windows, VS Code runs `initializeCommand` via the default shell (usually PowerShell). The command needs to work on PowerShell, or we need a cross-platform alternative.
- Rancher Desktop (not Docker Desktop) is the container runtime. The `docker` CLI command works the same way — Rancher Desktop provides it.
- The install command uses `irm ... | iex` (PowerShell equivalent of `curl ... | bash`).

---

## Phase 1: Rewrite install.ps1 — ✅ DONE

### Tasks

- [x] 1.1 Rewrite `install.ps1`:
  - Check Docker: `Get-Command docker` or exit with install instructions
  - Backup: if `.devcontainer` exists, rename to `.devcontainer.backup`
  - Create `.devcontainer/devcontainer.json` with the same JSONC template as `install.sh`
  - Pull image: `docker pull ghcr.io/terchris/devcontainer-toolbox:latest`
  - Print next steps
  - Do NOT create `.devcontainer.extend/`
  - Remove all zip-download logic
- [x] 1.2 Fix `initializeCommand` for cross-platform compatibility:
  - Solution: wrap the bash command in `bash -c '...'` so it works regardless of host shell
  - On Windows, `bash` is available via Git for Windows or WSL (both are prerequisites)
  - Updated both `install.sh` and `install.ps1` templates
- [x] 1.3 Update `README.md` — remove the TODO comment on the PowerShell line
- [ ] 1.4 Test on Windows (deferred — no Windows machine available; syntax uses standard PS cmdlets, verified by review)

### Validation

- `install.ps1` creates `.devcontainer/devcontainer.json` with correct image reference
- Docker image is pulled successfully
- `initializeCommand` works on both Windows (PowerShell) and macOS/Linux (bash)
- User confirms phase is complete

### Files to modify

- `install.ps1` (rewrite)
- `README.md` (remove TODO comment)
- Possibly `.devcontainer/devcontainer.json` template in `install.sh` if `initializeCommand` changes

---

## Phase 2: Update All Documentation — ✅ DONE

All documentation pages that mention installation need to be updated to reflect the new image-based approach. The install commands themselves (`curl ... | bash` and `irm ... | iex`) stay the same — but descriptions, prerequisites, and context need updating.

### What changed with the image-based approach

- Install scripts now create a single `devcontainer.json` (not 100+ files)
- The `devcontainer.json` references a pre-built Docker image on ghcr.io
- Container starts in seconds (image pull) instead of minutes (build from Dockerfile)
- No `.devcontainer.extend/` is created during install — entrypoint creates it on first start
- Updates happen via `dev-update` (pulls new image) + Rebuild Container

### Tasks

- [x] 2.1 Update `README.md`:
  - Removed `(TODO: update for image mode)` from the PowerShell install line (done in Phase 1)
  - Description already correct ("creates a single `devcontainer.json` and pulls the pre-built container image")
  - Changed prerequisites to list Rancher Desktop first (consistent with other docs)
- [x] 2.2 Update `website/docs/index.md`:
  - Added description of what install does and that container starts in seconds
  - Simplified steps 2/3 into one step (open in VS Code, click Reopen in Container)
- [x] 2.3 Update `website/docs/getting-started.md`:
  - Added description of what install script does (creates devcontainer.json, pulls image)
  - Mentioned fast startup since image is pre-pulled
  - Consolidated steps 2/3 into one step
  - ExecutionPolicy bypass command unchanged (still correct)
- [x] 2.4 Update `website/docs/about.md`:
  - Added Windows PowerShell install command alongside Mac/Linux
- [x] 2.5 Review `website/docs/what-are-devcontainers.mdx`:
  - No changes needed — content is generic devcontainer education, still accurate

### Validation

- All documentation pages show correct install commands for both platforms
- Descriptions match the new image-based approach (not the old zip-download approach)
- No references to downloading zip files or extracting 100+ files
- User confirms phase is complete

### Files to modify

- `README.md`
- `website/docs/index.md`
- `website/docs/getting-started.md`
- `website/docs/about.md`
- `website/docs/what-are-devcontainers.mdx` (review, likely no changes)

---

## Acceptance Criteria

- [ ] `install.ps1` creates image-mode `devcontainer.json` (no zip download)
- [ ] Docker image is pulled during install
- [ ] `initializeCommand` works on Windows and macOS/Linux
- [ ] README install instructions are correct for both platforms
- [ ] Existing `.devcontainer/` is backed up before overwriting
- [ ] All documentation pages updated with correct install descriptions
- [ ] Both Mac/Linux and Windows install commands shown in all relevant docs
- [ ] No remaining references to old zip-download approach in user-facing docs
