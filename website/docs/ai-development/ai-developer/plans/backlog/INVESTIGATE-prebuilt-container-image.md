# Investigate: Pre-built Container Image

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Determine the best approach for distributing devcontainer-toolbox as a pre-built container image instead of copying the `.devcontainer` folder into each developer's repo.

**Last Updated**: 2026-01-30

---

## Constraint

The developer must always see the same three folders in their project root — this cannot change:

```
project-root/
├── .devcontainer/          # Devcontainer configuration
├── .devcontainer.extend/   # Developer's custom tool selections
├── .devcontainer.secrets/  # Developer's secrets (gitignored)
└── ... (project files)
```

Whatever solution we choose must preserve this structure. The difference is what lives *inside* `.devcontainer/` — today it contains 100+ files (scripts, libraries, manage commands). The goal is to make it minimal while keeping the developer experience unchanged.

### Variable references

This project is a fork. All external URLs (registry, GitHub API) use variables so any fork works without changes:

| Variable | Default | Source |
|----------|---------|--------|
| `GITHUB_ORG` | `terchris` | GitHub Actions context or env var |
| `GITHUB_REPO` | `devcontainer-toolbox` | GitHub Actions context or env var |

Examples in this document use `${GITHUB_ORG}` / `${GITHUB_REPO}` placeholders. In scripts and CI, these resolve from environment variables. In `devcontainer.json`, the actual org/repo values are written at release time.

---

## Problem

Today, developers adopt devcontainer-toolbox by copying the `.devcontainer` folder into their project repository. This has two drawbacks:

1. **Build time** — The developer must wait for the devcontainer to be built from scratch every time a new container is created (e.g., first use, rebuild, new machine). This includes installing system packages, tools, and extensions.

2. **Repository bloat** — The full `.devcontainer` folder (scripts, libraries, manage commands, additions) is copied into the developer's repo. This adds files that are not part of their project and creates maintenance overhead when devcontainer-toolbox is updated.

---

## Questions Answered

All questions from the initial investigation are answered in [Research Findings](#research-findings):

| # | Question | Answer in |
|---|----------|-----------|
| 1 | How do devcontainer pre-built images work? | [Finding #1](#1-how-other-devcontainer-projects-distribute) |
| 2 | What lives in the image vs. developer's repo? | [Analysis: What Moves Into the Image](#analysis-what-moves-into-the-image) |
| 3 | How would developers customize/extend? | [Finding #5](#5-how-dev-setup-dev-help-dev-check-work) + [Finding #6](#6-dev-container-features--not-needed) |
| 4 | How would updates be distributed? | [Recommendation: Image details](#image-details) |
| 5 | How would manage commands work? | [Finding #5](#5-how-dev-setup-dev-help-dev-check-work) + [Path Resolution Design](#path-resolution-design) |
| 6 | Can we support both approaches? | [Path Resolution Design](#script-path-resolution-backwards-compatible) (yes, backwards compatible) |
| 7 | Hosting options and costs? | [Finding #3](#3-github-container-registry-ghcrio-limits) |
| 8 | Effect on release workflow? | [Recommendation: Next Steps](#next-steps) |

---

## Current State

### How it works today

1. Developer downloads a release zip from GitHub
2. Extracts `.devcontainer` folder into their project repo
3. Opens in VS Code → devcontainer builds from `Dockerfile` and `devcontainer.json`
4. Build installs base image + enabled tools from `.devcontainer/additions/`
5. Updates via `dev-update` which downloads a new zip and replaces files

### What's in .devcontainer/ today

```
.devcontainer/
├── devcontainer.json          # Config — developer needs this
├── Dockerfile.base            # Build instructions — 237 lines
├── manage/                    # dev-setup, dev-help, dev-check, dev-docs, etc.
├── additions/                 # Install scripts, config scripts, services
│   └── lib/                   # Shared libraries
├── dev-setup → manage/dev-setup.sh  # Symlinks to manage scripts
├── dev-help → manage/dev-help.sh
└── ...
```

### What Dockerfile.base installs today

Base image: `mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`

| Component | Details |
|-----------|---------|
| System packages | libcap2-bin, iputils-ping, iproute2, traceroute, jc, xdg-utils, git, curl, wget, zip, unzip, ca-certificates, gnupg, lsb-release, xz-utils |
| Node.js | v22.12.0 LTS (direct binary install, multi-arch) |
| Docker CLI | v27.5.1 (static binary, ~25MB) |
| GitHub CLI | gh (from GitHub's apt repo) |
| Supervisord | Process manager + config structure |
| User setup | vscode user, docker group, npm config |

Architecture support: amd64, arm64, armhf. (Note: armhf is dropped for the pre-built image — Microsoft's Python devcontainer base image does not publish armhf variants, and arm64 covers modern ARM devices including Apple Silicon.)

### What devcontainer.json configures today

| Setting | Purpose | Build-time or Runtime? |
|---------|---------|----------------------|
| `build.dockerfile` | Points to Dockerfile.base | Build-time |
| `build.args` (14 vars) | Host env vars (Mac/Linux/Windows username, OS info) | Build-time |
| `runArgs` | VPN capabilities (NET_ADMIN, NET_RAW, SYS_ADMIN, privileged) | Runtime |
| `customizations.vscode.extensions` | 5 universal extensions (markdown, mermaid, yaml, git-graph, shellcheck) | Runtime |
| `remoteUser` / `containerUser` | vscode | Runtime |
| `remoteEnv` | Docker socket paths | Runtime |
| `mounts` | Docker socket bind mount | Runtime |
| `workspaceFolder` / `workspaceMount` | /workspace bind mount | Runtime |
| `postCreateCommand` | `.devcontainer/manage/postCreateCommand.sh` | Runtime |
| `postStartCommand` | `.devcontainer/manage/postStartCommand.sh` | Runtime |

### Pain points

- Full rebuild takes several minutes depending on tools selected
- ~100+ files copied into developer's repo
- Symlinks don't survive zip extraction (fixed in v1.5.1 with path fallback)
- Updating requires downloading and replacing files

---

## Analysis: What Moves Into the Image

### Goes INTO the pre-built image (build once)

Everything from Dockerfile.base:
- Base OS (Debian Bookworm) + Python 3.12
- All system packages (ping, traceroute, jc, curl, wget, zip, etc.)
- Node.js 22.12.0
- Docker CLI 27.5.1
- GitHub CLI (gh)
- Supervisord + config structure
- npm configuration for vscode user

Plus the toolbox code:
- `/opt/devcontainer-toolbox/manage/` — all manage scripts
- `/opt/devcontainer-toolbox/additions/` — all install scripts + libraries
- `/opt/devcontainer-toolbox/version.txt`
- `/usr/local/bin/dev-*` → symlinks to manage scripts

### Stays in developer's repo (runtime config)

The developer's `.devcontainer/` folder shrinks to just `devcontainer.json`:

```
project-root/
├── .devcontainer/
│   └── devcontainer.json      # ~50 lines, references pre-built image
├── .devcontainer.extend/      # Developer's tool selections (as today)
│   └── enabled-tools.conf
└── .devcontainer.secrets/     # Developer's secrets (as today)
```

No Dockerfile. No manage/. No additions/. No symlinks.

### Simplified devcontainer.json

```jsonc
{
    "name": "DevContainer Toolbox",
    "image": "ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}:1.6",

    // VPN capabilities — runtime, can't be in image
    "runArgs": [
        "--cap-add=NET_ADMIN",
        "--cap-add=NET_RAW",
        "--cap-add=SYS_ADMIN",
        "--cap-add=AUDIT_WRITE",
        "--device=/dev/net/tun:/dev/net/tun",
        "--privileged"
    ],

    // VS Code extensions — runtime, per-developer
    "customizations": {
        "vscode": {
            "extensions": [
                "yzhang.markdown-all-in-one",
                "MermaidChart.vscode-mermaid-chart",
                "redhat.vscode-yaml",
                "mhutchie.git-graph",
                "timonwong.shellcheck"
            ]
        }
    },

    "remoteUser": "vscode",
    "containerUser": "vscode",

    "remoteEnv": {
        "DOCKER_HOST": "unix:///var/run/docker.sock",
        "DCT_HOME": "/opt/devcontainer-toolbox",
        "DCT_WORKSPACE": "/workspace",
        // Host env vars — all 14 build args moved to remoteEnv
        "DEV_MAC_LOGNAME": "${localEnv:LOGNAME}",
        "DEV_MAC_USER": "${localEnv:USER}",
        "DEV_LINUX_LOGNAME": "${localEnv:LOGNAME}",
        "DEV_LINUX_USER": "${localEnv:USER}",
        "DEV_WIN_USERNAME": "${localEnv:USERNAME}",
        "DEV_WIN_COMPUTERNAME": "${localEnv:COMPUTERNAME}",
        "DEV_WIN_OS": "${localEnv:OS}",
        "DEV_WIN_USERDOMAIN": "${localEnv:USERDOMAIN}",
        "DEV_WIN_PROCESSOR_ARCHITECTURE": "${localEnv:PROCESSOR_ARCHITECTURE}",
        "DEV_WIN_NUMBER_OF_PROCESSORS": "${localEnv:NUMBER_OF_PROCESSORS}",
        "DEV_WIN_PROCESSOR_IDENTIFIER": "${localEnv:PROCESSOR_IDENTIFIER}",
        "DEV_WIN_ONEDRIVE": "${localEnv:OneDrive}",
        "DEV_WIN_LOGONSERVER": "${localEnv:LOGONSERVER}",
        "DEV_WIN_USERDNSDOMAIN": "${localEnv:USERDNSDOMAIN}",
        "DEV_WIN_USERDOMAIN_ROAMINGPROFILE": "${localEnv:USERDOMAIN_ROAMINGPROFILE}"
    },

    "mounts": [
        // TODO: Podman uses a different socket path (e.g., /run/user/1000/podman/podman.sock).
        // Investigate conditional mount or Podman-compatible alternative for VS 2026 users.
        "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind,consistency=cached"
    ],

    "workspaceFolder": "/workspace",
    "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "shutdownAction": "stopContainer",
    "updateRemoteUserUID": true,
    "init": true

    // NOTE: postCreateCommand and postStartCommand are NOT needed here.
    // The image's ENTRYPOINT handles all startup logic (git safe, config
    // restoration, service startup, project-installs.sh) — regardless of
    // which IDE or tool starts the container.
    //
    // See "Container Startup Lifecycle" section for details.
}
```

### Key changes explained

| Today | Pre-built image |
|-------|----------------|
| `"build": { "dockerfile": "Dockerfile.base" }` | `"image": "ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}:1.6"` |
| `Dockerfile.base` (237 lines) | Not needed — baked into image |
| `manage/` folder in repo | Lives in image at `/opt/devcontainer-toolbox/manage/` |
| `additions/` folder in repo | Lives in image at `/opt/devcontainer-toolbox/additions/` |
| Host env vars as build args (14 vars) | Move to `remoteEnv` using `${localEnv:...}` |
| PATH includes `/workspace/.devcontainer` | Symlinks in `/usr/local/bin/` |
| `postCreateCommand` + `postStartCommand` | Replaced by image ENTRYPOINT (works with all IDEs) |
| `dev-update` downloads zip, replaces files | Change image tag in devcontainer.json |

### Host environment variables

Today these are build args passed at Docker build time and frozen into the image. With a pre-built image, they move to `remoteEnv` which supports `${localEnv:...}`. This is actually **better** — values are always fresh at runtime instead of frozen at build time.

All 14 build args move to `remoteEnv` using `${localEnv:...}`:

| Variable | Reason |
|----------|--------|
| `DEV_MAC_LOGNAME`, `DEV_MAC_USER` | Identify Mac users |
| `DEV_LINUX_LOGNAME`, `DEV_LINUX_USER` | Identify Linux users |
| `DEV_WIN_USERNAME`, `DEV_WIN_COMPUTERNAME`, `DEV_WIN_OS` | Identify Windows users |
| `DEV_WIN_USERDOMAIN`, `DEV_WIN_PROCESSOR_ARCHITECTURE` | Enterprise environments |
| `DEV_WIN_NUMBER_OF_PROCESSORS`, `DEV_WIN_PROCESSOR_IDENTIFIER`, `DEV_WIN_ONEDRIVE`, `DEV_WIN_LOGONSERVER`, `DEV_WIN_USERDNSDOMAIN`, `DEV_WIN_USERDOMAIN_ROAMINGPROFILE` | Windows system info |

---

## Path Resolution Design

### Toolbox code location

```
/opt/devcontainer-toolbox/
├── manage/                    # dev-setup.sh, dev-help.sh, dev-check.sh, dev-docs.sh, etc.
│   └── lib/                   # version-utils.sh, etc.
├── additions/                 # install-*.sh, config-*.sh, service-*.sh, cmd-*.sh
│   └── lib/                   # logging.sh, component-scanner.sh, etc.
└── version.txt
```

### Dev commands on PATH

Symlinks in `/usr/local/bin/` (built into the image):

```
/usr/local/bin/dev-setup  → /opt/devcontainer-toolbox/manage/dev-setup.sh
/usr/local/bin/dev-help   → /opt/devcontainer-toolbox/manage/dev-help.sh
/usr/local/bin/dev-check  → /opt/devcontainer-toolbox/manage/dev-check.sh
/usr/local/bin/dev-docs   → /opt/devcontainer-toolbox/manage/dev-docs.sh
```

`/usr/local/bin/` is already on PATH. This is the standard Linux way — no PATH manipulation needed.

### Script path resolution (backwards compatible)

Scripts check in this order — supports all three deployment modes:

```bash
if [ -n "$DCT_HOME" ]; then
    # Mode 1: Running from pre-built image
    TOOLBOX_DIR="$DCT_HOME"
elif [[ "$(basename "$SCRIPT_DIR")" == "manage" ]]; then
    # Mode 2: Running from .devcontainer/manage/ (current symlink approach)
    TOOLBOX_DIR="$(dirname "$SCRIPT_DIR")"
else
    # Mode 3: Running from .devcontainer/ root (zip copy, v1.5.1 fix)
    TOOLBOX_DIR="$SCRIPT_DIR"
fi

MANAGE_DIR="$TOOLBOX_DIR/manage"
ADDITIONS_DIR="$TOOLBOX_DIR/additions"
```

### How scripts find user config

Environment variables set in `devcontainer.json`:

```jsonc
"remoteEnv": {
    "DCT_HOME": "/opt/devcontainer-toolbox",
    "DCT_WORKSPACE": "/workspace"
}
```

Scripts use:
- `$DCT_HOME/additions/lib/...` → toolbox code (in the image)
- `$DCT_WORKSPACE/.devcontainer.extend/` → user tool selections (in the workspace)
- `$DCT_WORKSPACE/.devcontainer.secrets/` → user secrets (in the workspace)

If `DCT_HOME` is not set, scripts fall back to current behavior (resolve from script location) — backwards compatible.

---

## Container Startup Lifecycle

### The problem

Today, `devcontainer.json` defines two lifecycle hooks:
- **`postCreateCommand`** → runs once when the container is first created
- **`postStartCommand`** → runs every time the container starts

These hooks depend on the devcontainer specification. Tools without full devcontainer support (VS 2026, plain Docker CLI, JetBrains) may not execute them. We need startup logic to run **regardless of which tool starts the container**.

### What postCreateCommand does today

| Task | Still needed with pre-built image? | Why |
|------|-----------------------------------|-----|
| Setup PATH + command symlinks | **No** — baked into image | Symlinks in `/usr/local/bin/` |
| Install welcome message to `/etc/profile.d/` | **No** — baked into image | Pre-installed |
| Mark git folder as safe | **Yes** | Depends on workspace mount path |
| Restore configs from `.devcontainer.secrets` | **Yes** | User data lives in workspace |
| Check missing configs (warn about git identity) | **Yes** | Runtime check |
| Version checks (Node, Python) | **No** | Image versions are known |
| Install enabled tools from `enabled-tools.conf` | **Yes** — for non-default tools | Default tools are baked in. Non-default tools the developer added via `dev-setup` are listed in `enabled-tools.conf` and must be re-installed on container creation |
| Run `project-installs.sh` | **Yes** | Per-project, lives in workspace |

### What postStartCommand does today

| Task | Still needed? | Why |
|------|--------------|-----|
| Refresh git identity | **Yes** | May change between starts |
| Refresh host info | **Yes** | Runtime data |
| Start supervisord services | **Yes** | Runtime processes |
| Start OTel monitoring | **Yes** | Runtime service |
| Send startup event + tool inventory | **Yes** | Runtime telemetry |

### Solution: Docker ENTRYPOINT

Bake a custom entrypoint script into the image. This runs **regardless of which tool starts the container** — VS Code, VS 2026, Docker CLI, DevPod, Codespaces, or anything else.

```dockerfile
COPY entrypoint.sh /opt/devcontainer-toolbox/entrypoint.sh
RUN chmod +x /opt/devcontainer-toolbox/entrypoint.sh
ENTRYPOINT ["/opt/devcontainer-toolbox/entrypoint.sh"]
CMD ["sleep", "infinity"]
```

```bash
#!/bin/bash
# /opt/devcontainer-toolbox/entrypoint.sh
# Runs on EVERY container start, regardless of IDE or tool.

# --- Every start ---

# Mark workspace git folder as safe (depends on mount)
git config --global --add safe.directory /workspace 2>/dev/null || true
git config --global core.fileMode false 2>/dev/null || true

# Refresh git identity (non-interactive)
if [ -f /opt/devcontainer-toolbox/additions/config-git.sh ]; then
    bash /opt/devcontainer-toolbox/additions/config-git.sh --verify 2>/dev/null || true
fi

# Refresh host info
if [ -f /opt/devcontainer-toolbox/additions/config-host-info.sh ]; then
    bash /opt/devcontainer-toolbox/additions/config-host-info.sh --refresh 2>/dev/null || true
fi

# Start supervisord services
if [ -f /etc/supervisor/supervisord.conf ]; then
    sudo supervisord -c /etc/supervisor/supervisord.conf 2>/dev/null || true
fi

# --- First start only ---
if [ ! -f /tmp/.dct-initialized ]; then

    # Restore configs from .devcontainer.secrets
    # (config restoration logic from postCreateCommand.sh)

    # Install non-default tools from enabled-tools.conf
    # Default tools are baked into the image. Any extra tools the developer
    # added via dev-setup are listed in enabled-tools.conf and must be
    # re-installed when a new container is created (e.g., after dev-update).
    if [ -f /workspace/.devcontainer.extend/enabled-tools.conf ]; then
        while IFS= read -r script_name; do
            [[ -z "$script_name" || "$script_name" == \#* ]] && continue
            if [ -f "/opt/devcontainer-toolbox/additions/$script_name" ]; then
                bash "/opt/devcontainer-toolbox/additions/$script_name"
            fi
        done < /workspace/.devcontainer.extend/enabled-tools.conf
    fi

    # Run project-specific installations
    if [ -f /workspace/.devcontainer.extend/project-installs.sh ]; then
        bash /workspace/.devcontainer.extend/project-installs.sh
    fi

    touch /tmp/.dct-initialized
fi

# Execute whatever was passed as CMD (e.g., "sleep infinity")
exec "$@"
```

### How this works across tools

See [Tool compatibility — assessed](#10-14-tool-compatibility--assessed) in Research Findings for the full compatibility matrix.

### Idempotency requirement

Since both the ENTRYPOINT and devcontainer hooks may run, all startup scripts must be **idempotent** — safe to run multiple times without side effects. This is already mostly the case:
- `git config --global --add safe.directory` — idempotent
- `config-git.sh --verify` — checks only, no-op if already configured
- `supervisord` — won't start twice (checks PID file)
- `touch /tmp/.dct-initialized` — prevents first-time logic from running again

For devcontainer-aware tools (VS Code, Codespaces), the `postCreateCommand` and `postStartCommand` in `devcontainer.json` become **optional extras** that add VS Code-specific UX (welcome messages, warnings about `dev-check`, etc.) on top of what the ENTRYPOINT already handles.

---

## Options

### Option A: Pre-built Docker Base Image

Publish a base image (e.g., `ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}:latest`) with all tools pre-installed. Developer's repo only needs `devcontainer.json` referencing the image.

**Developer's repo would contain:**
```
project-root/
├── .devcontainer/
│   └── devcontainer.json      # References pre-built image (~50 lines)
├── .devcontainer.extend/      # Developer's tool selections (as today)
│   └── enabled-tools.conf
└── .devcontainer.secrets/     # Developer's secrets (as today)
```

All scripts, libraries, and manage commands live inside the image at `/opt/devcontainer-toolbox/`.

**Pros:**
- Near-instant container start (no build step)
- Minimal files in developer's repo (1 file instead of 100+)
- Easy updates (change image tag)
- Clean separation: toolbox is infrastructure, not project code
- No more symlink/path issues

**Cons:**
- Large image size (all tools pre-installed whether needed or not)
- Less flexibility — tools are baked in at image build time
- Requires hosting and CI to build/publish images
- Multiple image variants may be needed (e.g., python-only, full, minimal)

### Option B: Dev Container Features — *Not selected*

Package each tool as a [Dev Container Feature](https://containers.dev/features). Developers select features in their `devcontainer.json`.

**Developer's repo would contain:**
```
project-root/
├── .devcontainer/
│   └── devcontainer.json      # Base image + features list
├── .devcontainer.extend/      # Developer's tool selections (as today)
│   └── enabled-tools.conf
└── .devcontainer.secrets/     # Developer's secrets (as today)
```

```jsonc
// .devcontainer/devcontainer.json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}/python": {},
    "ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}/typescript": {},
    "ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}/azure-ops": {}
  }
}
```

**Pros:**
- Developer picks exactly the tools they need
- Each feature is independently versioned
- Standard devcontainer ecosystem — works with any base image
- No large monolithic image
- Community can contribute features

**Cons:**
- Significant refactoring — each install script becomes a feature
- Still requires build time (features install at container creation)
- More complex CI/CD (publish many features instead of one image)
- Dev Container Features have a specific structure that differs from current scripts

### Option C: Hybrid — Pre-built Image + Dev Container Features — *Not selected*

Publish a base image with core tools, plus individual features for optional tools.

**Developer's repo would contain:**
```
project-root/
├── .devcontainer/
│   └── devcontainer.json      # Base image + optional features
├── .devcontainer.extend/      # Developer's tool selections (as today)
│   └── enabled-tools.conf
└── .devcontainer.secrets/     # Developer's secrets (as today)
```

**Pros:**
- Fast start (base image is cached)
- Flexible (add features as needed)
- Best of both worlds

**Cons:**
- Most complex to implement and maintain
- Two distribution mechanisms to support
- Need to decide what's "base" vs. "feature"

### Option D: Pre-built Image with Runtime Tool Selection — *Not selected*

Publish a single image with everything pre-installed but tools disabled by default. `dev-setup` enables/disables tools at runtime (instant, no install needed).

**Pros:**
- Instant start AND instant tool switching
- Single image to maintain
- `dev-setup` menu works as today, but just toggles activation
- Simplest developer experience

**Cons:**
- Largest image size (everything included)
- Wasted disk space for unused tools
- Image must be rebuilt for every tool update

---

## IDE & Tool Compatibility

The `devcontainer.json` specification is supported by multiple tools. A pre-built image approach must work across all of them.

### Tools supporting devcontainer.json

| Tool | Status | Notes |
|------|--------|-------|
| **VS Code** | Full support | Primary tool today, Dev Containers extension |
| **Visual Studio 2026** | Partial support | C++ via CMake Presets (since VS 2022 17.4). Podman support new in VS 2026. Treats containers as remote targets. Ignores VS Code-specific fields (e.g., `customizations.vscode.extensions`) |
| **GitHub Codespaces** | Full support | Cloud-hosted dev environments using devcontainer.json |
| **JetBrains (IntelliJ)** | Early support | Remote dev containers via SSH or local Docker |
| **DevPod** | Full support | Client-only tool, any backend (local, Kubernetes, cloud VMs) |
| **Ona (formerly Gitpod)** | Full support | Cloud dev environments |
| **Dev Container CLI** | Full support | Reference implementation of the spec |

Source: [containers.dev/supporting](https://containers.dev/supporting)

### Visual Studio 2026 specifics

VS 2026 (GA November 2025) brings enhanced container tooling:
- **Podman support** — developers can now choose Podman instead of Docker as container runtime
- **Improved Dockerfile analysis** — dependency scanning, size optimization recommendations
- **Background container builds** — continues editing while containers build
- **Cloud-native debugging** — real-time logs, snapshots, distributed tracing

However, VS 2026 dev container support has limitations compared to VS Code:
- Only supports C++ projects using **CMake Presets** (not general-purpose like VS Code)
- Treats dev containers as **remote Linux targets** (similar to WSL)
- **Ignores** VS Code-specific `devcontainer.json` fields (extensions, customizations)
- Compose is **not yet supported** with Podman

Sources: [VS 2026 C++ Blog](https://devblogs.microsoft.com/cppblog/whats-new-for-cpp-developers-in-visual-studio-2026-version-18-0/), [VS 2026 Podman Blog](https://developer.microsoft.com/blog/visual-studio-2026-insiders-using-podman-for-container-development)

### Implications for our approach

1. **Pre-built image works everywhere** — all tools that support `devcontainer.json` with `"image"` can use a pre-built image. This is the most compatible approach.

2. **VS Code extensions stay in devcontainer.json** — VS 2026 and other tools ignore them, so no harm including them. They are runtime config, not image content.

3. **Podman compatibility** — our image should work with both Docker and Podman. This means:
   - No Docker-specific features in the image build
   - Docker socket mount in devcontainer.json may need a Podman alternative
   - Test with both `docker` and `podman` CLI

4. **Startup lifecycle via ENTRYPOINT** — a custom Docker ENTRYPOINT ensures initialization runs regardless of IDE. Devcontainer hooks (`postCreateCommand`, `postStartCommand`) remain as optional extras for devcontainer-aware tools (VS Code, Codespaces, DevPod). See [Container Startup Lifecycle](#container-startup-lifecycle) section above.

5. **DevPod as alternative** — developers not using VS Code or VS 2026 can use DevPod to spin up the same container on any backend. Worth mentioning in documentation.

6. **GitHub Codespaces** — a pre-built image makes Codespaces startup near-instant. Currently, Codespaces would need to build from Dockerfile.base which is slow.

---

## Research Findings

### 1. How other devcontainer projects distribute

Microsoft publishes pre-built images at `mcr.microsoft.com/devcontainers/` (Python, Node, base, universal). The recommended pattern is:
- Build image via GitHub Actions using the `devcontainers/ci` action
- Push to `ghcr.io` with multi-arch support (amd64 + arm64 via Docker Buildx + QEMU)
- Reference via `"image"` in `devcontainer.json`
- Use registry-based caching for faster rebuilds

Dev Container metadata can be embedded as image labels using the Dev Container CLI, so settings from `devcontainer.json` travel with the image.

Sources: [containers.dev prebuild guide](https://containers.dev/guide/prebuild), [devcontainers/images repo](https://github.com/devcontainers/images), [Community guide: Prebuild with GitHub Actions](https://devcontainer.community/20250303-prebuild-devcontainer/)

### 2. Estimated image sizes

Our base image (`mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`) is already **2.28 GB** locally. Our pre-built image would add the toolbox scripts (~2 MB) on top — negligible.

| Image | Approximate size |
|-------|-----------------|
| Our base image (Python 3.12 + Bookworm) | 2.28 GB |
| + Node.js, Docker CLI, gh, supervisord, system packages | ~2.5 GB estimated |
| + Toolbox scripts at `/opt/devcontainer-toolbox/` | +2 MB (negligible) |
| Microsoft universal image (for comparison) | 10+ GB |

Compressed size on ghcr.io would be roughly **800 MB–1 GB** (Docker images compress ~60-70%). This is well within normal range for dev container images.

### 3. GitHub Container Registry (ghcr.io) limits

GHCR container storage and bandwidth is **currently free** — explicitly stated by GitHub. When billing eventually starts (30-day notice promised):
- Free tier: 500 MB–1 GB storage, 1 GB data transfer/month
- Paid: $0.25/GB storage, $0.50/GB transfer
- Per-layer limit: 10 GB max
- Pulls via GitHub Actions: always free
- Public packages: no rate limit currently

**Recommendation:** Use ghcr.io. It's free now, and even with future billing the costs would be minimal for a single image. Public images have no rate limits.

Source: [GitHub Packages billing](https://docs.github.com/en/billing/concepts/product-billing/github-packages)

### 4. Start time improvement

With a pre-built image:
- **First use:** Pull image (~1-2 min on fast connection for ~1 GB compressed) vs. build from scratch (3-8 min depending on tools)
- **Subsequent uses:** Container starts in seconds (image cached locally)
- **Rebuild after toolbox update:** Pull only changed layers (seconds to minutes)

The biggest win is on subsequent uses — today every rebuild re-runs Dockerfile.base.

### 5. How dev-setup, dev-help, dev-check work

No change to how these work. They're bash scripts that live at `/opt/devcontainer-toolbox/manage/` instead of `.devcontainer/manage/`. Symlinks in `/usr/local/bin/` make them available as `dev-setup`, `dev-help`, etc.

The scripts use `$DCT_HOME` to find the toolbox code and `$DCT_WORKSPACE` to find user config. The `dev-setup` interactive menu works exactly as today — developer can install additional tools at runtime.

### 6. Dev Container Features — not needed

Since we're going with Option A (pre-built image with current defaults), Dev Container Features are not needed. The image contains everything Dockerfile.base installs today. Additional tools are installed via `dev-setup` at runtime, same as today.

Features could be a future enhancement but are not required for this change.

### 7. `${localEnv:...}` in remoteEnv — confirmed working

The `devcontainer.json` spec supports `${localEnv:VARIABLE_NAME}` in `remoteEnv`. This passes host environment variables into the container at runtime.

```jsonc
"remoteEnv": {
    "DEV_MAC_LOGNAME": "${localEnv:LOGNAME}",
    "DEV_WIN_USERNAME": "${localEnv:USERNAME}"
}
```

This is actually **better** than the current build-args approach — values are fresh at every container start instead of frozen at build time.

**Known issue:** Custom `localEnv` variables exported in `~/.bashrc` may not resolve on macOS. Standard system variables (`LOGNAME`, `USER`, `USERNAME`, etc.) work reliably.

Default values are supported: `${localEnv:VAR:default_value}`

Sources: [VS Code environment variables](https://code.visualstudio.com/remote/advancedcontainers/environment-variables), [DevPod docs](https://devpod.sh/docs/developing-in-workspaces/environment-variables-in-devcontainer-json)

### 8. ENTRYPOINT approach — validated

The Docker ENTRYPOINT pattern is standard and well-supported. The entrypoint script runs the startup logic, then `exec "$@"` passes control to the CMD. This works with:
- Docker CLI: `docker run` executes ENTRYPOINT + CMD
- Podman: same behavior as Docker
- VS Code Dev Containers: respects ENTRYPOINT, adds devcontainer hooks on top
- DevPod: respects ENTRYPOINT

**Needs prototyping:** Build a test image and verify with VS Code, Docker CLI, and Podman.

### 9. Idempotency — achievable

All current startup scripts are already mostly idempotent:
- `git config --global --add safe.directory` — idempotent
- `config-git.sh --verify` — check-only, no-op if configured
- `supervisord` — checks PID file, won't start twice
- File existence checks (`/tmp/.dct-initialized`) guard first-time logic

The design ensures ENTRYPOINT + devcontainer hooks can both run without side effects.

### 10-14. Tool compatibility — assessed

| Tool | Works with pre-built image? | ENTRYPOINT runs? | Notes |
|------|---------------------------|-------------------|-------|
| **VS Code** | Yes | Yes + devcontainer hooks | Full experience |
| **Docker CLI** | Yes | Yes | ENTRYPOINT handles all setup |
| **Podman** | Yes | Yes | Same OCI image, same ENTRYPOINT |
| **VS 2026** | Yes (as remote target) | Yes | Limited to C++ CMake projects |
| **GitHub Codespaces** | Yes | Yes + devcontainer hooks | Near-instant startup |
| **DevPod** | Yes | Yes + devcontainer hooks | Any backend |
| **JetBrains** | Yes (early support) | Yes | Via SSH or local Docker |

**Needs testing:** Actual hands-on testing with Podman, Codespaces, DevPod, and VS 2026. These are implementation-phase tasks, not investigation blockers.

---

## Onboarding: New Developer Setup

### How it works today

Developers run `install.sh` (Mac/Linux) or `install.ps1` (Windows) which:
1. Downloads a release zip from GitHub
2. Extracts the full `.devcontainer/` folder (100+ files) into the project root
3. Creates `.devcontainer.extend/` with default `enabled-tools.conf`

### How it works with pre-built image

The install scripts must be rewritten. Instead of extracting a zip, they create a minimal setup:

```
project-root/
├── .devcontainer/
│   └── devcontainer.json      # Generated with correct image reference
├── .devcontainer.extend/
│   └── enabled-tools.conf     # Default (empty or with defaults)
└── .devcontainer.secrets/     # Empty directory (gitignored)
```

**New `install.sh` flow:**

1. Query GitHub API for the latest image version tag
2. Generate `devcontainer.json` with the correct image reference (`ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}:<version>`)
3. Create `.devcontainer.extend/` with default `enabled-tools.conf`
4. Create `.devcontainer.secrets/` (empty)
5. Print next steps (open in VS Code, etc.)

No zip download needed. The script generates `devcontainer.json` from a template embedded in the script itself. This also means `install.sh` / `install.ps1` must use variables for org/repo — currently they hardcode `terchris/devcontainer-toolbox`.

**Note:** Both `install.sh` and `install.ps1` must be rewritten. They currently live in the repo root.

### Migration for existing users

Existing users who already have the full `.devcontainer/` folder can switch by:
1. Running `dev-update` (which will be updated to handle the migration)
2. Or manually: replace `.devcontainer/` contents with just the new `devcontainer.json`

The migration path will be documented in the release notes. No automated migration script is planned — we tell them what to do.

---

## Update Mechanism

### How dev-update works today

1. `dev-update` downloads a release zip from GitHub
2. Extracts and replaces files in `.devcontainer/` (100+ files)
3. Writing to `devcontainer.json` triggers VS Code to prompt "Rebuild Container"
4. Developer clicks rebuild → container rebuilds from updated Dockerfile

### How dev-update works with pre-built image

The update is much simpler — only one value changes: the image tag in `devcontainer.json`.

**`dev-update` flow:**

1. Query ghcr.io registry API for the latest version tag
2. Compare with the current tag in `/workspace/.devcontainer/devcontainer.json`
3. If a newer version exists:
   - Update the `"image"` line in `devcontainer.json` (e.g., `1.6.0` → `1.6.1`)
   - The write to `devcontainer.json` triggers VS Code's "Rebuild Container" prompt — same trigger mechanism as today
   - Developer clicks rebuild → VS Code pulls the new image and recreates the container
4. If already up to date: inform the developer, no changes

```bash
# Example: dev-update checks and updates the image tag
# Parse org/repo/tag from the existing image reference in devcontainer.json
# e.g., "ghcr.io/terchris/devcontainer-toolbox:1.6.0"
image_ref=$(grep -oP '"image":\s*"\K[^"]+' /workspace/.devcontainer/devcontainer.json)
registry=$(echo "$image_ref" | cut -d'/' -f1)        # ghcr.io
gh_org=$(echo "$image_ref" | cut -d'/' -f2)           # terchris
gh_repo=$(echo "$image_ref" | cut -d'/' -f3 | cut -d':' -f1)  # devcontainer-toolbox
current_tag=$(echo "$image_ref" | cut -d':' -f2)      # 1.6.0

# Query registry for latest version
latest_tag=$(curl -s "https://api.github.com/orgs/${gh_org}/packages/container/${gh_repo}/versions" \
    | jq -r '.[0].metadata.container.tags[0]')

if [ "$current_tag" != "$latest_tag" ]; then
    sed -i "s|${gh_repo}:${current_tag}|${gh_repo}:${latest_tag}|" \
        /workspace/.devcontainer/devcontainer.json
    log_info "Updated image tag: $current_tag → $latest_tag"
    log_info "VS Code will prompt to rebuild the container."
else
    log_info "Already up to date (version $current_tag)"
fi
```

**Key design:** `dev-update` parses `GITHUB_ORG` and `GITHUB_REPO` from the existing image reference in `devcontainer.json`. No extra environment variables or config files needed — the image reference is the single source of truth. This works for any fork automatically.

### Non-VS Code IDEs

The `devcontainer.json` write trick only works in VS Code (which watches the file for changes). For other tools:

| Tool | How to apply the update |
|------|------------------------|
| **VS Code** | Automatic — writing to `devcontainer.json` triggers rebuild prompt |
| **GitHub Codespaces** | Automatic — rebuilds from updated `devcontainer.json` on next start |
| **DevPod** | `devpod up` re-reads `devcontainer.json` and pulls new image |
| **VS 2026 / JetBrains** | Developer manually restarts/recreates the container |
| **Docker CLI** | `docker pull` + `docker run` with updated image |

### Version tagging strategy

| Tag format | Example | Use case |
|------------|---------|----------|
| Exact version | `1.6.1` | Production use — pinned, predictable |
| Minor floating | `1.6` | Always gets latest patch (1.6.0 → 1.6.1 → 1.6.2) |
| `latest` | `latest` | Always newest — convenient but unpredictable |

**Recommendation:** Default `devcontainer.json` ships with exact version tags (e.g., `1.6.0`). `dev-update` bumps to the latest exact version. Developers who want auto-updates can manually change to a floating tag.

---

## Recommendation

**Go with Option A: Pre-built Docker Base Image.**

Reasoning:
1. **Matches current behavior exactly** — same tools installed by default, same `dev-setup` for extras
2. **Simplest to implement** — one Dockerfile, one image, one GitHub Actions workflow
3. **Biggest developer win** — container starts in seconds instead of minutes
4. **Minimal repo footprint** — `devcontainer.json` only (1 file instead of 100+)
5. **Universal compatibility** — works with all IDEs and tools via standard Docker image + ENTRYPOINT
6. **Free hosting** — ghcr.io is currently free, and costs are minimal even with billing
7. **Easy updates** — developer changes image tag in `devcontainer.json`, done
8. **Backwards compatible** — scripts support both `$DCT_HOME` (image) and path resolution (copy) modes

### What the developer sees

**Today:**
```
.devcontainer/           # 100+ files (Dockerfile, manage/, additions/, symlinks)
.devcontainer.extend/    # Tool selections
.devcontainer.secrets/   # Secrets
```

**After:**
```
.devcontainer/           # 1 file (devcontainer.json)
.devcontainer.extend/    # Tool selections (unchanged)
.devcontainer.secrets/   # Secrets (unchanged)
```

### Image details

- **Registry:** `ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}`
- **Tags:** version-based (e.g., `1.6.0`, `latest`)
- **Multi-arch:** amd64 + arm64 (via Docker Buildx + QEMU)
- **Size:** ~2.5 GB uncompressed, ~1 GB compressed
- **Contents:** Everything from Dockerfile.base + toolbox scripts at `/opt/devcontainer-toolbox/`
- **ENTRYPOINT:** Custom startup script for universal IDE compatibility
- **CI:** GitHub Actions builds and pushes on every release

---

## Next Steps

- [ ] Create PLAN file for implementation (phased approach)
  - Phase 1: Build Dockerfile and ENTRYPOINT, test locally
  - Phase 2: GitHub Actions workflow to build and push to ghcr.io
  - Phase 3: Create simplified devcontainer.json template
  - Phase 4: Update path resolution in scripts (`$DCT_HOME` support)
  - Phase 5: Rewrite `install.sh` and `install.ps1` for image-based onboarding
  - Phase 6: Update `dev-update` mechanism (parse image ref, update tag)
  - Phase 7: Update documentation and migration guide
  - Phase 8: Test with VS Code, Docker CLI, Podman, Codespaces
- [ ] Bump version for release (MINOR: 1.6.0)

### Open items (not blockers)

These are deferred to implementation or future work:

- [ ] **Rollback mechanism** — developer changes image tag back in `devcontainer.json` and rebuilds (simple, just document it)
- [ ] **Offline/air-gapped environments** — image requires registry access; document local registry mirroring for enterprise users
- [ ] **Image signing/provenance** — cosign or Docker Content Trust for enterprise adoption
- [ ] **Podman socket mount** — investigate conditional mount or Podman-compatible alternative (see TODO in simplified devcontainer.json)
