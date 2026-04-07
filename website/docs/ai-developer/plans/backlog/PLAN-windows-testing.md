# Plan: Windows Platform Testing

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Verify that all DCT features work correctly on a Windows host with Docker Desktop (or Rancher Desktop) + WSL2.

**Priority**: High — all development and testing so far has been on macOS. No Windows validation exists.

**Last Updated**: 2026-04-07

**Prerequisites**: Access to a Windows machine with Docker Desktop or Rancher Desktop + VS Code

---

## Overview

DCT was developed and tested exclusively on macOS (Rancher Desktop, arm64). Several features make platform-specific assumptions that need Windows validation:

- `initializeCommand` — does `hostname -s` work on Windows?
- `remoteEnv` with `${localEnv:...}` — which Windows env vars are actually set?
- `config-host-info.sh` — does the Windows detection path work?
- `dev-update` — full flow including template replacement
- Docker engine info — what does `docker info` show on Docker Desktop Windows?

---

## Test Environment Setup

### Step 0: Prepare the Windows machine

1. Install Docker Desktop (or Rancher Desktop) with WSL2 backend
2. Install VS Code + Dev Containers extension
3. Create a test folder (e.g., `C:\Users\<username>\testing\dct-windows-test`)
4. Open a terminal in that folder

### Step 1: Install DCT

```powershell
# Run the install script
irm https://raw.githubusercontent.com/helpers-no/devcontainer-toolbox/main/install.ps1 | iex
```

Or if using bash (WSL2 / Git Bash):
```bash
curl -fsSL https://raw.githubusercontent.com/helpers-no/devcontainer-toolbox/main/install.sh | bash
```

Expected: `.devcontainer/devcontainer.json` created with latest template.

### Step 2: Open in VS Code

1. Open the test folder in VS Code
2. VS Code should prompt "Reopen in Container" — click yes
3. Wait for container to build and start

Expected: Container starts, welcome message shows DCT version.

---

## Phase 1: Host Environment Variables

### Test 1.1: Check which DEV_HOST_* variables are populated

```bash
config-host-info --env
```

Expected on Windows:

| Variable | Expected value |
|----------|---------------|
| `DEV_HOST_USER` | Empty (USER is Unix) |
| `DEV_HOST_USERNAME` | Windows username (e.g., `terje`) |
| `DEV_HOST_OS` | `Windows_NT` |
| `DEV_HOST_HOME` | Empty or Windows path |
| `DEV_HOST_LOGNAME` | Empty (Unix only) |
| `DEV_HOST_LANG` | May or may not be set |
| `DEV_HOST_SHELL` | Empty (Unix only) |
| `DEV_HOST_TERM_PROGRAM` | May be `vscode` |
| `DEV_HOST_HOSTNAME` | Empty (bash only) |
| `DEV_HOST_COMPUTERNAME` | Machine name (e.g., `DESKTOP-ABC123`) |
| `DEV_HOST_PROCESSOR_ARCHITECTURE` | `AMD64` or `ARM64` |
| `DEV_HOST_ONEDRIVE` | OneDrive path if configured |

**Paste the full output.** Some values may differ from expectations — that's what we're testing.

### Test 1.2: Check the .host-hostname file

```bash
cat /workspace/.devcontainer.secrets/env-vars/.host-hostname
```

Expected: The Windows machine name. This was written by `initializeCommand` on the host.

**If empty or missing**: `initializeCommand` failed on Windows. Record the error.

### Test 1.3: Check .host-info

```bash
cat /workspace/.devcontainer.secrets/env-vars/.host-info
```

Expected:
- `HOST_OS="Windows"` (not `unknown`)
- `HOST_USER` = Windows username
- `HOST_HOSTNAME` = machine name (from COMPUTERNAME or .host-hostname file)
- Docker engine fields populated

**Paste the full output.**

---

## Phase 2: Host Info Detection

### Test 2.1: Refresh and display

```bash
config-host-info --refresh
```

Expected: Shows OS, user, hostname, Docker engine info. All fields should have real values (no `unknown`).

### Test 2.2: Show saved config

```bash
config-host-info --show
```

Expected: Same values as --refresh, read from the saved file.

### Test 2.3: dev-env display

```bash
dev-env
```

Expected: HOST ENVIRONMENT section shows Windows OS, correct username, hostname.

---

## Phase 3: Docker Engine Info

### Test 3.1: Docker info from inside container

```bash
docker info --format '{{.Name}}' && docker info --format '{{.CPUs}}' && docker info --format '{{.MemTotal}}'
```

Expected: Values from Docker Desktop Windows. Record what `Name` shows (e.g., `docker-desktop`?).

### Test 3.2: Container name

```bash
docker inspect $(hostname) --format '{{.Name}}' 2>/dev/null
```

Expected: The friendly container name VS Code assigned.

---

## Phase 4: dev-update Flow

### Test 4.1: Check for updates

```bash
dev-update --check
```

Expected: Shows current version and latest version.

### Test 4.2: Full update (if an older version is available)

To test properly, the devcontainer.json should have an older `DCT_IMAGE_VERSION`. If the container is already on the latest:

1. Manually edit `.devcontainer/devcontainer.json` and change `DCT_IMAGE_VERSION` to an older version
2. Rebuild the container
3. Run `dev-update`

Expected:
- Image pulls successfully
- devcontainer.json replaced with latest template
- VS Code shows rebuild prompt
- After rebuild: container runs new version, .host-info has correct Windows values

---

## Phase 5: initializeCommand Deep Test

### Test 5.1: What shell does initializeCommand use?

Check the VS Code terminal output during container start for:
```
Running the initializeCommand from devcontainer.json...
```

Record what shell it shows (PowerShell? WSL2 bash? cmd.exe?).

### Test 5.2: Does hostname -s work?

On the Windows host (outside the container), run:

**In PowerShell:**
```powershell
hostname
```

**In WSL2 bash (if available):**
```bash
hostname -s
```

**In Git Bash (if available):**
```bash
hostname -s
```

Record which ones work and what they return.

### Test 5.3: initializeCommand fallback

If `hostname -s` failed in the container log, the fallback `hostname` should have been tried. Check if `.host-hostname` has any content.

---

## Phase 6: Edge Cases

### Test 6.1: Organization detection (if OneDrive is configured)

If the Windows machine has OneDrive configured:

```bash
echo $DEV_HOST_ONEDRIVE
config-host-info --refresh | grep -i org
```

Expected: Organization name parsed from OneDrive path.

### Test 6.2: Processor architecture

```bash
echo $DEV_HOST_PROCESSOR_ARCHITECTURE
```

Expected: `AMD64` or `ARM64` depending on the machine.

---

## Results Template

Copy this table and fill in after testing:

| Test | Result | Notes |
|------|--------|-------|
| 1.1 config-host-info --env | | |
| 1.2 .host-hostname file | | |
| 1.3 .host-info contents | | |
| 2.1 --refresh | | |
| 2.2 --show | | |
| 2.3 dev-env | | |
| 3.1 docker info | | |
| 3.2 container name | | |
| 4.1 dev-update --check | | |
| 4.2 full update flow | | |
| 5.1 initializeCommand shell | | |
| 5.2 hostname -s on host | | |
| 5.3 .host-hostname fallback | | |
| 6.1 organization detection | | |
| 6.2 processor architecture | | |

---

## Action Items After Testing

- [ ] Fix any failing tests
- [ ] Update `config-host-info.sh` if Windows detection logic needs adjustment
- [ ] Update `initializeCommand` if `hostname -s` doesn't work on Windows
- [ ] Update `devcontainer-json.md` with Windows-specific notes
- [ ] Update `startup-lifecycle.md` with Windows behavior
- [ ] Consider creating a Linux testing plan as well
