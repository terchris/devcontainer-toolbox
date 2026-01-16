# Feature: Configurable Repository URLs

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal:** Make the documentation site work on any fork without manual URL changes.

**Last Updated:** 2026-01-16

**Source:** [INVESTIGATE-docusaurus-enhancements.md](../backlog/INVESTIGATE-docusaurus-enhancements.md)

---

**Prerequisites:** None (this is the foundation)
**Blocks:** All other website enhancement plans depend on this
**Priority:** Critical

**CI/CD Note:** All phases can be validated locally with `npm run build`. Push and merge to main **once after Phase 4** to run the full CI/CD pipeline. The pipeline takes 15+ minutes, so avoid multiple pushes.

---

## Problem

The site currently has hardcoded URLs pointing to `terchris/devcontainer-toolbox`. This causes issues:

1. Contributors forking the repo get broken links
2. GitHub Pages deploys to wrong URL on forks
3. "Edit this page" links point to wrong repository
4. Manual changes required for each fork

**Files with hardcoded URLs:**
- `website/docusaurus.config.ts` - url, baseUrl, organizationName, editUrl, navbar/footer links
- `README.md` - documentation site links
- Various `.md` files - GitHub links

---

## Solution

Use environment variables with sensible defaults. GitHub Actions automatically passes repository context, and local development uses the defaults.

---

## Phase 1: Update Docusaurus Config — ✅ DONE

### Tasks

- [x] 1.1 Add environment variable reading at top of `docusaurus.config.ts` ✓
- [x] 1.2 Replace hardcoded values in config (url, baseUrl, organizationName, projectName) ✓
- [x] 1.3 Update `editUrl` to use variables ✓
- [x] 1.4 Update navbar GitHub link ✓
- [x] 1.5 Update footer links to use variables ✓

### Validation

Run `npm run build` in website folder - should complete without errors.

User confirms config changes look correct.

---

## Phase 2: Update GitHub Actions — ✅ DONE

### Tasks

- [x] 2.1 Update `.github/workflows/deploy-docs.yml` to pass environment variables ✓
- [x] 2.2 Verify the workflow file syntax is valid ✓

### Validation

Workflow updated with GITHUB_ORG and GITHUB_REPO env vars.

---

## Phase 3: Convert Markdown Links — ✅ DONE

### Tasks

- [x] 3.1 Audit markdown files for hardcoded GitHub URLs ✓
- [x] 3.2 Convert to relative links where possible (internal docs) ✓
- [x] 3.3 Document intentional main repo references ✓

### Findings

Audited all markdown files. Hardcoded URLs found are **intentional**:
- Support links (Issues, Discussions) → should point to main repo
- CLAUDE.md references → point to actual file in repo root
- Historical/completed plans → documentation of past work

No changes needed - these correctly reference the main repository.

---

## Phase 4: Documentation — ✅ DONE

### Tasks

- [x] 4.1 Update `website/README.md` with Fork Compatibility section ✓
- [x] 4.2 Comment in `docusaurus.config.ts` explaining the env var pattern ✓ (added in Phase 1)

### Validation

Documentation added to README and config file.

---

## Phase 5: Push, Merge, and Verify CI/CD — IN PROGRESS

### Tasks

- [x] 5.1 Create feature branch and commit all changes ✓
- [x] 5.2 Create PR to main ✓ (PR #16)
- [ ] 5.3 Merge PR (triggers CI/CD pipeline)
- [ ] 5.4 Monitor GitHub Actions workflow
- [ ] 5.5 Verify deployed site works correctly

### Validation

- GitHub Actions workflow completes successfully
- Deployed site loads at correct URL
- "Edit this page" links point to correct repository
- User confirms deployment is working

---

## Acceptance Criteria

- [ ] Site builds successfully with default values (local dev)
- [ ] Site builds successfully with custom env vars
- [ ] GitHub Actions workflow passes env vars correctly
- [ ] No hardcoded `terchris/devcontainer-toolbox` in docusaurus.config.ts
- [ ] Documentation explains the env var pattern
- [ ] Forking the repo results in working GitHub Pages deployment

---

## Files to Modify

- `website/docusaurus.config.ts`
- `.github/workflows/deploy-docs.yml`
- `website/README.md` (create or update)
- Various `website/docs/*.md` files (audit for hardcoded URLs)

---

## Implementation Notes

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GITHUB_ORG` | `terchris` | GitHub organization/username |
| `GITHUB_REPO` | `devcontainer-toolbox` | Repository name |

### Local Development

No changes needed - defaults work automatically:
```bash
cd website
npm start
# Uses terchris/devcontainer-toolbox defaults
```

### Testing with Custom Values

```bash
GITHUB_ORG=myorg GITHUB_REPO=myrepo npm run build
```

### GitHub Actions Context Variables

| GitHub Context | Value |
|----------------|-------|
| `github.repository_owner` | Organization or username |
| `github.event.repository.name` | Repository name |

### Future: Custom Domain

A custom domain is planned for later. When implemented:
- `url` will change to the custom domain (e.g., `https://devcontainer-toolbox.dev`)
- `baseUrl` can become `/` (no repo name prefix needed)
- Environment variables can be extended: `CUSTOM_DOMAIN`

For now, we use GitHub Pages default URLs (`username.github.io/repo-name`).
