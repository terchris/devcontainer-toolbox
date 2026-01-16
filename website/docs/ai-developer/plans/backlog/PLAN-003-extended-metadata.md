# Feature: Extended Script Metadata

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal:** Add extended metadata fields to scripts (logo, website, tags, abstract, related) and update all existing tools.

**Last Updated:** 2026-01-16

**Source:** [INVESTIGATE-docusaurus-enhancements.md](INVESTIGATE-docusaurus-enhancements.md)

---

**Prerequisites:** None (can run parallel to other plans)
**Blocks:** PLAN-004 (Enhanced Tool Pages), PLAN-005 (Interactive Homepage)
**Priority:** High (foundation for tool pages and homepage)

**CI/CD Note:** All changes can be validated locally with tests. Push once after all phases complete.

---

## Overview

Currently scripts have basic metadata (ID, VER, NAME, DESCRIPTION, CATEGORY, CHECK_COMMAND). This plan adds extended fields to enable richer tool documentation and better website display.

**New metadata fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| `SCRIPT_LOGO` | Icon filename | `python-logo.svg` |
| `SCRIPT_WEBSITE` | Official tool URL | `https://python.org` |
| `SCRIPT_TAGS` | Search keywords | `"python pip venv"` |
| `SCRIPT_ABSTRACT` | Longer description (2-3 sentences) | For tool detail pages |
| `SCRIPT_RELATED` | Related tool IDs | `"dev-data-analytics dev-ai"` |

---

## Phase 1: Define and Document Extended Metadata

### Tasks

- [ ] 1.1 Update `website/docs/ai-developer/CREATING-SCRIPTS.md` with new metadata fields
- [ ] 1.2 Update `website/docs/contributors/scripts/install-scripts.md` with new fields
- [ ] 1.3 Update script template files in `.devcontainer/additions/`:
  - `_template-install.sh`
  - `_template-config.sh`
  - `_template-service.sh`

### Validation

Review documentation is clear and complete. Template files have all new fields.

---

## Phase 2: Update dev-docs.sh to Read New Fields

### Tasks

- [ ] 2.1 Update `.devcontainer/manage/dev-docs.sh` to extract new metadata fields
- [ ] 2.2 Add new fields to markdown output (tools/index.md, tools-details.md)
- [ ] 2.3 Generate `website/src/data/tools.json` for React components:
  ```json
  {
    "tools": [
      {
        "id": "dev-python",
        "name": "Python Development",
        "description": "...",
        "category": "LANGUAGE_DEV",
        "logo": "python-logo.svg",
        "website": "https://python.org",
        "tags": ["python", "pip", "venv"],
        "abstract": "...",
        "related": ["dev-data-analytics", "dev-ai"]
      }
    ]
  }
  ```

### Validation

```bash
docker exec <container> bash -c "cd /workspace && .devcontainer/manage/dev-docs.sh"
```

Verify:
- New fields appear in markdown output
- `tools.json` is generated with all fields

---

## Phase 3: Add Static Test Validation

### Tasks

- [ ] 3.1 Update `.devcontainer/additions/tests/` to validate new metadata fields
- [ ] 3.2 Add validation rules:
  - SCRIPT_LOGO: warn if file doesn't exist in `website/static/img/tools/`
  - SCRIPT_WEBSITE: validate URL format
  - SCRIPT_TAGS: must be quoted space-separated list
  - SCRIPT_ABSTRACT: must be quoted, 50-300 characters
  - SCRIPT_RELATED: validate references existing tool IDs
- [ ] 3.3 Make validation warn (not fail) for missing extended fields during transition

### Validation

```bash
docker exec <container> bash -c "cd /workspace && .devcontainer/additions/tests/run-all-tests.sh static"
```

Tests should pass with warnings for scripts missing extended metadata.

---

## Phase 4: Create Logo Directory and Download Logos

### Tasks

- [ ] 4.1 Create `website/static/img/tools/` directory
- [ ] 4.2 Download/create SVG logos for all tools:
  - Languages: python, typescript, go, rust, dotnet
  - Cloud: azure, terraform, kubernetes
  - Data: postgresql, analytics
  - AI: claude (or generic AI icon)
  - Config/services: generic icons as needed
- [ ] 4.3 Use consistent sizing (64x64 or similar)
- [ ] 4.4 Prefer SVG for scalability; PNG acceptable if SVG unavailable

### Validation

All logo files exist and display correctly when opened in browser.

---

## Phase 5: Update All Existing Scripts

### Tasks

Update ALL scripts with extended metadata. Scripts to update:

**Install scripts (install-*.sh):**
- [ ] 5.1 install-ai-claude-code.sh
- [ ] 5.2 install-cloud-azure.sh
- [ ] 5.3 install-cloud-terraform.sh
- [ ] 5.4 install-data-analytics.sh
- [ ] 5.5 install-data-postgresql.sh
- [ ] 5.6 install-dev-bash.sh
- [ ] 5.7 install-dev-dotnet.sh
- [ ] 5.8 install-dev-go.sh
- [ ] 5.9 install-dev-python.sh
- [ ] 5.10 install-dev-rust.sh
- [ ] 5.11 install-dev-typescript.sh
- [ ] 5.12 install-kubernetes.sh

**Config scripts (config-*.sh):**
- [ ] 5.13 config-git-safe-directory.sh
- [ ] 5.14 config-git-trust-workspace.sh
- [ ] 5.15 config-zsh-aliases.sh

**Service scripts (service-*.sh):**
- [ ] 5.16 service-litellm.sh
- [ ] 5.17 service-openwebui.sh

For each script add:
```bash
# --- Extended metadata (for website) ---
SCRIPT_LOGO="<tool>-logo.svg"
SCRIPT_WEBSITE="https://<official-website>"
SCRIPT_TAGS="<keyword1> <keyword2> <keyword3>"
SCRIPT_ABSTRACT="<2-3 sentence description of what this tool provides and why you'd use it>"
SCRIPT_RELATED="<related-tool-id-1> <related-tool-id-2>"
```

### Validation

```bash
docker exec <container> bash -c "cd /workspace && .devcontainer/additions/tests/run-all-tests.sh static"
```

All scripts should pass validation without warnings.

---

## Phase 6: Regenerate Documentation and Test

### Tasks

- [ ] 6.1 Run `dev-docs.sh` to regenerate all documentation
- [ ] 6.2 Run full build to verify no broken links
- [ ] 6.3 Start dev server and verify tool pages show correctly
- [ ] 6.4 Verify `tools.json` contains all expected data

### Validation

```bash
docker exec <container> bash -c "cd /workspace && .devcontainer/manage/dev-docs.sh"
docker exec <container> bash -c "cd /workspace/website && npm run build"
```

User verifies in Chrome (localhost or deployed):
- Tool pages have correct content
- No broken images
- tools.json is accessible

---

## Phase 7: Commit and Deploy

### Tasks

- [ ] 7.1 Commit all changes
- [ ] 7.2 Create PR and merge
- [ ] 7.3 Verify deployed site
- [ ] 7.4 Verify using Chrome on published site

### Validation

All features work on live site. Verify in Chrome.

---

## Acceptance Criteria

- [ ] All scripts have extended metadata (LOGO, WEBSITE, TAGS, ABSTRACT, RELATED)
- [ ] All logo files exist in `website/static/img/tools/`
- [ ] `dev-docs.sh` generates `tools.json` for React components
- [ ] Static tests validate new metadata fields
- [ ] Documentation updated with new field specifications
- [ ] Build passes without errors
- [ ] Site verified in Chrome browser

---

## Files to Modify

**Documentation:**
- `website/docs/ai-developer/CREATING-SCRIPTS.md`
- `website/docs/contributors/scripts/install-scripts.md`

**Templates:**
- `.devcontainer/additions/_template-install.sh`
- `.devcontainer/additions/_template-config.sh`
- `.devcontainer/additions/_template-service.sh`

**Tooling:**
- `.devcontainer/manage/dev-docs.sh`
- `.devcontainer/additions/tests/` (validation tests)

**Assets:**
- `website/static/img/tools/` (new folder with logos)

**Data output:**
- `website/src/data/tools.json` (generated)

**All scripts:**
- All `install-*.sh`, `config-*.sh`, `service-*.sh` in `.devcontainer/additions/`

---

## Implementation Notes

### Logo Sources

Free SVG logos can be found at:
- [Simple Icons](https://simpleicons.org/) - Tech brand icons
- [Devicon](https://devicon.dev/) - Programming language icons
- [Heroicons](https://heroicons.com/) - Generic icons

### SCRIPT_ABSTRACT Guidelines

- Should be 2-3 sentences
- Describe what the tool provides
- Explain why someone would use it
- Example: "Full Python development environment with pip, venv, and VS Code extensions. Includes ipython for interactive development and pytest for testing."

### SCRIPT_RELATED Guidelines

- Space-separated list of script IDs (without .sh extension)
- Only reference existing scripts
- Focus on complementary tools
- Example: Python relates to data-analytics, ai-claude-code

### Backward Compatibility

Extended metadata fields are optional during transition. Tests should:
- Warn for missing fields (not fail)
- After all scripts updated, can make fields required
