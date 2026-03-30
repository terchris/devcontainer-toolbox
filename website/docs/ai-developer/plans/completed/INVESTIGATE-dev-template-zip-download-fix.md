# Investigate: Fix dev-template by replacing git clone with zip download

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Done

**Goal**: Fix `dev-template` hanging on fresh machines by replacing `git clone` with a zip download.

**Last Updated**: 2026-02-19

**GitHub Issue**: #63

---

## Questions to Answer

1. Why does the script hang?
2. What is the minimal fix?
3. Can we do this without changes to the templates repo?

---

## Root Cause

`dev-template.sh` line 86 uses `git clone` to fetch templates:

```bash
if ! git clone --quiet $TEMPLATE_REPO_URL 2>/dev/null; then
```

On a fresh machine, git's credential helper can prompt for HTTPS auth. With `2>/dev/null` suppressing all output and no `GIT_TERMINAL_PROMPT=0`, the script hangs silently. The user sees the last printed message ("Detecting GitHub repository information...") and nothing else — the hang is actually in the next function (`clone_template_repo`).

---

## Current State

### How dev-template fetches templates today

```bash
TEMPLATE_REPO_URL="https://github.com/terchris/urbalurba-dev-templates"
git clone --quiet $TEMPLATE_REPO_URL 2>/dev/null
```

This clones the entire repo (including git history) into a temp directory, then scans `templates/*/TEMPLATE_INFO` for the menu.

### How dev-sync fetches updates (the pattern to follow)

```bash
curl -fsSL "https://github.com/$REPO/releases/download/latest/dev_containers.zip" -o "$ZIP_FILE"
unzip -q "$ZIP_FILE" -d "$TEMP_DIR/"
```

No git auth needed. Fast. Works everywhere.

### GitHub archive URLs

GitHub provides zip archives for any public repo without authentication:

```
https://github.com/terchris/urbalurba-dev-templates/archive/refs/heads/main.zip
```

This requires **no changes** to the templates repo — no CI/CD, no releases. The URL works for any public repo.

When unzipped, the directory is named `urbalurba-dev-templates-main/` (repo name + branch).

---

## Scope: What changes and what stays

| Aspect | Change? | Notes |
|--------|---------|-------|
| Download method | **YES** | `git clone` → `curl` + `unzip` |
| Template scanning | **Minor** | Adjust directory name (`-main` suffix) |
| TEMPLATE_INFO format | **NO** | Keep current 4 fields |
| Menu system | **NO** | Keep current flat dialog menu |
| Category grouping | **NO** | Keep hardcoded WEB_SERVER/WEB_APP/OTHER |
| Error handling | **YES** | Show download errors, don't suppress |
| `detect_github_info()` | **YES** | Add git repo check, better error messages |

---

## Error Handling Improvements (included in fix)

| Location | Current | Fixed |
|----------|---------|-------|
| `detect_github_info()` | No git repo check | Check `git rev-parse --git-dir` first |
| `detect_github_info()` | One error for all failures | Separate messages for no-repo, no-remote, non-GitHub |
| `clone_template_repo()` | `2>/dev/null` hides errors | Show curl error output |
| `clone_template_repo()` | No hang protection | `curl` never prompts for credentials |
| `clone_template_repo()` | No download verification | Check zip exists and is not empty |

---

## Recommendation

Replace `git clone` with `curl` using GitHub's archive URL. This is a minimal, focused fix:

- **No changes needed in the templates repo** (no CI/CD, no releases)
- **No changes to TEMPLATE_INFO format** (keep current 4 fields)
- **No changes to the menu system** (keep current flat menu)
- Better error handling as a bonus

The only code changes are in `clone_template_repo()` and `detect_github_info()` in `.devcontainer/manage/dev-template.sh`.

---

## Next Steps

- [ ] Create PLAN-dev-template-zip-fix.md with the fix
