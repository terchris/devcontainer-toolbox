# GitHub Issue for terchris/urbalurba-dev-templates

**Ready to post after confirmation.**

---

## Title

Add CI/CD pipeline to validate templates, auto-replace placeholders, and publish release zip

## Body

### Problem

The `dev-template` command in [devcontainer-toolbox](https://github.com/terchris/devcontainer-toolbox) copies template files as-is — it does not replace `{{GITHUB_USERNAME}}` or `{{REPO_NAME}}` placeholders. These placeholders appear in Kubernetes manifests and GitHub workflow files across all templates.

Previously `dev-template` required a git repo to detect GitHub info and replace these, but that broke on fresh machines. The new approach is: `dev-template` just copies files, and the templates' own CI/CD handles placeholder replacement on first push.

### Requested

Create GitHub Actions workflows that:

1. **Auto-replace placeholders on first push (all templates):**
   - On push to any branch, check if any files contain `{{GITHUB_USERNAME}}` or `{{REPO_NAME}}`
   - If found, replace with `${{ github.repository_owner }}` and `${{ github.event.repository.name }}`
   - Commit the changes back to the branch
   - This runs once — after replacement, the placeholders are gone and the step becomes a no-op
   - This should be a separate workflow file (e.g., `init-placeholders.yml`) included in every template

2. **Validate templates on every push/PR (this repo only):**
   - Every directory in `templates/` has a `TEMPLATE_INFO` file
   - `TEMPLATE_INFO` contains required variables: `TEMPLATE_NAME`, `TEMPLATE_DESCRIPTION`, `TEMPLATE_CATEGORY`
   - Every template has `manifests/deployment.yaml` (required by `dev-template`)
   - No broken file references
   - Optional: lint YAML files

3. **Publish a release zip on merge to main (this repo only):**
   - Create a zip containing the `templates/` directory (and `urbalurba-scripts/` if present)
   - Publish as a GitHub release asset (e.g., `templates.zip`)
   - Use a fixed release tag (e.g., `latest`) so the download URL is stable
   - Stable download URL: `https://github.com/terchris/urbalurba-dev-templates/releases/download/latest/templates.zip`

### Why

- `dev-template` stays ultra simple — just download, browse, select, copy. No git requirement.
- Placeholder replacement happens automatically when the user pushes their project to GitHub — zero manual steps
- Template validation catches errors before they reach users
- Follows the same pattern as devcontainer-toolbox's own release pipeline

### Placeholder replacement example

The `init-placeholders.yml` workflow included in each template:

```yaml
name: Initialize project
on: push

jobs:
  init:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Replace template placeholders
        run: |
          # Check if any placeholders remain
          if grep -rq '{{GITHUB_USERNAME}}\|{{REPO_NAME}}' . --include='*.yaml' --include='*.yml'; then
            find . -type f \( -name '*.yaml' -o -name '*.yml' \) -exec sed -i \
              -e 's|{{GITHUB_USERNAME}}|${{ github.repository_owner }}|g' \
              -e 's|{{REPO_NAME}}|${{ github.event.repository.name }}|g' {} +
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git add -A
            git commit -m "chore: initialize project placeholders [skip ci]" || true
            git push
          fi
```

### Reference

The devcontainer-toolbox CI/CD pipeline that creates a similar zip:
- Workflow: [zip_dev_setup.yml](https://github.com/terchris/devcontainer-toolbox/blob/main/.github/workflows/zip_dev_setup.yml)
- Consumer: [dev-sync.sh](https://github.com/terchris/devcontainer-toolbox/blob/main/.devcontainer/manage/dev-sync.sh) downloads the zip with `curl -fsSL`
