# Investigation: Azure DevOps CLI & Config (Issues #42 & #44)

## Status: ✅ COMPLETED

**Completed:** 2026-02-09

## Summary

Two related issues for lightweight Azure DevOps support:

1. **Issue #42**: `install-tool-azure-devops.sh` - Azure CLI + azure-devops extension only (no extras)
2. **Issue #44**: `config-azure-devops.sh` - PAT authentication and project defaults

---

## What Was Implemented

### Phase 1: `install-tool-azure-devops.sh` — ✅ DONE

**File:** `.devcontainer/additions/install-tool-azure-devops.sh`

Lightweight Azure CLI installation with only the azure-devops extension:
- Adds Microsoft APT repository
- Installs `azure-cli` package only (no Functions, Azurite, PowerShell)
- Installs azure-devops extension: `az extension add --name azure-devops`
- Post-install message with PR command examples
- SCRIPT_CHECK_COMMAND checks for azure-devops extension specifically

### Phase 2: `config-azure-devops.sh` — ✅ DONE

**File:** `.devcontainer/additions/config-azure-devops.sh`

Implemented with more features than originally planned:

**Core features:**
- Interactive PAT configuration with step-by-step guidance
- Persistent storage in `.devcontainer.secrets/env-vars/`
- `--show` flag to display current config
- `--verify` flag for non-interactive restore on container start

**Enhanced features (beyond original plan):**
- **URL parsing**: User pastes Azure DevOps URL from browser, script extracts org/project/repo
- **PAT validation**: Validates PAT against Azure DevOps API before saving
- **Clone integration**: Offers to clone the repository after configuration
- **Smart clone**: Clones to temp folder, moves contents to workspace root (not subfolder)
- **Preserves credentials**: `.devcontainer.secrets/` preserved during clone
- **Auto-gitignore**: Ensures `.devcontainer.secrets/` is in `.gitignore` after clone
- **Conflict handling**: If repo has `.devcontainer/`, it overwrites workspace version

**Persistent storage:**
```
.devcontainer.secrets/env-vars/
  azure-devops-pat           ← PAT token (chmod 600)
  .azure-devops-config       ← org URL, project, repo name
```

### Phase 3: Integration — ✅ DONE

- Scripts included in image via `.devcontainer/additions/` copy
- Logo created: `tool-azure-devops-logo.svg` and `config-azure-devops-logo.svg`
- Startup hints added to `entrypoint.sh` for Azure DevOps repos

### Phase 4: Testing — ✅ DONE

- Tested full flow: install CLI → configure PAT → clone repo
- Verified repo clones to workspace root (not subfolder)
- Verified `.gitignore` created with `.devcontainer.secrets/`
- Verified PAT validation works
- Verified config persists across container rebuilds

---

## Additional Fixes During Implementation

1. **Azure Application Development SCRIPT_CHECK_COMMAND** — Changed from checking `az` to checking `func` (Azure Functions Core Tools) so it doesn't show as installed when only Azure DevOps CLI is installed.

2. **"Developer Identity" renamed** — Changed to "Telemetry Identity" to avoid confusion with git/Azure identity.

3. **Entrypoint hints updated** — Simplified Azure DevOps instructions since config script now handles cloning.

---

## Files Created/Modified

| File | Action |
|------|--------|
| `.devcontainer/additions/install-tool-azure-devops.sh` | Created |
| `.devcontainer/additions/config-azure-devops.sh` | Created |
| `website/static/img/tools/src/tool-azure-devops-logo.svg` | Created |
| `website/static/img/tools/src/config-azure-devops-logo.svg` | Created |
| `image/entrypoint.sh` | Modified - added startup hints |
| `.devcontainer/additions/install-tool-azure-dev.sh` | Modified - fixed SCRIPT_CHECK_COMMAND |
| `.devcontainer/additions/config-devcontainer-identity.sh` | Modified - renamed to Telemetry Identity |

---

## User Workflow

1. Start devcontainer with empty workspace
2. Run `dev-setup` → Cloud Tools → Azure DevOps CLI
3. Run `dev-setup` → Setup & Configuration → Azure DevOps Identity
4. Paste Azure DevOps URL from browser (e.g., `https://dev.azure.com/MyOrg/MyProject/_git/MyRepo`)
5. Create PAT at provided link, paste it
6. Script validates PAT, saves config, offers to clone
7. Repo is cloned to workspace root, ready to work
