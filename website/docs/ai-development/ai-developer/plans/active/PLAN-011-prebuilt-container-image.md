# Feature: Pre-built Container Image

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Distribute devcontainer-toolbox as a pre-built Docker image so developers get near-instant container startup and only need one file (`devcontainer.json`) in their repo.

**Last Updated**: 2026-01-30

**Investigation**: [INVESTIGATE-prebuilt-container-image.md](../backlog/INVESTIGATE-prebuilt-container-image.md)

---

## Overview

Today developers copy 100+ files (`.devcontainer/` folder) into their project and wait minutes for the container to build. This plan replaces that with a pre-built image on ghcr.io containing everything from `Dockerfile.base` plus the toolbox scripts at `/opt/devcontainer-toolbox/`. The developer's repo shrinks to a single `devcontainer.json` referencing the image.

**Key design decisions** (from investigation):
- Option A chosen: single pre-built image with current default tools
- Toolbox code lives at `/opt/devcontainer-toolbox/` in the image
- Dev commands available via `/usr/local/bin/dev-*` symlinks
- Docker ENTRYPOINT handles startup for all IDEs (not just VS Code)
- `dev-update` parses org/repo from image reference — no hardcoded URLs
- All external URLs use `${GITHUB_ORG}` / `${GITHUB_REPO}` variables
- Scripts support 3 modes: `$DCT_HOME` (image), `manage/` subdir (symlinks), root dir (zip copy)

---

## Phase 1: Dockerfile and ENTRYPOINT — ✅ DONE

Build the image definition and startup script. Test locally with `docker build` and `docker run`.

### Tasks

- [x] 1.1 Create `image/Dockerfile` — base image + system packages + toolbox code + symlinks + ENTRYPOINT
- [x] 1.2 Create `image/entrypoint.sh` — startup script (every start + first start only)
- [x] 1.3 Build locally: `docker build -t devcontainer-toolbox:local -f image/Dockerfile .` ✓
- [x] 1.4 Test with `docker run`: ENTRYPOINT runs, dev commands on PATH, symlinks work ✓
- [x] 1.5 Test with VS Code Dev Containers: open a test project with `devcontainer.json` pointing to local image, verify full startup sequence

**Build notes:**
- Removed stale Yarn repo source list (`/etc/apt/sources.list.d/yarn.list`) from base image
- Docker group creation: use `getent` check instead of hardcoded GID 102
- Image files located in `image/` folder (user chose this over repo root)
- **VS Code ENTRYPOINT override**: VS Code always overrides ENTRYPOINT with `--entrypoint /bin/sh` (hardcoded in source). Fix: add `"overrideCommand": false` to `devcontainer.json` — VS Code then passes original ENTRYPOINT+CMD as arguments to `/bin/sh`, so our startup script still runs. See [devcontainers/cli#816](https://github.com/devcontainers/cli/issues/816).

### Validation

- ✅ Image builds without errors
- ✅ `docker run devcontainer-toolbox:local dev-help` prints help output
- ✅ Symlinks, DCT_HOME, Node, Docker, gh, Python all verified
- ✅ VS Code test: container starts, extensions install — `overrideCommand: false` required
- User confirms phase is complete

### Files created

- `image/Dockerfile`
- `image/entrypoint.sh`

---

## Phase 2: GitHub Actions CI — IN PROGRESS

Automate multi-arch image builds and publish to ghcr.io on every release.

### Tasks

- [x] 2.1 Create GitHub Actions workflow `.github/workflows/build-image.yml`:
  - Trigger: on push to `main` when `version.txt`, `image/`, or `.devcontainer/` changes
  - Uses `docker/setup-qemu-action` for arm64 emulation
  - Uses `docker/setup-buildx-action` for multi-arch support
  - Login to ghcr.io with `docker/login-action` using `GITHUB_TOKEN`
  - Build and push with `docker/build-push-action`:
    - Platforms: `linux/amd64,linux/arm64`
    - Tags: `ghcr.io/<repo>:<version>` and `ghcr.io/<repo>:latest`
    - Cache: `type=gha` (GitHub Actions cache)
  - Repository name lowercased for ghcr.io compatibility
  - Manual trigger via `workflow_dispatch`
- [ ] 2.2 Ensure the published image is public (ghcr.io package visibility — manual step after first push)
- [ ] 2.3 Test: push a version bump, verify image appears on ghcr.io with correct tags and both architectures

### Validation

- GitHub Actions workflow runs successfully on push
- Image is published to `ghcr.io/<org>/<repo>:<version>`
- Both amd64 and arm64 manifests are present (`docker manifest inspect`)
- User confirms phase is complete

### Files created

- `.github/workflows/build-image.yml`

---

## Phase 3: Simplified devcontainer.json Template

Create the minimal `devcontainer.json` that references the pre-built image.

### Tasks

- [ ] 3.1 Create template `devcontainer.json` with:
  - `"image"` referencing `ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}:<version>`
  - `"overrideCommand": false` — required so VS Code doesn't bypass the ENTRYPOINT
  - `runArgs` for VPN capabilities (NET_ADMIN, NET_RAW, SYS_ADMIN, AUDIT_WRITE, privileged, /dev/net/tun)
  - `customizations.vscode.extensions` (5 universal extensions)
  - `remoteEnv` with all 14 host env vars using `${localEnv:...}`, plus `DCT_HOME`, `DCT_WORKSPACE`, `DOCKER_HOST`
  - `mounts` for Docker socket (with Podman TODO comment)
  - `workspaceFolder` and `workspaceMount`
  - No `postCreateCommand` / `postStartCommand` (ENTRYPOINT handles it)
  - Comment explaining `overrideCommand: false` and why lifecycle hooks are not needed
- [ ] 3.2 Test: use the template in a test project with the image from Phase 2, verify everything works end-to-end
- [ ] 3.3 Verify all `${localEnv:...}` variables resolve correctly on macOS, Linux, and Windows hosts

### Validation

- Container starts from the template with no build step
- All dev commands work (`dev-help`, `dev-setup`, `dev-check`)
- Environment variables are populated correctly inside the container
- User confirms phase is complete

### Files to create

- Template `devcontainer.json` (location TBD — could be in `image/` folder or a separate template directory)

---

## Phase 4: Update Path Resolution in Scripts — ✅ DONE

Add `$DCT_HOME` support to all manage and additions scripts so they work in both image and copy modes.

### Tasks

- [x] 4.1 Update manage scripts (`dev-env.sh`, `dev-services.sh`, etc.) to resolve `TOOLBOX_DIR` via `$DCT_HOME` first, then `manage/` subdir, then script dir
- [x] 4.2 Fix dev-env.sh and dev-services.sh path resolution for image mode
- [x] 4.3 Add all 13 dev-* symlinks to `image/Dockerfile`
- [x] 4.4 Create `dev-log.sh` command to stream startup log from `/tmp/.dct-startup.log`
- [x] 4.5 Fix welcome message display for VS Code internal shells
- [x] 4.6 Test: all dev commands work inside the pre-built image container

### Validation

- ✅ All dev commands work in image mode (`$DCT_HOME` set)
- ✅ All dev commands work in copy mode (`$DCT_HOME` not set)
- ✅ `dev-log` shows startup log
- User confirms phase is complete

### Files modified

- `.devcontainer/manage/dev-env.sh`
- `.devcontainer/manage/dev-services.sh`
- `.devcontainer/manage/dev-log.sh` (new)
- `.devcontainer/manage/dev-welcome.sh`
- `image/Dockerfile`

---

## Phase 5: Rewrite Install Script — IN PROGRESS

Rewrite `install.sh` for image mode. Windows `install.ps1` deferred to a later phase.

### Key decisions
- Template is embedded in `install.sh` as a heredoc (not a separate file)
- Image reference uses `:latest` tag (simplest for new users)
- Do NOT create `.devcontainer.extend/` — entrypoint creates it on first start
- No `install.ps1` rewrite yet (Windows deferred)

### Tasks

- [ ] 5.1 Rewrite `install.sh`:
  - Check Docker is installed (`command -v docker`) or exit with instructions
  - Backup existing `.devcontainer/` to `.devcontainer.backup/`
  - Create `.devcontainer/devcontainer.json` from embedded heredoc template:
    - `"image": "ghcr.io/terchris/devcontainer-toolbox:latest"`
    - `"overrideCommand": false`
    - Same `runArgs` (NET_ADMIN, NET_RAW, SYS_ADMIN, AUDIT_WRITE, privileged, /dev/net/tun)
    - Same 5 VS Code extensions
    - `remoteEnv` with `DOCKER_HOST`, `DCT_HOME`, `DCT_WORKSPACE`
    - Docker socket mount
    - `workspaceFolder: /workspace`, `workspaceMount`
    - `initializeCommand` for git identity capture
    - No `postCreateCommand` / `postStartCommand` (entrypoint handles it)
  - Pull image: `docker pull ghcr.io/terchris/devcontainer-toolbox:latest`
  - Print next steps (open in VS Code, reopen in container)
- [ ] 5.2 Test `install.sh` in a fresh temp directory
- [ ] 5.3 Verify container starts from the generated `devcontainer.json`

### Validation

- `install.sh` creates `.devcontainer/devcontainer.json` with correct image reference
- Docker image is pulled successfully
- Opening the project in VS Code starts the container via the image
- User confirms phase is complete

### Files to modify

- `install.sh` (rewrite)

---

## Phase 6: Rewrite dev-update for Image Mode

Rewrite `dev-update` for image mode only (no legacy zip fallback).

### Key decisions
- REPO defaults to `terchris/devcontainer-toolbox` (no placeholder replacement needed)
- Read current version from `$DCT_HOME/version.txt`
- Docker CLI available inside container via socket mount
- Simple `docker pull :latest` — no version-specific tags in devcontainer.json
- Remove the self-copy pattern (not needed — script lives in image, not workspace)
- Remove all zip-download logic

### Tasks

- [ ] 6.1 Rewrite `dev-update.sh`:
  - Read current version from `$DCT_HOME/version.txt`
  - Fetch remote version: `curl https://raw.githubusercontent.com/$REPO/main/version.txt`
  - Compare versions
  - If newer (or `--force`): `docker pull ghcr.io/terchris/devcontainer-toolbox:latest`
  - Instruct user to rebuild: `Cmd/Ctrl+Shift+P > Rebuild Container`
  - If same: "Already up to date (version X.Y.Z)"
- [ ] 6.2 Test `dev-update --help` and `dev-update` inside container
- [ ] 6.3 Test `dev-update --force` pulls image and instructs rebuild

### Validation

- `dev-update` reports current and latest version
- `dev-update` pulls newer image when available
- `dev-update --force` pulls even when versions match
- User confirms phase is complete

### Files to modify

- `.devcontainer/manage/dev-update.sh` (rewrite)

---

## Phase 7: Documentation and Migration Guide

Update all documentation to reflect the new image-based approach.

### Tasks

- [ ] 7.1 Update `website/docs/getting-started.md` — new installation instructions
- [ ] 7.2 Update `website/README.md` if needed
- [ ] 7.3 Update `website/docs/contributors/website.md` if needed
- [ ] 7.4 Update `website/docs/configuration.md` — explain `devcontainer.json` settings
- [ ] 7.5 Add migration section to docs for existing users switching from copy to image
- [ ] 7.6 Update `CREATING-SCRIPTS.md` — note that scripts now live in the image
- [ ] 7.7 Update release notes template to mention image tag
- [ ] 7.8 Mark investigation as completed, link to this plan

### Validation

- Documentation accurately describes the new approach
- Getting started guide works for a new user
- User confirms phase is complete

### Files to modify

- `website/docs/getting-started.md`
- `website/docs/configuration.md`
- `website/docs/ai-development/ai-developer/CREATING-SCRIPTS.md`
- Other docs as identified during implementation

---

## Phase 8: Testing Across IDEs and Tools

Verify the image works with all supported tools and environments.

### Tasks

- [ ] 8.1 Test with **VS Code Dev Containers** — full end-to-end (primary)
- [ ] 8.2 Test with **Docker CLI** — `docker run`, verify ENTRYPOINT, dev commands
- [ ] 8.3 Test with **Podman** — same OCI image, verify ENTRYPOINT
- [ ] 8.4 Test with **GitHub Codespaces** — create codespace from template, verify near-instant startup
- [ ] 8.5 Test `dev-setup` runtime tool installation — install a tool, rebuild container, verify it re-installs from `enabled-tools.conf`
- [ ] 8.6 Test `dev-update` — verify version bump and rebuild flow
- [ ] 8.7 Test on both **amd64** and **arm64** hosts (Intel Mac/Linux and Apple Silicon)

### Validation

- All tests pass
- Document any tool-specific quirks or limitations
- User confirms phase is complete

---

## Acceptance Criteria

- [ ] Pre-built image is published to ghcr.io with multi-arch support (amd64 + arm64)
- [ ] Developer's repo needs only `devcontainer.json` (no Dockerfile, no manage/, no additions/)
- [ ] Container starts in seconds (image pull) instead of minutes (build)
- [ ] All dev commands work: `dev-setup`, `dev-help`, `dev-check`, `dev-docs`
- [ ] `dev-setup` installs additional tools at runtime (same as today)
- [ ] Non-default tools from `enabled-tools.conf` are re-installed on container rebuild
- [ ] `dev-update` updates the image tag and triggers VS Code rebuild
- [ ] `install.sh` / `install.ps1` set up the image-based approach for new users
- [ ] ENTRYPOINT handles startup for all IDEs (VS Code, Docker CLI, Podman, Codespaces)
- [ ] Scripts work in both image mode (`$DCT_HOME`) and copy mode (backwards compatible)
- [ ] All external URLs use variables — works on any fork
- [ ] GitHub Actions builds and publishes the image automatically on release

---

## Implementation Notes

- **Dockerfile location**: `image/` folder (decided in Phase 1).
- **Version tagging**: Use exact version tags by default (e.g., `1.6.0`). Also tag `latest`. Consider minor floating tags (`1.6`) later.
- **armhf dropped**: Microsoft's Python base image doesn't publish armhf variants. arm64 covers Apple Silicon and modern ARM.
- **Podman socket**: Docker socket mount in `devcontainer.json` needs a Podman alternative. Flagged as TODO, investigate during Phase 8.
- **Existing release workflow**: The zip-based release (`deploy-docs.yml`, `version.txt`) continues for copy-mode users during transition. Image builds are additive, not replacing.
- **`enabled-tools.conf` format**: The ENTRYPOINT reads script names line-by-line from this file. Blank lines and `#` comments are skipped.
- **VS Code ENTRYPOINT override**: VS Code hardcodes `--entrypoint /bin/sh` for all containers. Setting `"overrideCommand": false` in `devcontainer.json` makes VS Code pass the original ENTRYPOINT+CMD as arguments to `/bin/sh`, so `entrypoint.sh` still runs. This is a known limitation ([devcontainers/cli#816](https://github.com/devcontainers/cli/issues/816)). For Docker CLI and Podman, the ENTRYPOINT works natively.
