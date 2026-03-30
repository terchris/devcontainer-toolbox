# Fix: dev-template.sh v1.5.0 missing placeholder substitution

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Restore placeholder substitution in `dev-template.sh` so `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}` are replaced in template files, and remove obsolete `urbalurba-scripts/` copy block.

**GitHub Issue**: #67

**Last Updated**: 2026-03-04

**Investigation**: [INVESTIGATE-dev-template-placeholder-substitution.md](../completed/INVESTIGATE-dev-template-placeholder-substitution.md)

---

## Problem

When `dev-template.sh` was moved from `urbalurba-dev-templates` to `devcontainer-toolbox`, the `replace_placeholders()` function was not carried over. Template files are copied with literal `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}`, breaking the entire deploy chain (invalid Kubernetes manifests, silent GitHub Actions failures, ArgoCD sync errors).

Additionally, the script copies an `urbalurba-scripts/` directory that no longer exists on the remote repo (dead code).

---

## Phase 1: Add path resolution and CALLER_DIR — ✅ DONE

Replace fragile `$OLDPWD` usage with explicit directory tracking.

### Tasks

- [ ] 1.1 Add `CALLER_DIR="$PWD"` immediately after `set -e` (line 14)
- [ ] 1.2 Add path resolution block after script metadata (after line 25):
  ```bash
  SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
  DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
  ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"
  ```
- [ ] 1.3 Replace all `$OLDPWD` references with `$CALLER_DIR`:
  - Line 361: `cp -r "$TEMPLATE_PATH/"* "$OLDPWD/"`
  - Line 365: `mkdir -p "$OLDPWD/urbalurba-scripts"` (will be removed in Phase 4, but fix for now)
  - Line 366: `cp -r "$TEMPLATE_REPO_NAME/urbalurba-scripts/"* "$OLDPWD/urbalurba-scripts/"`
  - Line 367: `chmod +x "$OLDPWD/urbalurba-scripts/"*.sh`
  - Line 380: `mkdir -p "$OLDPWD/.github/workflows"`
  - Line 381: `cp -r "$TEMPLATE_PATH/.github"/* "$OLDPWD/.github/"`
  - Line 394-417: All `$OLDPWD` in `merge_gitignore()`
  - Line 468: `cd "$OLDPWD"` → `cd "$CALLER_DIR"`
- [ ] 1.4 Verify no other `$OLDPWD` references remain

### Validation

User confirms all `$OLDPWD` references replaced with `$CALLER_DIR`.

---

## Phase 2: Add repo info detection and validation — ✅ DONE

Source `git-identity.sh` and validate repo info before downloading anything.

### Tasks

- [ ] 2.1 Add source statement after path resolution:
  ```bash
  source "$ADDITIONS_DIR/lib/git-identity.sh"
  ```
- [ ] 2.2 Add `detect_and_validate_repo_info()` function:
  ```bash
  function detect_and_validate_repo_info() {
    echo "🔍 Detecting repository information..."

    detect_git_identity "$CALLER_DIR"

    if [ -z "$GIT_ORG" ]; then
      echo "❌ Error: Could not detect GitHub username/organization"
      echo ""
      echo "   The template needs to know your GitHub username to configure"
      echo "   container image paths and Kubernetes manifests."
      echo ""
      echo "   To fix this, set up a GitHub remote:"
      echo "   git remote add origin https://github.com/YOUR_USERNAME/$(basename "$CALLER_DIR").git"
      exit 1
    fi

    if [ -z "$GIT_REPO" ]; then
      echo "❌ Error: Could not detect repository name"
      echo ""
      echo "   The template needs the repository name to configure"
      echo "   Kubernetes deployment names and labels."
      echo ""
      echo "   To fix this, set up a GitHub remote:"
      echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
      exit 1
    fi

    if [ "$GIT_PROVIDER" != "github" ]; then
      echo "⚠️  Warning: Detected provider '$GIT_PROVIDER' (not GitHub)"
      echo "   Templates use ghcr.io container registry paths which are GitHub-specific."
      echo "   You may need to update image paths in manifests/ after setup."
      echo ""
    fi

    echo "   GitHub user: $GIT_ORG"
    echo "   Repo name:   $GIT_REPO"
    echo "✅ Repository info verified"
    echo ""
  }
  ```
- [ ] 2.3 Add `detect_and_validate_repo_info` call in main flow, after `check_prerequisites` and before `download_templates` (around line 459):
  ```bash
  check_prerequisites
  clear
  display_intro
  detect_and_validate_repo_info    # ← NEW
  download_templates
  ```

### Validation

User confirms: running `dev-template.sh` without a git remote shows a clear error and exits before downloading.

---

## Phase 3: Add placeholder substitution — ✅ DONE

Restore `replace_placeholders()` and call it on manifests and workflows.

### Tasks

- [ ] 3.1 Add `replace_placeholders()` function (before `cleanup_and_complete()`):
  ```bash
  function replace_placeholders() {
    local file=$1
    local temp_file
    temp_file=$(mktemp)

    if [ -f "$file" ]; then
      sed -e "s|{{GITHUB_USERNAME}}|$GIT_ORG|g" \
          -e "s|{{REPO_NAME}}|$GIT_REPO|g" "$file" > "$temp_file"

      if cat "$temp_file" > "$file"; then
        echo "   ✅ Updated $(basename "$file")"
      else
        echo "   ❌ Failed to update $(basename "$file")"
        rm -f "$temp_file"
        return 1
      fi
      rm -f "$temp_file"
    fi
  }
  ```
- [ ] 3.2 Add `process_template_files()` function:
  ```bash
  function process_template_files() {
    echo "🔄 Replacing template placeholders..."
    echo "   Using: $GIT_ORG/$GIT_REPO"

    # Process manifest files
    if [ -d "$CALLER_DIR/manifests" ]; then
      for file in "$CALLER_DIR"/manifests/*.yaml "$CALLER_DIR"/manifests/*.yml; do
        if [ -f "$file" ]; then
          replace_placeholders "$file"
        fi
      done
    fi

    # Process GitHub workflow files
    if [ -d "$CALLER_DIR/.github/workflows" ]; then
      for file in "$CALLER_DIR"/.github/workflows/*.yaml "$CALLER_DIR"/.github/workflows/*.yml; do
        if [ -f "$file" ]; then
          replace_placeholders "$file"
        fi
      done
    fi

    echo "✅ Placeholders replaced"
    echo ""
  }
  ```
- [ ] 3.3 Add `process_template_files` call in main flow, after `merge_gitignore` and before `cd "$CALLER_DIR"`:
  ```bash
  merge_gitignore
  process_template_files    # ← NEW
  cd "$CALLER_DIR"
  cleanup_and_complete
  ```

### Validation

User confirms: after running `dev-template.sh`, `manifests/deployment.yaml` contains actual repo name and GitHub username instead of `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}`.

---

## Phase 4: Remove dead code and bump version — ✅ DONE

### Tasks

- [ ] 4.1 Remove `urbalurba-scripts/` copy block from `copy_template_files()` (lines 363-369):
  ```bash
  # DELETE THIS BLOCK:
  if [ -d "$TEMPLATE_REPO_NAME/urbalurba-scripts" ]; then
    echo "   Setting up urbalurba-scripts..."
    mkdir -p "$CALLER_DIR/urbalurba-scripts"
    cp -r "$TEMPLATE_REPO_NAME/urbalurba-scripts/"* "$CALLER_DIR/urbalurba-scripts/"
    chmod +x "$CALLER_DIR/urbalurba-scripts/"*.sh 2>/dev/null || true
    echo "   ✅ Added urbalurba-scripts"
  fi
  ```
- [ ] 4.2 Bump `SCRIPT_VERSION` from `1.5.0` to `1.6.0` (lines 12 and 24)
- [ ] 4.3 Verify the complete script flow works end-to-end

### Validation

User confirms script version is 1.6.0 and no `urbalurba-scripts/` block remains.

---

## Acceptance Criteria

- [ ] Script detects `GIT_ORG` and `GIT_REPO` from git remote before downloading templates
- [ ] Script aborts with clear error if repo info is missing
- [ ] Script warns (but continues) for non-GitHub providers
- [ ] `{{REPO_NAME}}` replaced in `manifests/*.yaml` and `.github/workflows/*.yaml`
- [ ] `{{GITHUB_USERNAME}}` replaced in `manifests/*.yaml` and `.github/workflows/*.yaml`
- [ ] GitHub Actions `${{ }}` context variables are NOT affected by substitution
- [ ] `urbalurba-scripts/` copy block removed
- [ ] All `$OLDPWD` references replaced with `$CALLER_DIR`
- [ ] Script version bumped to 1.6.0
- [ ] No shellcheck warnings

---

## Files to Modify

- `.devcontainer/manage/dev-template.sh` — all changes are in this single file
