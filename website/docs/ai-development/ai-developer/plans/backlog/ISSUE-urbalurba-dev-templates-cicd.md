# GitHub Issue for terchris/urbalurba-dev-templates

**Ready to post after confirmation.**

---

## Title

Add CI/CD pipeline to validate templates and publish release zip

## Body

### Problem

The `dev-template` command in [devcontainer-toolbox](https://github.com/terchris/devcontainer-toolbox) currently uses `git clone` to fetch templates. This fails on freshly installed machines where git credential helpers block or prompt for auth (see [devcontainer-toolbox#63](https://github.com/terchris/devcontainer-toolbox/issues/63)).

The fix is to switch to downloading a release zip (like devcontainer-toolbox's `dev-sync` command does), but this repo has no CI/CD pipeline and no releases.

### Requested

Create a GitHub Actions workflow that:

1. **Validates templates on every push/PR:**
   - Every directory in `templates/` has a `TEMPLATE_INFO` file
   - `TEMPLATE_INFO` contains required variables: `TEMPLATE_NAME`, `TEMPLATE_DESCRIPTION`, `TEMPLATE_CATEGORY`
   - Every template has `manifests/deployment.yaml` (required by `dev-template`)
   - No broken file references
   - Optional: lint YAML files, check for placeholder variables

2. **Publishes a release zip on merge to main:**
   - Create a zip containing the `templates/` directory (and `urbalurba-scripts/` if present)
   - Publish as a GitHub release asset (e.g., `templates.zip`)
   - Use a fixed release tag (e.g., `latest`) so the download URL is stable, or use `templates-version.txt` for versioned releases
   - The stable download URL should be: `https://github.com/terchris/urbalurba-dev-templates/releases/download/latest/templates.zip`

### Why

- `dev-template` will switch from `git clone` to `curl` + zip download (no git auth needed)
- Template validation catches errors before they reach users
- Follows the same pattern as devcontainer-toolbox's own release pipeline (`dev_containers.zip`)
- Zip download is faster (no git history) and works in restrictive network environments

### Reference

The devcontainer-toolbox CI/CD pipeline that creates a similar zip:
- Workflow: [zip_dev_setup.yml](https://github.com/terchris/devcontainer-toolbox/blob/main/.github/workflows/zip_dev_setup.yml)
- Consumer: [dev-sync.sh](https://github.com/terchris/devcontainer-toolbox/blob/main/.devcontainer/manage/dev-sync.sh) downloads the zip with `curl -fsSL`
