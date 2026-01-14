# Investigate: Overall Plan for Devcontainer Toolbox

## Status: Backlog

**Goal**: Determine the overall direction and priorities for devcontainer-toolbox

**Last Updated**: 2026-01-14

---

## Questions to Answer

Goal for devcontainer-toolbox:  A setup that can be imported in all projects/repos to give the same environment to all projects.

investigate:
1. how to best get the .devcontainer folder into any repo?
   - as a submodule submodule ? (what is the pro/con)
   - installed using a script ? (pro/con)
   - other ways?

---

## Investigation 1: Distribution Method

### Option A: Git Submodule

The `.devcontainer` folder is a git submodule pointing to devcontainer-toolbox.

```bash
# Initial setup in target repo
git submodule add https://github.com/terchris/devcontainer-toolbox.git .devcontainer

# Cloning a repo that uses it
git clone --recurse-submodules <repo-url>

# Updating to latest
cd .devcontainer && git pull origin main && cd ..
git add .devcontainer && git commit -m "Update devcontainer"
```

**Pros:**
- Clear separation: toolbox is external, not mixed into project
- Easy updates: `git pull` in submodule gets latest
- Version pinning: can lock to specific commit/tag
- Git tracks which version of toolbox is used
- No duplication of files in target repo

**Cons:**
- Submodule complexity: developers must know `--recurse-submodules`
- Extra step when cloning: easy to forget, causes confusion
- CI/CD needs submodule handling
- VS Code sometimes struggles with submodules
- `.devcontainer` must be at repo root, but submodule points elsewhere
- Harder to make project-specific patches to devcontainer files

**Critical Issue:** VS Code expects `.devcontainer/devcontainer.json` at repo root. A submodule works, but the path must be exactly `.devcontainer`. This works.

---

### Option B: Install Script

A script copies/downloads the `.devcontainer` folder into the target repo.

```bash
# One-liner to install
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash

# Or with specific version
curl -fsSL .../install.sh | bash -s -- --version v1.0.0
```

**Pros:**
- Simple: one command, done
- No submodule knowledge needed
- Files are directly in the repo (easy to inspect/modify)
- Works with any CI/CD without special config
- Can include setup wizard (ask which tools to enable)

**Cons:**
- No automatic updates: must re-run script to update
- Files are duplicated in every repo
- Harder to track which version is installed
- Local modifications can conflict with updates
- Requires maintaining an install script

**Update pattern:**
```bash
# Check for updates
curl -fsSL .../update.sh | bash
# Shows diff, asks to apply
```

---

### Option C: Copy Manually

Just copy the `.devcontainer` folder from devcontainer-toolbox to target repo.

**Pros:**
- Simplest to understand
- Full control, easy to modify
- No tooling required

**Cons:**
- No update mechanism
- Easy to diverge from upstream
- Must remember where it came from
- Not scalable for many repos

---

### Option D: Template Repository

devcontainer-toolbox as a GitHub template repo. New projects start from it.

**Pros:**
- Great for new projects
- GitHub UI makes it easy
- Gets full copy including structure

**Cons:**
- Only works for NEW repos
- Doesn't help existing repos
- No update mechanism after creation

---

### Option E: Git Subtree

Like submodule but merges history into main repo.

```bash
# Add
git subtree add --prefix .devcontainer https://github.com/terchris/devcontainer-toolbox.git main --squash

# Update
git subtree pull --prefix .devcontainer https://github.com/terchris/devcontainer-toolbox.git main --squash
```

**Pros:**
- No submodule complexity for cloners
- Files are in repo, work normally
- Can still pull updates from upstream
- Can push local changes back (if desired)

**Cons:**
- Subtree commands are verbose/complex
- Merges can have conflicts
- History can get messy
- Less common, developers may not know it

---

### Comparison Matrix

| Criteria | Submodule | Script | Manual Copy | Template | Subtree |
|----------|-----------|--------|-------------|----------|---------|
| Easy initial setup | ⚠️ | ✅ | ✅ | ✅ | ⚠️ |
| Easy updates | ✅ | ⚠️ | ❌ | ❌ | ✅ |
| No extra git knowledge | ❌ | ✅ | ✅ | ✅ | ❌ |
| Works for existing repos | ✅ | ✅ | ✅ | ❌ | ✅ |
| Version tracking | ✅ | ⚠️ | ❌ | ❌ | ✅ |
| Easy local modifications | ❌ | ✅ | ✅ | ✅ | ✅ |
| CI/CD friendly | ⚠️ | ✅ | ✅ | ✅ | ✅ |

---

### Recommendation

**Primary: Install Script** with version tracking

Why:
- Lowest barrier to entry
- Works for existing repos
- No git submodule/subtree knowledge needed
- Can include interactive setup
- Files are local, easy to inspect

The script should:
1. Download specific version (tagged release)
2. Create `.devcontainer/` with core files
3. Create `.devcontainer.extend/` with defaults (if not exists)
4. Record installed version in a file (e.g., `.devcontainer/.version`)
5. Provide update command that shows diff before applying

**Secondary: Document submodule approach** for advanced users who want automatic updates.

---

### Existing Implementation

Scripts and automation already exist:

**update-devcontainer.sh** (bash) and **update-devcontainer.ps1** (PowerShell):
- Download zip from GitHub release
- Replace `.devcontainer/` completely
- Create `.devcontainer.extend/` only if it doesn't exist (preserves user config)
- Clean up temp files

**GitHub Action** (`.github/workflows/zip_dev_setup.yml`):
- Triggers on push to main
- Zips `.devcontainer` and `.devcontainer.extend`
- Creates/updates "latest" release with zip attached

**Current behavior:**
```
User runs script → Downloads latest zip → Replaces .devcontainer → Preserves .devcontainer.extend
```

**Issues to fix:**

1. **Configurable URL** - Need to support multiple repos:
   - Development fork: `terchris/devcontainer-toolbox`
   - Production: `norwegianredcross/devcontainer-toolbox`

   **Solution options:**

   **Option A: Config file in target repo**
   ```bash
   # .devcontainer.extend/toolbox-source.conf
   TOOLBOX_REPO="terchris/devcontainer-toolbox"
   # or
   TOOLBOX_REPO="norwegianredcross/devcontainer-toolbox"
   ```
   Script reads this file to determine where to download from.

   **Pros:** Config is version controlled with project, visible, easy to change
   **Cons:** Need to create file on first install

   **Option B: Script parameter**
   ```bash
   ./update-devcontainer.sh --repo terchris/devcontainer-toolbox
   # or
   curl ... | bash -s -- --repo norwegianredcross/devcontainer-toolbox
   ```

   **Pros:** Flexible, no config file needed
   **Cons:** Must remember to pass param every time

   **Option C: Environment variable**
   ```bash
   DEVCONTAINER_TOOLBOX_REPO=terchris/devcontainer-toolbox ./update-devcontainer.sh
   ```

   **Pros:** Can set in shell profile
   **Cons:** Not visible in repo, each dev must configure

   **Option D: Default in script + override**
   Script has default (norwegianredcross), but checks for:
   1. Config file first
   2. Then environment variable
   3. Then uses default

   **Recommended: Option E** - Bake URL into scripts at build time

   The GitHub Action injects the correct repo URL into the scripts when building the release zip.

   ```yaml
   # In zip_dev_setup.yml
   - name: Set repo URL in scripts
     run: |
       REPO="${{ github.repository }}"
       sed -i "s|TOOLBOX_REPO_PLACEHOLDER|$REPO|g" update-devcontainer.sh
       sed -i "s|TOOLBOX_REPO_PLACEHOLDER|$REPO|g" update-devcontainer.ps1
   ```

   **How it works:**
   - Scripts have placeholder: `TOOLBOX_REPO_PLACEHOLDER`
   - GitHub Action replaces with `${{ github.repository }}`
   - norwegianredcross fork → scripts contain `norwegianredcross/devcontainer-toolbox`
   - terchris fork → scripts contain `terchris/devcontainer-toolbox`

   **Pros:**
   - No extra config files for developers
   - Each fork automatically gets correct URL
   - URL is visible in the scripts (can be manually changed if needed)
   - Works automatically for any fork

   **Cons:**
   - None significant

   This is the simplest solution - no extra files, automatic per-fork.

2. **No version tracking** - Always downloads "latest", no way to know what version is installed or pin to specific version

3. **No diff preview** - Replaces files without showing what changed

4. **Scripts in wrong location** - These scripts should be:
   - In the target repo (so user can run them)
   - OR downloadable via curl one-liner
   - Currently they're in the toolbox repo itself

**Proposed improvements:**

1. Fix URL to point to correct repo

2. Add version tracking:
   - Use semantic versioning tags (v1.0.0, v1.1.0)
   - Store installed version in `.devcontainer/.version`
   - Script checks current vs latest and shows changelog

3. Add `--check` flag to show what would change without applying

4. Create install one-liner:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
   ```

5. **Script location and self-update**

   Scripts live in **target repo root** for easy access:
   ```
   my-project/
   ├── update-devcontainer.sh    ← Linux/Mac
   ├── update-devcontainer.ps1   ← Windows
   ├── .devcontainer/
   └── .devcontainer.extend/
   ```

   **Why repo root:**
   - Easy to find and run
   - No path to remember (`./update-devcontainer.sh`)
   - Two files (bash + PowerShell) covers all platforms

   **Self-update behavior:**
   The scripts must update themselves when a newer version exists.

   ```bash
   # Pseudocode for update-devcontainer.sh

   1. Download zip from GitHub release
   2. Extract to temp folder
   3. Replace .devcontainer/ with new version
   4. Preserve .devcontainer.extend/ (don't overwrite)
   5. Compare update-devcontainer.sh from zip with current self
      - If different: replace self with new version
      - Same for update-devcontainer.ps1
   6. Show what was updated (version X → Y, scripts updated: yes/no)
   7. Cleanup temp files
   ```

   **Script self-update pattern:**
   ```bash
   # Check if scripts need updating
   NEW_SCRIPT="$EXTRACT_DIR/update-devcontainer.sh"
   CURRENT_SCRIPT="$0"

   if ! diff -q "$NEW_SCRIPT" "$CURRENT_SCRIPT" > /dev/null 2>&1; then
       echo "Updating update-devcontainer.sh..."
       cp "$NEW_SCRIPT" "$CURRENT_SCRIPT"
   fi
   ```

   **Files in zip:**
   ```
   dev_containers.zip
   ├── .devcontainer/
   ├── .devcontainer.extend/
   ├── update-devcontainer.sh
   └── update-devcontainer.ps1
   ```

---

2. .devcontainer.extend and .devcontainer.secrets folders
   - the contant of .devcontainer.extend is standard, but the config files there must be checked in to the repo as it defines what parts of the .devcontainer/additions are used
   - the .devcontainer.secrets stores any secrets that the system needs - must not be checked in to the repo

3. Future: split out the monitoring and tailscale stuff info a separate repo
   - monitoring and services should not be in the devcontainer it should be as a separate container that the devcontainer can communicate with
   - ideas related to this are in /Users/terje.christensen/learn/projects-2025/sovereignsky
