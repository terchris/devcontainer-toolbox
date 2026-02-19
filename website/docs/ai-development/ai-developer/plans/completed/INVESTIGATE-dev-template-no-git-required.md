# Investigate: Make dev-template work without a git repo

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Done

**Goal**: Determine how to make `dev-template` work on a fresh machine without requiring a git repo or login.

**Last Updated**: 2026-02-19

**GitHub Issue**: #63 (follow-up — the zip download fix was merged but git repo is still required)

---

## Questions to Answer

1. Where is git repo / GitHub info actually needed?
2. Can we remove git entirely?
3. How do `{{GITHUB_USERNAME}}` and `{{REPO_NAME}}` placeholders get filled in?

---

## Findings

### 1. Where GitHub info is used in dev-template

`detect_github_info()` sets `GITHUB_USERNAME` and `REPO_NAME` by reading the git remote URL. These are **only** used in `replace_placeholders()` which does sed replacement on manifest and workflow YAML files.

**Everything else** — download, scan, menu, select, copy, merge .gitignore — does **not** need GitHub info.

### 2. Where placeholders appear in templates

Searched all 7 templates. `{{GITHUB_USERNAME}}` and `{{REPO_NAME}}` appear in:
- `manifests/deployment.yaml` — deployment name, image reference, owner label
- `manifests/ingress.yaml` — hostname, annotations
- `manifests/kustomization.yaml` — image references
- `.github/workflows/urbalurba-build-and-push.yaml` — some references

Not all templates need these — some templates may not have Kubernetes manifests at all.

### 3. Who should replace the placeholders?

**Option A: dev-template replaces them (current approach)**
- Requires git repo detection or user prompts
- Adds complexity to a tool that should be simple
- Fails on fresh machines

**Option B: GitHub Actions replaces them on first push (recommended)**
- Each template includes an `init-placeholders.yml` workflow
- On first push, the workflow checks for `{{GITHUB_USERNAME}}`/`{{REPO_NAME}}`
- If found, replaces with `${{ github.repository_owner }}`/`${{ github.event.repository.name }}` and commits
- After first run, placeholders are gone — the step becomes a no-op
- Zero effort for the user
- `dev-template` stays ultra simple

### 4. Simplified dev-template flow

```
Current:                          Proposed:
detect_github_info  ← REMOVE      download_templates
download_templates                 scan_templates
scan_templates                     select_template
select_template                    verify_template
verify_template                    copy_template_files
copy_template_files                setup_github_workflows
setup_github_workflows             merge_gitignore
merge_gitignore                    cleanup_and_complete
process_essential_files ← REMOVE
cleanup_and_complete
```

---

## Recommendation

1. **Remove all git code from dev-template** — delete `detect_github_info()`, `replace_placeholders()`, and `process_essential_files()`. The script becomes: download → browse → select → copy.

2. **Add placeholder replacement to the templates repo** — each template gets an `init-placeholders.yml` GitHub Actions workflow that auto-replaces `{{GITHUB_USERNAME}}`/`{{REPO_NAME}}` on first push. This is tracked in the draft issue: [ISSUE-urbalurba-dev-templates-cicd.md](../backlog/ISSUE-urbalurba-dev-templates-cicd.md).

---

## Next Steps

- [x] Create PLAN-dev-template-no-git-required.md
- [x] Update ISSUE-urbalurba-dev-templates-cicd.md with placeholder replacement workflow
