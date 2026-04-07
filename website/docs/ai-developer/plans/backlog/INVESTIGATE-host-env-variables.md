# Investigate: Host Environment Variables in User DCT

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Move host detection environment variables (`DEV_MAC_*`, `DEV_WIN_*`, `DEV_LINUX_*`) from the DCT dev devcontainer into the user template so scripts can detect the host platform in all user projects.

**Priority**: Medium — scripts that need host detection currently only work in the toolbox dev environment

**Last Updated**: 2026-04-06

---

## Problem

Host detection variables are defined in `.devcontainer/devcontainer.json` (toolbox development only) as `build.args`:

```json
"build": {
    "args": {
        "DEV_MAC_LOGNAME": "${localEnv:LOGNAME}",
        "DEV_MAC_USER": "${localEnv:USER}",
        "DEV_WIN_USERNAME": "${localEnv:USERNAME}",
        "DEV_WIN_OS": "${localEnv:OS}",
        ...
    }
}
```

These are **not** in `devcontainer-user-template.json`. This means:
- DCT scripts that check host platform (VPN config, path handling, Docker socket) only work in toolbox development
- User projects get no host information — scripts can't distinguish Mac from Windows from Linux
- The variables are in `build.args` which only applies during `docker build` — but user projects use a pre-built image (no build step)

---

## Current Variables

From `.devcontainer/devcontainer.json`:

### Mac/Linux
| Variable | Source | Purpose |
|----------|--------|---------|
| `DEV_MAC_LOGNAME` | `${localEnv:LOGNAME}` | Login name |
| `DEV_MAC_USER` | `${localEnv:USER}` | Username |
| `DEV_LINUX_LOGNAME` | `${localEnv:LOGNAME}` | Same as Mac (both use LOGNAME) |
| `DEV_LINUX_USER` | `${localEnv:USER}` | Same as Mac (both use USER) |

### Windows
| Variable | Source | Purpose |
|----------|--------|---------|
| `DEV_WIN_USERNAME` | `${localEnv:USERNAME}` | Windows username |
| `DEV_WIN_OS` | `${localEnv:OS}` | "Windows_NT" if Windows |
| `DEV_WIN_COMPUTERNAME` | `${localEnv:COMPUTERNAME}` | Machine name |
| `DEV_WIN_USERDNSDOMAIN` | `${localEnv:USERDNSDOMAIN}` | AD domain |
| `DEV_WIN_USERDOMAIN` | `${localEnv:USERDOMAIN}` | Domain name |
| `DEV_WIN_USERDOMAIN_ROAMINGPROFILE` | `${localEnv:USERDOMAIN_ROAMINGPROFILE}` | Roaming profile domain |
| `DEV_WIN_NUMBER_OF_PROCESSORS` | `${localEnv:NUMBER_OF_PROCESSORS}` | CPU count |
| `DEV_WIN_PROCESSOR_ARCHITECTURE` | `${localEnv:PROCESSOR_ARCHITECTURE}` | x86/AMD64/ARM64 |
| `DEV_WIN_PROCESSOR_IDENTIFIER` | `${localEnv:PROCESSOR_IDENTIFIER}` | CPU model |
| `DEV_WIN_ONEDRIVE` | `${localEnv:OneDrive}` | OneDrive path |
| `DEV_WIN_LOGONSERVER` | `${localEnv:LOGONSERVER}` | AD logon server |

---

## Audit Results (2026-04-07)

### Only one script uses these variables

`config-host-info.sh` is the **only** script that reads `DEV_MAC_*`, `DEV_WIN_*`, or `DEV_LINUX_*`. No other scripts in `manage/` or `additions/` reference them.

### Variables actually consumed by `config-host-info.sh`

**Platform detection (used on all platforms):**
| Variable | What it derives | Needed in template? |
|----------|----------------|-------------------|
| `DEV_MAC_USER` | `HOST_USER`, `HOST_OS=macOS` | Yes → mapped to `DEV_HOST_USER` |
| `DEV_LINUX_USER` | `HOST_USER`, `HOST_OS=Linux` | Yes → mapped to `DEV_HOST_USER` |
| `DEV_WIN_USERNAME` | `HOST_USER`, `HOST_OS=Windows` | Yes → mapped to `DEV_HOST_USERNAME` |

**Windows-only details (only read when `DEV_WIN_USERNAME` is set):**
| Variable | What it derives |
|----------|----------------|
| `DEV_WIN_COMPUTERNAME` | `HOST_HOSTNAME` |
| `DEV_WIN_USERDOMAIN` | `HOST_DOMAIN` |
| `DEV_WIN_PROCESSOR_ARCHITECTURE` | `HOST_ARCH` |
| `DEV_WIN_PROCESSOR_IDENTIFIER` | `HOST_CPU_MODEL_NAME` |
| `DEV_WIN_NUMBER_OF_PROCESSORS` | `HOST_CPU_LOGICAL_COUNT` |
| `DEV_WIN_ONEDRIVE` | Organization detection (via `parse_organization_from_onedrive`) |
| `DEV_WIN_LOGONSERVER` | Organization detection fallback |

**Never read by any script:**
| Variable | Status |
|----------|--------|
| `DEV_MAC_LOGNAME` | Unused — `DEV_MAC_USER` is used instead |
| `DEV_LINUX_LOGNAME` | Unused — `DEV_LINUX_USER` is used instead |
| `DEV_WIN_OS` | Unused — Windows is detected by `DEV_WIN_USERNAME` being set |
| `DEV_WIN_USERDNSDOMAIN` | Unused |
| `DEV_WIN_USERDOMAIN_ROAMINGPROFILE` | Unused |

### What's already in the user template (v1.7.23)

```json
"DEV_HOST_USER": "${localEnv:USER}",
"DEV_HOST_USERNAME": "${localEnv:USERNAME}",
"DEV_HOST_OS": "${localEnv:OS}",
"DEV_HOST_HOME": "${localEnv:HOME}",
"DEV_HOST_LOGNAME": "${localEnv:LOGNAME}",
"DEV_HOST_LANG": "${localEnv:LANG}",
"DEV_HOST_SHELL": "${localEnv:SHELL}",
"DEV_HOST_TERM_PROGRAM": "${localEnv:TERM_PROGRAM}"
```

### What's missing for `config-host-info.sh` to work

The script checks `DEV_MAC_USER`, `DEV_LINUX_USER`, `DEV_WIN_USERNAME` — not the new `DEV_HOST_*` names. Two options:

**Option A: Add old variable names to template alongside new ones.**
Keeps `config-host-info.sh` working without changes. Adds 10 more env vars (noisy).

**Option B: Update `config-host-info.sh` to use the new `DEV_HOST_*` names.**
Cleaner. Detection logic becomes:
```bash
if [ "${DEV_HOST_OS}" = "Windows_NT" ]; then
    HOST_OS="Windows"
    HOST_USER="$DEV_HOST_USERNAME"
elif [[ "${DEV_HOST_HOME}" == /Users/* ]]; then
    HOST_OS="macOS"
    HOST_USER="$DEV_HOST_USER"
else
    HOST_OS="Linux"
    HOST_USER="$DEV_HOST_USER"
fi
```
BUT: loses Windows-specific details (COMPUTERNAME, PROCESSOR_ARCHITECTURE, OneDrive organization detection) unless we add those to the template too.

**Option C (recommended): Option B + add Windows-specific vars for the details that matter.**
Add to template:
```json
"DEV_HOST_COMPUTERNAME": "${localEnv:COMPUTERNAME}",
"DEV_HOST_PROCESSOR_ARCHITECTURE": "${localEnv:PROCESSOR_ARCHITECTURE}",
"DEV_HOST_ONEDRIVE": "${localEnv:OneDrive}"
```
These are empty on Mac/Linux. Only 3 extra vars instead of 10. Covers everything `config-host-info.sh` needs.

Drop the rest (`USERDNSDOMAIN`, `USERDOMAIN_ROAMINGPROFILE`, `LOGONSERVER`, `PROCESSOR_IDENTIFIER`, `NUMBER_OF_PROCESSORS`) — not worth the noise for what they provide.

---

## Questions to Answer

### 1. Which variables do scripts actually use?

**ANSWERED** — see audit above. Only `config-host-info.sh`.

### 2. Can we simplify the variable set?

**ANSWERED** — Option C: update `config-host-info.sh` to use `DEV_HOST_*`, add 3 Windows-specific vars. Total: 11 vars in template (8 current + 3 new).

### ~~3.~~ Remaining questions

Detection logic:
- `DEV_HOST_OS` = "Windows_NT" → Windows
- `DEV_HOST_USER` is set, `DEV_HOST_OS` is empty → Mac or Linux
- Distinguish Mac from Linux via `uname` inside the container (the container is always Linux, but `${localEnv:HOME}` starting with `/Users/` indicates Mac host)

### 3. `build.args` vs `remoteEnv` — what changes?

Currently in `build.args`:
- Available during `docker build` only
- Baked into the image layer
- Not available at runtime unless the Dockerfile copies them to ENV

In `remoteEnv`:
- Available at runtime (all processes)
- Set by VS Code at container start
- Not available during build (irrelevant — user projects use pre-built image)
- Empty string if the host variable doesn't exist

For user projects using the pre-built image, `remoteEnv` is the correct mechanism.

### 4. Does adding 15 env vars to every container cause issues?

- Most will be empty strings on non-matching platforms
- `docker inspect` and `env` output becomes noisier
- No performance impact

### 5. What about non-VS Code IDEs?

`${localEnv:...}` is a VS Code / devcontainers CLI feature. JetBrains, Docker CLI, and Podman don't process these variables. The entrypoint would need a fallback for detecting the host platform without these variables (e.g., checking mount paths, hostname patterns, or uname).

### 6. Should the dev devcontainer keep its `build.args`?

The dev devcontainer builds from `Dockerfile.base`. The `build.args` are used during the build. If we add the same variables to `remoteEnv`, we could remove the `build.args` — unless scripts in `Dockerfile.base` reference them during build.

Check:
```bash
grep -r "DEV_MAC_\|DEV_WIN_\|DEV_LINUX_" .devcontainer/Dockerfile.base
```

---

## Proposed Approach

### Option A: Move all 15 variables to `remoteEnv` in user template

Simple, complete, backwards-compatible with any script that reads these variables.

```json
"remoteEnv": {
    "DCT_HOME": "/opt/devcontainer-toolbox",
    "DCT_WORKSPACE": "/workspace",
    "DCT_IMAGE_VERSION": "1.7.18",
    "DEV_MAC_LOGNAME": "${localEnv:LOGNAME}",
    "DEV_MAC_USER": "${localEnv:USER}",
    "DEV_LINUX_LOGNAME": "${localEnv:LOGNAME}",
    "DEV_LINUX_USER": "${localEnv:USER}",
    "DEV_WIN_USERNAME": "${localEnv:USERNAME}",
    "DEV_WIN_OS": "${localEnv:OS}",
    "DEV_WIN_COMPUTERNAME": "${localEnv:COMPUTERNAME}",
    "DEV_WIN_USERDNSDOMAIN": "${localEnv:USERDNSDOMAIN}",
    "DEV_WIN_USERDOMAIN": "${localEnv:USERDOMAIN}",
    "DEV_WIN_USERDOMAIN_ROAMINGPROFILE": "${localEnv:USERDOMAIN_ROAMINGPROFILE}",
    "DEV_WIN_NUMBER_OF_PROCESSORS": "${localEnv:NUMBER_OF_PROCESSORS}",
    "DEV_WIN_PROCESSOR_ARCHITECTURE": "${localEnv:PROCESSOR_ARCHITECTURE}",
    "DEV_WIN_PROCESSOR_IDENTIFIER": "${localEnv:PROCESSOR_IDENTIFIER}",
    "DEV_WIN_ONEDRIVE": "${localEnv:OneDrive}",
    "DEV_WIN_LOGONSERVER": "${localEnv:LOGONSERVER}"
}
```

Pro: complete. Con: 15 extra env vars, most empty.

### Option B: Minimal set — only what scripts actually use

Audit scripts first, add only the variables that are referenced. Likely a much smaller set.

Pro: clean. Con: need to audit first, might miss future needs.

### Option C: Simplified detection — fewer variables, derive the rest

```json
"remoteEnv": {
    "DCT_HOME": "/opt/devcontainer-toolbox",
    "DCT_WORKSPACE": "/workspace",
    "DCT_IMAGE_VERSION": "1.7.18",
    "DEV_HOST_USER": "${localEnv:USER}",
    "DEV_HOST_USERNAME": "${localEnv:USERNAME}",
    "DEV_HOST_OS": "${localEnv:OS}",
    "DEV_HOST_HOME": "${localEnv:HOME}"
}
```

A library function `detect_host_platform()` derives Mac/Windows/Linux from these 4 variables. Scripts call the function instead of checking individual variables.

Pro: clean, 4 variables instead of 15. Con: requires updating scripts that currently check `DEV_WIN_OS` etc.

---

## Implementation (completed 2026-04-07)

### What was implemented

Option C was implemented with several additions discovered during testing.

**14 remoteEnv variables in user template (v1.7.31):**
- 3 DCT system: `DCT_HOME`, `DCT_WORKSPACE`, `DCT_IMAGE_VERSION`
- 8 generic host: `DEV_HOST_USER`, `DEV_HOST_USERNAME`, `DEV_HOST_OS`, `DEV_HOST_HOME`, `DEV_HOST_LOGNAME`, `DEV_HOST_LANG`, `DEV_HOST_SHELL`, `DEV_HOST_TERM_PROGRAM`
- 1 Linux hostname: `DEV_HOST_HOSTNAME` (set by bash on Linux, empty on Mac/Windows)
- 3 Windows-specific: `DEV_HOST_COMPUTERNAME`, `DEV_HOST_PROCESSOR_ARCHITECTURE`, `DEV_HOST_ONEDRIVE`

**Hostname resolution chain** (in `config-host-info.sh`):
1. `DEV_HOST_HOSTNAME` — works on Linux (bash exports it)
2. `DEV_HOST_COMPUTERNAME` — works on Windows
3. `.devcontainer.secrets/env-vars/.host-hostname` — written by `initializeCommand`, works on Mac/Linux/Windows
4. Fallback: `"devcontainer"`

**`initializeCommand`** added to user template — runs `hostname -s` on the host before container starts, writes to `.devcontainer.secrets/env-vars/.host-hostname`. This is the only way to get the Mac hostname since macOS doesn't export `HOSTNAME`.

**`postStartCommand`** added to user template — runs `config-host-info.sh --verify` after VS Code connects (when remoteEnv is available). This was needed because the ENTRYPOINT runs before VS Code injects remoteEnv — `DEV_HOST_*` variables are empty during entrypoint execution.

**`config-host-info.sh` rewritten:**
- Shared `_detect_host_vars()` function — reads `DEV_HOST_*` first, falls back to legacy `DEV_MAC_*`/`DEV_WIN_*`/`DEV_LINUX_*`
- `get_host_hostname()` — resolution chain above
- `get_container_name()` — reads container name via `docker inspect $(hostname)`
- New flags: `--env` (show all DEV_HOST_* vars), `--refresh` (re-detect + show)
- `config-host-info` command available via symlink in Dockerfile
- Docker engine info captured: Name, CPUs, Memory, Architecture, OS, Container Name

**Key discovery: remoteEnv timing**

`remoteEnv` variables (`DEV_HOST_*`) are injected by VS Code AFTER the container's ENTRYPOINT runs. This means:
- ENTRYPOINT: `DEV_HOST_*` = empty → host detection writes `unknown`
- `postStartCommand`: `DEV_HOST_*` = populated → host detection works correctly
- Terminal: `DEV_HOST_*` = populated → manual `--refresh` works

Solution: `postStartCommand` in the user template handles the detection. The entrypoint still runs its detection (writes `unknown` initially), but `postStartCommand` overwrites with correct values immediately after.

The DCT dev devcontainer (`Dockerfile.base`) bakes the old `DEV_MAC_*`/`DEV_WIN_*` variables into the image via `ENV` in the Dockerfile, so the entrypoint sees them at runtime. This is why it "worked before" in the dev environment but not in user projects (which use the pre-built image without `ENV`).

### E2E test results (Mac, v1.7.31)

```
HOST_OS="macOS"
HOST_USER="terje.christensen"
HOST_HOSTNAME="MBP-J4G0G066W2"
DOCKER_CONTAINER_NAME="musing_sanderson"
DOCKER_HOST_NAME="lima-rancher-desktop"
DOCKER_HOST_CPUS="8"
DOCKER_HOST_MEMORY="15.6GiB"
DOCKER_HOST_ARCH="aarch64"
DOCKER_HOST_OS="Alpine Linux v3.23"
```

All fields populated correctly on a fresh rebuild.

---

## Issues Discovered and Fixed During Implementation

### 1. remoteEnv not available in ENTRYPOINT

`remoteEnv` variables (`DEV_HOST_*`) are injected by VS Code AFTER the container's ENTRYPOINT runs. The entrypoint saw empty variables and wrote `HOST_OS=unknown` to `.host-info`.

**Fix:** Added `postStartCommand` to the user template. It runs after VS Code connects and injects remoteEnv. Calls `config-host-info.sh --verify` to save correct host info.

**Execution order:**
1. `initializeCommand` — on host (hostname capture)
2. ENTRYPOINT — in container (no remoteEnv)
3. `postStartCommand` — in container (remoteEnv available)

### 2. Mac hostname not available via environment variables

macOS (zsh) doesn't export `HOSTNAME`. The `DEV_HOST_HOSTNAME` remoteEnv variable is empty on Mac. Linux bash exports it, Windows has `COMPUTERNAME`.

**Fix:** Added `initializeCommand` to the user template that runs `hostname -s` on the host and writes to `.devcontainer.secrets/env-vars/.host-hostname`. `config-host-info.sh` reads this file as a fallback.

### 3. DCT dev devcontainer vs user template — why it "worked before"

The DCT dev devcontainer (`Dockerfile.base`) has:
```dockerfile
ENV DEV_MAC_USER=$DEV_MAC_USER \
    DEV_WIN_USERNAME=$DEV_WIN_USERNAME \
    ...
```
Build args are baked into the image as ENV — available at runtime including in the entrypoint. This is why host detection "always worked" in the dev environment.

The user template uses the pre-built image (`image/Dockerfile`) which does NOT have these ENV lines. Host detection in the entrypoint never worked for user projects — it always wrote `unknown`. Nobody noticed because OTel wasn't widely deployed.

### 4. CI tests failing — ensure-gitignore.sh permission denied

Adding the `.devcontainer/backup/` gitignore entry to `ensure-gitignore.sh` broke CI. The CI workspace is mounted with runner-user ownership, but the container runs as `vscode`. Writing to `.gitignore` failed with "Permission denied".

This killed ALL cmd and service script `--help` tests because `logging.sh` sources `ensure-gitignore.sh` on every script invocation.

**Fix:** Wrapped all `.gitignore` writes with `2>/dev/null || true` so permission errors don't propagate.

### 5. Docker engine info for Grafana

`docker info` provides useful host data not available via environment variables: CPUs, memory, architecture, Docker engine name (which reveals the runtime: `lima-rancher-desktop`, `docker-desktop`, `orbstack`), and the container name.

Added `get_docker_server_stats()` to capture all of these and save to `.host-info`.

---

## Remaining Work

- [ ] Check if `Dockerfile.base` uses any `build.args` at build time (may need to keep them in dev devcontainer)
- [ ] Remove legacy `DEV_MAC_*`/`DEV_WIN_*`/`DEV_LINUX_*` `build.args` from dev devcontainer and `Dockerfile.base` — replace with `remoteEnv` in `.devcontainer/devcontainer.json`
- [ ] Test on Windows host (need Windows tester)
- [ ] Test on Linux host (need Linux tester)
