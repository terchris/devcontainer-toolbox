# Investigate: dev-template.sh v1.5.0 missing placeholder substitution

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Determine the best approach to restore placeholder substitution in `dev-template.sh` and remove the obsolete `urbalurba-scripts/` copy block.

**GitHub Issue**: #67

**Last Updated**: 2026-03-04

---

## Questions to Answer

1. Where exactly in the current `dev-template.sh` (v1.5.0) should `replace_placeholders()` be restored?
2. Which files need substitution after the `ingress.yaml` removal?
3. Are there any other placeholders beyond `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}`?
4. Where is the `urbalurba-scripts/` copy block and what exactly does it copy?
5. Are there any downstream effects of removing the `urbalurba-scripts/` copy?

---

## Current State

When `dev-template.sh` was moved from `urbalurba-dev-templates` to `devcontainer-toolbox`, the `replace_placeholders()` function was not carried over. The current v1.5.0 copies template files as-is without substituting `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}`.

### Impact — entire deploy chain is broken

Without substitution, three things fail in sequence:

1. `manifests/deployment.yaml` contains literal `{{REPO_NAME}}-deployment` — not a valid Kubernetes resource name
2. GitHub Actions workflow sed pattern doesn't match the un-substituted placeholders — silently does nothing
3. ArgoCD cannot sync because the manifests contain invalid YAML values

### What the old version had

The v1.1.0 script had a `replace_placeholders()` function (lines 540-562) that ran `sed` substitution on `{{GITHUB_USERNAME}}` and `{{REPO_NAME}}` across `manifests/*.yaml` and `.github/workflows/*.yaml`.

---

## Fix 1: Restore placeholder substitution

Restore the `replace_placeholders()` function from v1.1.0 into `dev-template.sh`. Call it on `manifests/*.yaml` after `copy_template_files()` completes.

**Files that need substitution:**

- `manifests/deployment.yaml` — 8 × `{{REPO_NAME}}`, 2 × `{{GITHUB_USERNAME}}`
- `manifests/kustomization.yaml` — 2 × `{{REPO_NAME}}`, 2 × `{{GITHUB_USERNAME}}`
- `.github/workflows/urbalurba-build-and-push.yaml` — no fix needed (uses GitHub context variables)

## Fix 2: Remove `urbalurba-scripts/` copy block

The `copy_template_files()` function copies the `urbalurba-scripts/` directory into new projects. This directory contains obsolete registration scripts (`register-argocd.sh`, `remove-argocd.sh`, `check-deployment.sh`, etc.) that predate the `uis` CLI.

All functionality is now handled by `uis argocd register/remove/list/verify`. The copy block should be removed.

---

## Investigation Tasks

- [x] Read current `dev-template.sh` to understand the structure and find `copy_template_files()`
- [x] Locate the `urbalurba-scripts/` copy block
- [x] Check the old v1.1.0 `replace_placeholders()` function in `urbalurba-dev-templates`
- [x] Verify which placeholders exist in the template files
- [x] Determine if any other scripts depend on `urbalurba-scripts/` being present
- [x] Assess whether this is a simple restore or needs redesign

---

## Investigation Findings

### Q1: Where should `replace_placeholders()` be restored?

The current script flow in `dev-template.sh` (v1.5.0) is:

```
check_prerequisites → download_templates → scan_templates → select_template
→ verify_template → copy_template_files → setup_github_workflows → merge_gitignore
→ cd $OLDPWD → cleanup_and_complete
```

The substitution must happen **after** `copy_template_files()` and `setup_github_workflows()` copy files into `$OLDPWD`, but **before** `cleanup_and_complete()`. A new `replace_placeholders()` function + a `process_essential_files()` caller should be added between `merge_gitignore` and `cd "$OLDPWD"` (around line 467).

**Critical missing piece:** The current v1.5.0 script has no code to extract `GITHUB_USERNAME` and `REPO_NAME` from the git remote.

**Existing library:** `.devcontainer/additions/lib/git-identity.sh` already provides:
- `parse_git_remote_url()` — parses GitHub (HTTPS+SSH), Azure DevOps, and generic remotes
- `detect_git_identity()` — full detection with fallbacks, exports `GIT_ORG` and `GIT_REPO`

The script should `source lib/git-identity.sh` and call `detect_git_identity` — no need to write custom detection.

**Validation must happen early** — before downloading templates. The script should:
1. Source `git-identity.sh` and call `detect_git_identity`
2. Validate that `GIT_ORG` is not empty (needed for `ghcr.io/{{GITHUB_USERNAME}}/...`)
3. Validate that `GIT_REPO` is not empty
4. Abort with a clear error if either is missing, explaining what the user needs to do (e.g., `git remote add origin ...`)
5. Only then proceed to `download_templates`

Updated flow:
```
check_prerequisites → detect_and_validate_repo_info → download_templates → scan_templates
→ select_template → verify_template → copy_template_files → setup_github_workflows
→ merge_gitignore → replace_placeholders → cd $OLDPWD → cleanup_and_complete
```

**Edge cases where `GIT_ORG` would be empty:**
- No git repo initialized (`git init` not run)
- No remote configured (`git remote add origin` not run)
- Non-GitHub/Azure DevOps remote (generic fallback sets `GIT_ORG=""`)

All of these should produce a clear error message before any template work begins.

### Q2: Which files need substitution?

Confirmed from ALL 7 template source directories:

- **`manifests/deployment.yaml`** — all 7 templates: `{{REPO_NAME}}`, `{{GITHUB_USERNAME}}`
- **`manifests/kustomization.yaml`** — all 7 templates: `{{REPO_NAME}}`, `{{GITHUB_USERNAME}}`
- **`.github/workflows/urbalurba-build-and-push.yaml`** — 4 of 7 templates (csharp, golang, java, php) contain `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}` placeholders

**Correction from initial analysis:** The issue stated workflows don't need substitution. This is **wrong for 4 templates**. The substitution must run on both `manifests/*.yaml` AND `.github/workflows/*.yaml`.

No `ingress.yaml` files exist in any template (already removed).

### Q3: Any other placeholders?

**No custom template placeholders** beyond `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}`. The `${{ ... }}` patterns in workflow files (e.g., `${{ github.repository }}`, `${{ secrets.GITHUB_TOKEN }}`) are GitHub Actions context variables — these must NOT be touched by the sed substitution. The `{{` vs `${{` distinction is important.

### Q4: Where is the `urbalurba-scripts/` copy block?

Lines 363-369 of the current `dev-template.sh`:

```bash
if [ -d "$TEMPLATE_REPO_NAME/urbalurba-scripts" ]; then
    echo "   Setting up urbalurba-scripts..."
    mkdir -p "$OLDPWD/urbalurba-scripts"
    cp -r "$TEMPLATE_REPO_NAME/urbalurba-scripts/"* "$OLDPWD/urbalurba-scripts/"
    chmod +x "$OLDPWD/urbalurba-scripts/"*.sh 2>/dev/null || true
    echo "   ✅ Added urbalurba-scripts"
fi
```

### Q5: Any downstream effects of removing `urbalurba-scripts/`?

**None.** The `urbalurba-scripts/` directory no longer exists on the remote `urbalurba-dev-templates` repo (confirmed via GitHub API — returns 404). The copy block is already dead code. Removing it is safe.

### Q6: Simple restore or redesign?

**Simple restore with several improvements.** The fix requires:

1. Add path resolution (`SCRIPT_DIR`, `ADDITIONS_DIR`) — same pattern as `dev-setup.sh` and `dev-help.sh`
2. Source existing `lib/git-identity.sh` and call `detect_git_identity` early (before downloading)
3. Validate `GIT_ORG` and `GIT_REPO` are not empty — abort with clear error if missing
4. Replace `$OLDPWD` usage with explicit `CALLER_DIR="$PWD"` captured at script start
5. Add `replace_placeholders()` function using `$GIT_ORG` and `$GIT_REPO` (adapted from v1.1.0)
6. Add `process_essential_files()` to call it on `manifests/*.yaml` AND `.github/workflows/*.yaml`
7. Remove the `urbalurba-scripts/` copy block (lines 363-369)
8. Bump `SCRIPT_VERSION` to 1.6.0

Reuses existing `git-identity.sh` library rather than duplicating detection logic.

---

## Gaps Found During Validation

### Gap 1: Workflow files need substitution too

The issue and initial analysis stated `.github/workflows/*.yaml` don't need substitution. **This is wrong.** 4 of 7 templates (csharp, golang, java, php) have `{{REPO_NAME}}` and `{{GITHUB_USERNAME}}` in their workflow files. Must substitute both `manifests/*.yaml` and `.github/workflows/*.yaml`.

**Important:** The sed pattern `{{REPO_NAME}}` must NOT match `${{ github.repository }}` or other GitHub Actions context variables. The existing sed from v1.1.0 uses exact match (`s|{{GITHUB_USERNAME}}|...|g`) which is safe — `${{` won't match `{{`.

### Gap 2: `$OLDPWD` is fragile

The script uses `$OLDPWD` throughout (lines 361, 365-367, 380-381, 394-408) to write files back to the user's project. This relies on `cd "$TEMP_DIR"` being the only `cd` in the script. But `detect_git_identity()` also does `cd /workspace` internally, which would corrupt `$OLDPWD`.

**Fix:** Capture `CALLER_DIR="$PWD"` at script start and replace all `$OLDPWD` references with `$CALLER_DIR`.

### Gap 3: No path resolution for sourcing libraries

`dev-template.sh` has no `SCRIPT_DIR`/`ADDITIONS_DIR` path calculation. It cannot source `git-identity.sh` without this. Other manage/ scripts (`dev-help.sh`, `dev-setup.sh`) already have this pattern:

```bash
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
ADDITIONS_DIR="$DEVCONTAINER_DIR/additions"
```

### Gap 4: `detect_git_identity()` changes working directory

The function does `cd "$workspace_dir"` (defaults to `/workspace`). If called after `cd "$TEMP_DIR"`, it changes the cwd back. If called before, it sets cwd to `/workspace`, and then `cd "$TEMP_DIR"` overwrites it. Using `CALLER_DIR` instead of `$OLDPWD` eliminates this fragility regardless of call order.

### Gap 5: Non-GitHub providers

Templates use `ghcr.io/{{GITHUB_USERNAME}}/{{REPO_NAME}}` — this is GitHub Container Registry. If `GIT_PROVIDER` is `azure-devops`, `GIT_ORG` maps to an Azure DevOps org, not a GitHub username. The image path would be technically wrong. For now, the templates are GitHub-only, so the validation should check `GIT_PROVIDER == "github"` and warn (but not block) for other providers.

---

## Recommendation

Create a single PLAN file with four phases:

- **Phase 1:** Add path resolution and `CALLER_DIR` — replace all `$OLDPWD` usage, add `SCRIPT_DIR`/`ADDITIONS_DIR` calculation
- **Phase 2:** Add repo info detection and validation — source `git-identity.sh`, call `detect_git_identity`, validate `GIT_ORG`/`GIT_REPO` before downloading templates
- **Phase 3:** Add `replace_placeholders()` + `process_essential_files()` — substitute both `manifests/*.yaml` and `.github/workflows/*.yaml`
- **Phase 4:** Remove `urbalurba-scripts/` copy block + bump version to 1.6.0

---

## Next Steps

- [ ] Create PLAN-dev-template-placeholder-fix.md with the approach above
