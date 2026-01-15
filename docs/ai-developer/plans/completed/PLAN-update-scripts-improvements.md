# Plan: Install and Update Scripts

## Status: Completed

**Goal**: Create install scripts for first-time setup, fix update scripts for ongoing updates, rename CLI commands to consistent dev-* pattern

**Last Updated**: 2026-01-14 (final: all features implemented and tested)

**Related**: INVESTIGATE-overall-plan-for-devcontainer-toolbox.md (Investigation 1)

---

## Overview

**Scripts needed:**

| Script | Runs Where | Purpose |
|--------|------------|---------|
| `install.sh` / `install.ps1` | Host (outside container) | First-time install - needs both for Mac/Linux/Windows |
| `dev-update` | Inside devcontainer | Update existing install - single bash script |

**Why dev-update runs inside devcontainer:**
- Always Linux environment inside container - no need for Windows/PowerShell version
- Single script to maintain
- Follows the `dev-*` CLI pattern
- No scripts cluttering the repo root

**User workflow:**

```
# First time (on host, before devcontainer exists):

# Mac/Linux:
curl -fsSL https://raw.githubusercontent.com/REPO/main/install.sh | bash

# Windows PowerShell:
irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex

# After install, repo has:
my-project/
├── .devcontainer/
│   ├── dev-update    -> manage/dev-update.sh
│   └── ...other dev-* commands...
└── .devcontainer.extend/

# Future updates (inside devcontainer):
dev-update
```

---

## Problem

Current issues:

1. No install scripts - no easy way to first-time install
2. Hardcoded URL pointing to `norwegianredcross/devcontainer-toolbox`
3. No self-update - update scripts don't update themselves
4. No version tracking - no way to know what version is installed
5. Update scripts in repo root require both bash and PowerShell versions

---

## Handling Existing Installations

Scripts must handle these scenarios:

| Scenario | .devcontainer exists? | .version exists? | Action |
|----------|----------------------|------------------|--------|
| Fresh install | No | No | Install normally |
| Previous devcontainer-toolbox (old) | Yes | No | Warn, backup, install |
| Current devcontainer-toolbox | Yes | Yes | Update normally (check version) |
| Unknown devcontainer | Yes | No | Warn, backup, install |

**Behavior:**

```bash
# Check for existing .devcontainer
if [ -d ".devcontainer" ]; then
    if [ -f ".devcontainer/.version" ]; then
        # This is devcontainer-toolbox - proceed with update
        echo "Found devcontainer-toolbox installation"
    else
        # Unknown or old installation - warn and backup
        echo "⚠️  Found existing .devcontainer without version info"
        echo "This may be from:"
        echo "  - An older devcontainer-toolbox installation"
        echo "  - A different devcontainer setup"
        echo ""
        echo "Creating backup at .devcontainer.backup"

        # Remove old backup if exists
        rm -rf .devcontainer.backup

        # Backup current
        mv .devcontainer .devcontainer.backup

        echo "✅ Backup created. Proceeding with install..."
    fi
fi
```

**For .devcontainer.extend:**

| Scenario | .devcontainer.extend exists? | Action |
|----------|------------------------------|--------|
| Fresh install | No | Create from template in zip |
| Existing (old/unknown) | Yes | Backup → Create fresh → Tell user to reconfigure |

Old `.devcontainer.extend` may have incompatible structure. Simpler to backup and start fresh.

```bash
if [ -d ".devcontainer.extend" ]; then
    echo "⚠️  Found existing .devcontainer.extend"
    echo "Creating backup at .devcontainer.extend.backup"

    rm -rf .devcontainer.extend.backup
    mv .devcontainer.extend .devcontainer.extend.backup

    echo "✅ Backup created"
fi

# Install fresh .devcontainer.extend
cp -r "$EXTRACT_DIR/.devcontainer.extend" .

echo ""
echo "📋 Your previous .devcontainer.extend is backed up."
echo "   Review .devcontainer.extend.backup and reconfigure using:"
echo "   - Edit .devcontainer.extend/enabled-tools.conf"
echo "   - Edit .devcontainer.extend/enabled-services.conf"
echo "   - Run: .devcontainer/dev-setup"
```

**Key principle:** Never silently overwrite. Backup everything, start fresh, guide user to reconfigure.

---

## Phase 0: Create install scripts

### Tasks

- [x] 0.1 Create `install.sh` for Mac/Linux
- [x] 0.2 Create `install.ps1` for Windows

### install.sh

```bash
#!/bin/bash
set -e

REPO="TOOLBOX_REPO_PLACEHOLDER"
URL="https://github.com/$REPO/releases/download/latest/dev_containers.zip"
TEMP_DIR=$(mktemp -d)

echo "Installing devcontainer-toolbox from $REPO..."

# Download
curl -fsSL "$URL" -o "$TEMP_DIR/dev_containers.zip"

# Extract
unzip -q "$TEMP_DIR/dev_containers.zip" -d "$TEMP_DIR/extract"

# Copy .devcontainer
cp -r "$TEMP_DIR/extract/.devcontainer" .

# Only copy .devcontainer.extend if it doesn't exist
if [ ! -d ".devcontainer.extend" ]; then
    cp -r "$TEMP_DIR/extract/.devcontainer.extend" .
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Installed!"
echo ""
echo "Next steps:"
echo "  1. Open this folder in VS Code"
echo "  2. When prompted, click 'Reopen in Container'"
echo "  3. Inside the container, run: dev-update (to check for updates)"
echo "  4. Run: dev-help (to see all available commands)"
```

### install.ps1

```powershell
$ErrorActionPreference = "Stop"

$repo = "TOOLBOX_REPO_PLACEHOLDER"
$url = "https://github.com/$repo/releases/download/latest/dev_containers.zip"
$tempZip = Join-Path $env:TEMP "dev_containers.zip"
$tempExtract = Join-Path $env:TEMP "dev_containers_extract"

Write-Host "Installing devcontainer-toolbox from $repo..."

# Download
Invoke-WebRequest -Uri $url -OutFile $tempZip

# Extract
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
Expand-Archive -Path $tempZip -DestinationPath $tempExtract

# Copy .devcontainer
Copy-Item -Path "$tempExtract\.devcontainer" -Destination "." -Recurse -Force

# Only copy .devcontainer.extend if it doesn't exist
if (-not (Test-Path ".devcontainer.extend")) {
    Copy-Item -Path "$tempExtract\.devcontainer.extend" -Destination "." -Recurse
}

# Cleanup
Remove-Item $tempZip -Force
Remove-Item $tempExtract -Recurse -Force

Write-Host ""
Write-Host "Installed!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open this folder in VS Code"
Write-Host "  2. When prompted, click 'Reopen in Container'"
Write-Host "  3. Inside the container, run: dev-update (to check for updates)"
Write-Host "  4. Run: dev-help (to see all available commands)"
```

### Validation

User confirms install scripts look correct.

---

## Phase 1: Update GitHub Action to build correct zip

### Tasks

- [x] 1.1 Modify `zip_dev_setup.yml` to inject repo URL into scripts
- [x] 1.2 Inject repo URL into `manage/dev-update.sh` before zipping
- [x] 1.3 Inject repo URL into `install.sh` and `install.ps1` (stay in repo for raw URL access)
- [x] 1.4 Write version from `version.txt` into `.devcontainer/.version`

### Updated workflow

```yaml
- name: Set repo URL in scripts
  run: |
    REPO="${{ github.repository }}"
    VERSION=$(cat version.txt)

    # Update dev-update.sh (goes in zip inside .devcontainer/manage/)
    sed -i "s|TOOLBOX_REPO_PLACEHOLDER|$REPO|g" .devcontainer/manage/dev-update.sh

    # Update install scripts (stay in repo for raw URL access)
    sed -i "s|TOOLBOX_REPO_PLACEHOLDER|$REPO|g" install.sh
    sed -i "s|TOOLBOX_REPO_PLACEHOLDER|$REPO|g" install.ps1

    # Write version info to .devcontainer/.version
    echo "VERSION=$VERSION" > .devcontainer/.version
    echo "REPO=$REPO" >> .devcontainer/.version
    echo "UPDATED=$(date +%Y-%m-%d)" >> .devcontainer/.version

- name: Archive dev_containers folders
  run: |
    zip -r dev_containers.zip .devcontainer .devcontainer.extend

- name: Commit updated install scripts
  run: |
    git config user.name "github-actions"
    git config user.email "github-actions@github.com"
    git add install.sh install.ps1
    git diff --staged --quiet || git commit -m "Update install scripts with repo URL"
    git push
```

### Files to modify

- `.github/workflows/zip_dev_setup.yml`
- `.devcontainer/manage/dev-update.sh` - new file with placeholder
- `install.sh` - new file with placeholder
- `install.ps1` - new file with placeholder

### Validation

User confirms GitHub Action changes look correct.

---

## Phase 2: Create dev-update.sh with self-update logic

### Tasks

- [x] 2.1 Create `manage/dev-update.sh` with version check and update logic
- [x] 2.2 Use self-copy pattern for safe self-update
- [x] 2.3 Create symlink `dev-update` -> `manage/dev-update.sh`
- [x] 2.4 Handle devcontainer.json changes (recommend rebuild)

### dev-update.sh

```bash
#!/bin/bash
# dev-update.sh - Update devcontainer-toolbox from inside the container
set -e

REPO="TOOLBOX_REPO_PLACEHOLDER"

# Self-copy pattern: copy to temp and exec from there for safe self-update
if [ -z "$DEV_UPDATE_RUNNING_FROM_TEMP" ]; then
    TEMP_SCRIPT=$(mktemp)
    cp "$0" "$TEMP_SCRIPT"
    chmod +x "$TEMP_SCRIPT"
    DEV_UPDATE_RUNNING_FROM_TEMP=1 exec "$TEMP_SCRIPT" "$@"
fi

# Parse arguments
FORCE=false
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    FORCE=true
fi

# Find workspace root (where .devcontainer is)
WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$WORKSPACE_ROOT"

echo "Checking for updates from $REPO..."

# Read current installed version
CURRENT_VERSION=""
if [ -f ".devcontainer/.version" ]; then
    CURRENT_VERSION=$(grep "^VERSION=" .devcontainer/.version | cut -d= -f2)
fi

# Fetch remote version
REMOTE_VERSION=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/main/version.txt" 2>/dev/null || echo "")

if [ -z "$REMOTE_VERSION" ]; then
    echo "Error: Could not fetch remote version"
    exit 1
fi

# Compare versions
if [ "$FORCE" = false ] && [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo "Already up to date (version $CURRENT_VERSION)"
    exit 0
fi

if [ -n "$CURRENT_VERSION" ]; then
    echo "Updating from $CURRENT_VERSION to $REMOTE_VERSION..."
else
    echo "Installing version $REMOTE_VERSION..."
fi

# Download and extract
TEMP_DIR=$(mktemp -d)
URL="https://github.com/$REPO/releases/download/latest/dev_containers.zip"

curl -fsSL "$URL" -o "$TEMP_DIR/dev_containers.zip"
unzip -q "$TEMP_DIR/dev_containers.zip" -d "$TEMP_DIR/extract"

# Check if devcontainer.json changed
REBUILD_NEEDED=false
if [ -f ".devcontainer/devcontainer.json" ]; then
    if ! diff -q "$TEMP_DIR/extract/.devcontainer/devcontainer.json" ".devcontainer/devcontainer.json" > /dev/null 2>&1; then
        REBUILD_NEEDED=true
    fi
fi

# Handle existing .devcontainer.extend
if [ -d ".devcontainer.extend" ]; then
    echo "⚠️  Backing up .devcontainer.extend..."
    rm -rf .devcontainer.extend.backup
    mv .devcontainer.extend .devcontainer.extend.backup
fi

# Replace .devcontainer
rm -rf .devcontainer
cp -r "$TEMP_DIR/extract/.devcontainer" .

# Install fresh .devcontainer.extend
cp -r "$TEMP_DIR/extract/.devcontainer.extend" .

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Updated to version $REMOTE_VERSION"

if [ -d ".devcontainer.extend.backup" ]; then
    echo ""
    echo "📋 Your previous .devcontainer.extend is backed up."
    echo "   Review .devcontainer.extend.backup and reconfigure:"
    echo "   - Edit .devcontainer.extend/enabled-tools.conf"
    echo "   - Run: dev-setup"
fi

if [ "$REBUILD_NEEDED" = true ]; then
    echo ""
    echo "⚠️  devcontainer.json has changed."
    echo "   Rebuild the container for changes to take effect:"
    echo "   - VS Code: Cmd/Ctrl+Shift+P > 'Rebuild Container'"
fi
```

### Validation

User confirms dev-update.sh looks correct.

---

## Phase 3: Create version.txt

### Tasks

- [x] 3.1 Create `version.txt` in repo root with initial version (e.g., "1.0.0")
- [ ] 3.2 Document versioning policy in README or CONTRIBUTING (will do in Phase 5)

### version.txt

```
1.0.0
```

This file is manually updated when releasing a new version. The GitHub Action reads it and writes the version info into `.devcontainer/.version` in the zip.

### Validation

User confirms version.txt is created.

---

## Phase 4: Test the complete flow

### Tasks

- [x] 4.1 Push changes to trigger GitHub Action
- [x] 4.2 Download the release zip and verify contents
- [x] 4.3 Test install script in a target repo (fresh install)
- [x] 4.4 Open in VS Code, start devcontainer
- [x] 4.5 Inside container, run `dev-update` - should say "Already up to date"
- [x] 4.6 Run `dev-update --force` - should update anyway
- [x] 4.7 Bump version.txt, push, run `dev-update` - should update
- [x] 4.8 Verify `.devcontainer.extend/` is backed up and fresh copy installed
- [x] 4.9 Verify `dev-update` self-updates when script changes
- [ ] 4.10 Test install on repo with existing .devcontainer (no .version) - should backup

### Validation

User confirms full flow works correctly.

---

## Acceptance Criteria

- [x] Install scripts download from correct repo based on which fork built the release
- [x] `dev-update` checks version BEFORE downloading - skip if already current
- [x] `dev-update` supports `--force` flag to update even if current
- [x] `dev-update` updates itself when newer version available (self-copy pattern)
- [x] `dev-update` detects devcontainer.json changes and recommends rebuild
- [x] `.devcontainer/` is replaced completely
- [x] `.devcontainer.extend/` is backed up if exists, fresh copy installed, user told to reconfigure
- [x] Version is tracked in `.devcontainer/.version`
- [x] `version.txt` exists in repo root for remote version check
- [x] GitHub Action builds zip with correct files and version info
- [x] README.md has updated install/update instructions
- [x] All CLI commands use `dev-*` prefix
- [x] `dev-help` command shows all available commands
- [x] `dev-update` command available inside devcontainer
- [x] Script files in `manage/` match their symlink names
- [x] Welcome message shows version on terminal open
- [x] VS Code prompts for rebuild when devcontainer.json changes (via _toolboxVersion)

---

## Files to Create/Modify

**New files (repo root):**
- `install.sh` - first-time install for Mac/Linux (runs on host)
- `install.ps1` - first-time install for Windows (runs on host)
- `version.txt` - single line with version number (e.g., "1.0.0"), manually updated

**New files (.devcontainer):**
- `.devcontainer/manage/dev-update.sh` - update from inside container
- `.devcontainer/dev-update` - symlink to manage/dev-update.sh

**Modified files:**
- `.github/workflows/zip_dev_setup.yml` - inject repo URL, write version info
- `README.md` - update install/update instructions

**Files to delete:**
- `update-devcontainer.sh` - replaced by dev-update inside container
- `update-devcontainer.ps1` - replaced by dev-update inside container

**Renamed files (Phase 6):**
- `manage/check-configs.sh` → `manage/dev-check.sh`
- `manage/clean-devcontainer.sh` → `manage/dev-clean.sh`
- `additions/show-environment.sh` → `manage/dev-env.sh` (also moved)

**New CLI file (Phase 6):**
- `manage/dev-help.sh` - lists all dev-* commands

**Symlink updates (Phase 6):**
- Remove: `check-configs`, `show-environment`, `clean-devcontainer`
- Add: `dev-check`, `dev-env`, `dev-clean`, `dev-help`, `dev-update`

---

## Versioning

**Manual versioning** - you update `version.txt` when you want to release a new version.

```
# version.txt (in repo root)
1.0.0
```

**When to bump version:**
- After making changes to `.devcontainer/` that users should get
- After updating the install/update scripts
- NOT needed for documentation-only changes

**GitHub Action reads `version.txt`** and writes it to `.devcontainer/.version` in the zip, so users know what version they have installed.

---

## Phase 5: Update README.md

### Tasks

- [x] 5.1 Replace old wget-based install instructions with new curl/irm one-liners
- [x] 5.2 Add Windows execution policy fallback instructions
- [x] 5.3 Add section about updating from inside the container

### Current README install section (to replace):

```powershell
# Old Windows method
wget https://raw.githubusercontent.com/norwegianredcross/devcontainer-toolbox/refs/heads/main/update-devcontainer.ps1 -O update-devcontainer.ps1; .\update-devcontainer.ps1
```

```bash
# Old Mac/Linux method
wget https://raw.githubusercontent.com/norwegianredcross/devcontainer-toolbox/refs/heads/main/update-devcontainer.sh -O update-devcontainer.sh && chmod +x update-devcontainer.sh && ./update-devcontainer.sh
```

### New README install section:

```markdown
## Installation

### Mac/Linux

```bash
curl -fsSL https://raw.githubusercontent.com/REPO/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex
```

If you see "running scripts is disabled on this system", use:
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex"
```

## Updating

Updates are done from inside the devcontainer. Open your project in VS Code, start the devcontainer, then run:

```bash
dev-update
```

This checks for updates and applies them if available. Use `dev-update --force` to force an update.
```

### Validation

User confirms README changes look correct.

---

## Summary

**Install (first time, on host):**

Mac/Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/REPO/main/install.sh | bash
```

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex
```

If Windows shows "running scripts is disabled on this system", use:
```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex"
```

**Update (inside devcontainer):**

```bash
dev-update
```

---

## Phase 6: Rename CLI commands to consistent dev-* pattern

### Overview

All CLI commands should use the `dev-` prefix for discoverability (Tab completion) and consistency.

### Current state

| Symlink | Script | Status |
|---------|--------|--------|
| `dev-setup` | `manage/dev-setup.sh` | ✓ Already correct |
| `dev-services` | `manage/dev-services.sh` | ✓ Already correct |
| `dev-template` | `manage/dev-template.sh` | ✓ Already correct |
| `dev-update` | `manage/dev-update.sh` | ✓ New (Phase 2) |
| `check-configs` | `manage/check-configs.sh` | Needs rename |
| `show-environment` | `additions/show-environment.sh` | Needs rename + move |
| `clean-devcontainer` | `manage/clean-devcontainer.sh` | Needs rename |

### Tasks

- [x] 6.1 Rename `manage/check-configs.sh` → `manage/dev-check.sh`
- [x] 6.2 Rename `manage/clean-devcontainer.sh` → `manage/dev-clean.sh`
- [x] 6.3 Move and rename `additions/show-environment.sh` → `manage/dev-env.sh`
- [x] 6.4 Create new `manage/dev-help.sh` that lists all dev-* commands
- [x] 6.5 Update symlinks in `.devcontainer/`:
  - Remove old: `check-configs`, `show-environment`, `clean-devcontainer`
  - Add new: `dev-check`, `dev-env`, `dev-clean`, `dev-help`
- [x] 6.6 Update any scripts that reference the old names

### dev-help.sh content

```bash
#!/bin/bash
# dev-help.sh - Show available dev-* commands

cat << 'EOF'
Available dev-* commands:

  dev-setup      Configure which tools to enable
  dev-services   Manage development services
  dev-template   Create files from templates
  dev-update     Update devcontainer-toolbox
  dev-check      Validate configuration files
  dev-env        Show environment information
  dev-clean      Clean up devcontainer resources
  dev-help       Show this help message

Run any command with --help for more details.
EOF
```

### Final CLI structure

```
.devcontainer/
├── dev-check     -> manage/dev-check.sh
├── dev-clean     -> manage/dev-clean.sh
├── dev-env       -> manage/dev-env.sh
├── dev-help      -> manage/dev-help.sh
├── dev-services  -> manage/dev-services.sh
├── dev-setup     -> manage/dev-setup.sh
├── dev-template  -> manage/dev-template.sh
└── dev-update    -> manage/dev-update.sh
```

### Validation

User confirms:
- All symlinks work correctly
- `dev-help` shows correct output
- Tab completion shows all dev-* commands

---

## Phase 7: Additional Features (Implemented)

These features were added during implementation based on user feedback.

### 7.1 Welcome message on terminal open

**Files created:**
- `manage/dev-welcome.sh` - Shows version and update status when opening terminal
- `manage/lib/version-utils.sh` - Shared library for version checking

**Implementation:**
- Installed to `/etc/profile.d/` during postCreateCommand
- Sourced from `/etc/bash.bashrc` (VS Code terminal is non-login shell)
- Shows version and update availability on each new terminal

### 7.2 Version in devcontainer.json triggers rebuild

**Change:**
- Added `"_toolboxVersion": "TOOLBOX_VERSION_PLACEHOLDER"` to devcontainer.json
- GitHub Action replaces placeholder with actual version
- When dev-update downloads new version, VS Code detects devcontainer.json change and prompts for rebuild

### 7.3 Self-copy workspace path fix

**Problem:** dev-update uses self-copy pattern for safe self-update, but lost workspace path when running from temp.

**Fix:**
- Capture `DEV_UPDATE_WORKSPACE_ROOT` environment variable before self-copy
- Use exported variable after exec to temp script

### 7.4 Sudo for mounted volume permissions

**Problem:** Cannot write to mounted .devcontainer folder without elevated permissions.

**Fix:**
- Use `sudo` for rm/cp operations on .devcontainer and .devcontainer.extend
- Use `sudo chown` to restore ownership after copy

### 7.5 Always recommend rebuild after update

**Change:**
- dev-update always shows rebuild recommendation (not just when devcontainer.json changes)
- Other changes (scripts, welcome message) also require rebuild to take effect

---

## Implementation Summary

**All phases completed:**
- [x] Phase 0: Install scripts (install.sh, install.ps1)
- [x] Phase 1: GitHub Action updates
- [x] Phase 2: dev-update.sh with self-update
- [x] Phase 3: version.txt
- [x] Phase 4: Testing (completed)
- [x] Phase 5: README.md updates
- [x] Phase 6: CLI command renaming
- [x] Phase 7: Additional features

**Final version:** 1.0.3
