# Fix: Replace git clone with zip download in dev-template

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Fix `dev-template` hanging on fresh machines by replacing `git clone` with `curl` + zip download.

**Last Updated**: 2026-02-19

**GitHub Issue**: #63

**Investigation**: [INVESTIGATE-dev-template-zip-download-fix.md](INVESTIGATE-dev-template-zip-download-fix.md)

**Priority**: High — dev-template is broken on fresh machines

---

## Problem

`dev-template.sh` uses `git clone` to fetch templates. On fresh machines, git's credential helper can hang waiting for auth. All errors are hidden by `2>/dev/null`.

---

## Phase 1: Replace git clone with curl + zip — ✅ DONE

### Tasks

- [x] 1.1 Rename `clone_template_repo()` to `download_templates()` and replace the implementation:

  **Current (line 86):**
  ```bash
  if ! git clone --quiet $TEMPLATE_REPO_URL 2>/dev/null; then
  ```

  **New:**
  ```bash
  TEMPLATE_ZIP_URL="https://github.com/$TEMPLATE_OWNER/$TEMPLATE_REPO_NAME/archive/refs/heads/main.zip"
  ZIP_FILE="$TEMP_DIR/templates.zip"

  if ! curl -fsSL "$TEMPLATE_ZIP_URL" -o "$ZIP_FILE"; then
      echo "❌ Failed to download templates"
      echo ""
      echo "   URL: $TEMPLATE_ZIP_URL"
      echo "   Check your internet connection and try again."
      rm -rf "$TEMP_DIR"
      exit 1
  fi

  if [ ! -s "$ZIP_FILE" ]; then
      echo "❌ Downloaded file is empty"
      rm -rf "$TEMP_DIR"
      exit 1
  fi

  if ! unzip -q "$ZIP_FILE" -d "$TEMP_DIR/"; then
      echo "❌ Failed to extract templates"
      rm -rf "$TEMP_DIR"
      exit 1
  fi
  ```

- [x] 1.2 Update `TEMPLATE_REPO_NAME` references throughout the script. The zip extracts to `urbalurba-dev-templates-main/` (with `-main` suffix). Change the variable after extraction:

  ```bash
  TEMPLATE_REPO_NAME="urbalurba-dev-templates-main"
  ```

  This variable is used in:
  - `scan_templates()` line 147: `"$TEMPLATE_REPO_NAME/templates"/*`
  - `clone_template_repo()` line 92: `"$TEMPLATE_REPO_NAME/templates"`
  - `select_template()` line 281: `"$TEMPLATE_REPO_NAME/templates/$TEMPLATE_NAME"`
  - `copy_template_files()` line 353: `"$TEMPLATE_REPO_NAME/urbalurba-scripts"`

- [x] 1.3 Ensure `unzip` is available — it's pre-installed in the devcontainer base image. Add a check at the top alongside the `dialog` check.

### Validation

```bash
bash .devcontainer/manage/dev-template.sh --help
# Or run dev-template in a devcontainer without gh auth configured — should not hang
```

---

## Phase 2: Improve detect_github_info() error handling — ✅ DONE

### Tasks

- [x] 2.1 Add git repo check before calling `git remote`:

  ```bash
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
      echo "❌ Not inside a git repository"
      echo "   Run this command from the root of your project."
      exit 1
  fi
  ```

- [x] 2.2 Improve error messages with specific causes:
  - No remote: suggest `git remote add origin`
  - Non-GitHub remote: show the URL and explain it needs to be a GitHub URL
  - Can't parse username: show the URL format expected

- [x] 2.3 Print the detected remote URL for debugging:

  ```bash
  echo "   Remote: $GITHUB_REMOTE"
  ```

### Validation

Test with:
- No git repo (should show clear error)
- Git repo with no remote (should show clear error)
- Git repo with GitHub remote (should work)

---

## Acceptance Criteria

- [ ] No `git clone` in the script — uses `curl` + `unzip`
- [ ] Works on fresh machines without git auth configured (verified on fresh Windows devcontainer)
- [ ] Clear error messages on download failure (no hanging, no suppressed errors)
- [ ] `detect_github_info()` gives specific errors for each failure mode
- [ ] Template scanning, menu, selection, and file copying all work as before
- [ ] Existing menu system unchanged (flat list with WEB_SERVER/WEB_APP/OTHER)
- [ ] TEMPLATE_INFO format unchanged (4 fields)
- [ ] Direct selection still works: `dev-template typescript-basic-webserver`

---

## Files to Modify

- `.devcontainer/manage/dev-template.sh` — replace download method and improve error handling
