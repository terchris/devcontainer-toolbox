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

## Questions to Answer

### 1. Which variables do scripts actually use?

Before moving all 15 variables, audit which ones are actually read by DCT scripts. Unused variables are just noise in the environment.

```bash
grep -r "DEV_MAC_\|DEV_WIN_\|DEV_LINUX_" .devcontainer/manage/ .devcontainer/additions/
```

### 2. Can we simplify the variable set?

Instead of 15 platform-specific variables, could we derive a single `DCT_HOST_OS` variable?

```json
"remoteEnv": {
    "DEV_HOST_OS": "${localEnv:OS}",
    "DEV_HOST_USER": "${localEnv:USER}",
    "DEV_HOST_USERNAME": "${localEnv:USERNAME}"
}
```

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

## Next Steps

- [ ] Audit: which `DEV_MAC_*` / `DEV_WIN_*` / `DEV_LINUX_*` variables are actually used by scripts?
- [ ] Check if `Dockerfile.base` uses any of the `build.args`
- [ ] Decide: Option A (all 15), B (only used), or C (simplified 4)
- [ ] Implement: add chosen variables to `devcontainer-user-template.json`
- [ ] Update devcontainer-json.md documentation
- [ ] Test on Mac, Windows, and Linux hosts
