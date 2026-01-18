# Feature: Extended Script and Category Metadata

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal:** Add extended metadata fields to scripts and categories (logo, website, tags, abstract, summary, related) and update all existing tools and categories.

**Last Updated:** 2026-01-16

**Source:** [INVESTIGATE-docusaurus-enhancements.md](./INVESTIGATE-docusaurus-enhancements.md)

---

**Prerequisites:** None (can run parallel to other plans)
**Blocks:** PLAN-004 (Enhanced Tool Pages), PLAN-005 (Interactive Homepage)
**Related:** Config refactor plan (needed so contributors can install dev-imagetools locally without committing to .conf files)
**Priority:** High (foundation for tool pages and homepage)

**CI/CD Note:** All changes can be validated locally with tests. Push once after all phases complete.

---

## Overview

This plan adds extended metadata fields to enable richer tool documentation and better website display.

**Important:** Extended metadata is for the **website only**, not for `dev-setup.sh`. The terminal-based installer uses only the existing core metadata (NAME, DESCRIPTION, CATEGORY). Logos and extended descriptions are stored in the website folder and are not included in projects that use devcontainer-toolbox.

### Existing Metadata Fields (required)

These fields already exist in all scripts:

| Field | Purpose | Example |
|-------|---------|---------|
| `SCRIPT_ID` | Unique identifier | `dev-python` |
| `SCRIPT_VER` | Version number | `1.0.0` |
| `SCRIPT_NAME` | Display name | `Python Development Tools` |
| `SCRIPT_DESCRIPTION` | Short one-line description | `Adds ipython, pytest-cov, and VS Code extensions` |
| `SCRIPT_CATEGORY` | Category for grouping | `LANGUAGE_DEV` |
| `SCRIPT_CHECK_COMMAND` | Command to verify installation | `command -v ipython >/dev/null 2>&1` |

### Script Type (auto-detected)

Script type is automatically detected from the filename prefix:

| Prefix | Type | Description |
|--------|------|-------------|
| `install-*.sh` | `install` | Installs tools and packages |
| `config-*.sh` | `config` | Configures settings |
| `service-*.sh` | `service` | Background services and daemons |

**Website use cases for type:**
- Filter by type (show all services, show all config scripts)
- Display different icons/badges per type
- Group tools by type in listings
- Show type-specific information (e.g., "This is a background service")

### New Extended Metadata Fields

| Field | Required | Purpose | Length | Example |
|-------|----------|---------|--------|---------|
| `SCRIPT_LOGO` | No | Icon filename | - | `python-logo.svg` |
| `SCRIPT_WEBSITE` | No | Official tool URL | - | `https://python.org` |
| `SCRIPT_TAGS` | Yes | Search keywords | - | `"python pip venv ipython"` |
| `SCRIPT_ABSTRACT` | Yes | Brief description | 50-150 chars | `"Full Python development environment with pip, venv, and VS Code extensions."` |
| `SCRIPT_SUMMARY` | No | Detailed description | 150-500 chars | `"Complete Python development setup including virtual environment management..."` |
| `SCRIPT_RELATED` | No | Related tool IDs | - | `"dev-data-analytics dev-ai"` |

### Category Metadata

Categories are defined in `.devcontainer/additions/lib/categories.sh` using a pipe-delimited table.

**Existing Category Fields (to be renamed):**

| Current Field | New Field | Purpose |
|---------------|-----------|---------|
| `SORT_ORDER` | `CATEGORY_ORDER` | Display order (number) |
| `CATEGORY_ID` | `CATEGORY_ID` | Identifier (unchanged) |
| `DISPLAY_NAME` | `CATEGORY_NAME` | Human-readable name |
| `SHORT_DESCRIPTION` | `CATEGORY_ABSTRACT` | Brief description (50-150 chars) |
| `LONG_DESCRIPTION` | `CATEGORY_SUMMARY` | Detailed description (150-500 chars) |

**New Category Fields:**

| Field | Required | Purpose | Example |
|-------|----------|---------|---------|
| `CATEGORY_TAGS` | Yes | Search keywords | `"programming languages code development"` |
| `CATEGORY_LOGO` | No | Logo filename | `language-dev-logo.svg` |

**New table format:**
```
CATEGORY_ORDER|CATEGORY_ID|CATEGORY_NAME|CATEGORY_ABSTRACT|CATEGORY_SUMMARY|CATEGORY_TAGS|CATEGORY_LOGO
```

**Current categories (8 total):**
1. `SYSTEM_COMMANDS` - DevContainer management commands
2. `LANGUAGE_DEV` - Development Tools
3. `AI_TOOLS` - AI & Machine Learning Tools
4. `CLOUD_TOOLS` - Cloud & Infrastructure Tools
5. `DATA_ANALYTICS` - Data & Analytics Tools
6. `BACKGROUND_SERVICES` - Background Services & Daemons
7. `INFRA_CONFIG` - Infrastructure & Configuration
8. `CONTRIBUTOR_TOOLS` - Contributor Tools

---

## Phase 1: Define and Document Extended Metadata — ✅ DONE

### Tasks

**Script metadata:**
- [x] 1.1 Update `website/docs/ai-developer/CREATING-SCRIPTS.md` with new metadata fields
- [x] 1.2 Update `website/docs/contributors/scripts/install-scripts.md` with new fields
- [x] 1.3 Update script template files in `.devcontainer/additions/`:
  - `_template-install-script.sh`
  - `_template-config-script.sh`
  - `_template-service-script.sh`
  - `_template-cmd-script.sh`

**Category metadata:**
- [x] 1.4 Update `.devcontainer/additions/lib/categories.sh`:
  - Renamed fields to new naming convention
  - Added CATEGORY_TAGS and CATEGORY_LOGO columns to table
  - Updated helper functions to use new field names
  - Added backward compatibility aliases
  - Updated field number references in `_get_category_field()`

### Validation

Documentation updated. Template files have all new fields. Category helper functions work correctly with backward compatibility.

---

## Phase 2: Enrich All Tools with Extended Metadata — ✅ DONE

All scripts and categories have been enriched with extended metadata fields (TAGS, ABSTRACT, LOGO, WEBSITE, SUMMARY, RELATED).

### Install Scripts (23 total) — ✅ Complete

All install scripts updated with extended metadata:

**Language Development (11 scripts):**
- [x] `install-dev-python.sh` - Python development tools
- [x] `install-dev-typescript.sh` - TypeScript development tools
- [x] `install-dev-golang.sh` - Go development tools
- [x] `install-dev-rust.sh` - Rust development tools
- [x] `install-dev-csharp.sh` - C#/.NET development tools
- [x] `install-dev-java.sh` - Java development tools
- [x] `install-dev-bash.sh` - Bash development tools
- [x] `install-dev-cpp.sh` - C/C++ development tools
- [x] `install-dev-fortran.sh` - Fortran development tools
- [x] `install-dev-php-laravel.sh` - PHP Laravel development tools
- [x] `install-dev-ai-claudecode.sh` - Claude Code AI assistant

**Cloud & Infrastructure (6 scripts):**
- [x] `install-tool-azure-dev.sh` - Azure application development
- [x] `install-tool-azure-ops.sh` - Azure operations tools
- [x] `install-tool-kubernetes.sh` - Kubernetes tools
- [x] `install-tool-iac.sh` - Infrastructure as Code tools
- [x] `install-tool-okta.sh` - Okta identity tools
- [x] `install-tool-powerplatform.sh` - Power Platform tools

**Data & Analytics (2 scripts):**
- [x] `install-tool-dataanalytics.sh` - Data analytics tools
- [x] `install-tool-databricks.sh` - Databricks tools

**Utilities (2 scripts):**
- [x] `install-tool-api-dev.sh` - API development tools
- [x] `install-tool-dev-utils.sh` - Development utilities

**Background Services (2 scripts):**
- [x] `install-srv-nginx.sh` - Nginx reverse proxy
- [x] `install-srv-otel-monitoring.sh` - OpenTelemetry monitoring

### Config Scripts (6 total) — ✅ Complete

All config scripts updated with extended metadata:
- [x] `config-ai-claudecode.sh` - Claude Code configuration
- [x] `config-devcontainer-identity.sh` - Developer identity
- [x] `config-nginx.sh` - Nginx proxy configuration
- [x] `config-supervisor.sh` - Supervisor configuration
- [x] `config-git.sh` - Git identity configuration
- [x] `config-host-info.sh` - Host information

### Categories (8 total) — ✅ Complete (in Phase 1)

Categories were updated in Phase 1 when modifying `categories.sh`:
- [x] `SYSTEM_COMMANDS` - DevContainer management commands
- [x] `LANGUAGE_DEV` - Development Tools
- [x] `AI_TOOLS` - AI & Machine Learning Tools
- [x] `CLOUD_TOOLS` - Cloud & Infrastructure Tools
- [x] `DATA_ANALYTICS` - Data & Analytics Tools
- [x] `BACKGROUND_SERVICES` - Background Services & Daemons
- [x] `INFRA_CONFIG` - Infrastructure & Configuration
- [x] `CONTRIBUTOR_TOOLS` - Contributor Tools

### Validation

- [x] All scripts have TAGS and ABSTRACT (required fields)
- [x] All scripts have optional fields (LOGO, WEBSITE, SUMMARY, RELATED) set
- [x] All categories have TAGS, ABSTRACT, SUMMARY, and LOGO in categories.sh
- [ ] Source logos to be added to `website/static/img/tools/src/` (Phase 5)
- [ ] Source logos to be added to `website/static/img/categories/src/` (Phase 5)

---

## Phase 3: Update dev-docs.sh to Read New Fields — ✅ DONE

### Tasks

**Script metadata:**
- [x] 3.1 Update `.devcontainer/manage/dev-docs.sh` to extract new script metadata fields
  - Added `extract_script_field()` and `extract_extended_metadata()` functions
- [x] 3.2 Detect script type from filename prefix:
  - Added `detect_script_type()` function
  - `install-*.sh` → `"type": "install"`
  - `config-*.sh` → `"type": "config"`
  - `service-*.sh` or `install-srv-*.sh` → `"type": "service"`
- [x] 3.3 Add new fields to markdown output (tools/index.md, tools-details.md)
  - JSON data available for React components to enhance pages
- [x] 3.4 Generate `website/src/data/tools.json` for React components:
  - Added `generate_tools_json()` function
  - Added `json_escape()` and `to_json_array()` helper functions
  - JSON includes: id, type, name, description, category, tags, abstract, logo, website, summary, related

**Category metadata:**
- [x] 3.5 Update `dev-docs.sh` to read category metadata from `categories.sh`
  - Uses existing helper functions: `get_category_name()`, `get_category_order()`, etc.
- [x] 3.6 Generate `website/src/data/categories.json` for React components:
  - Added `generate_categories_json()` function
  - JSON includes: id, name, order, tags, abstract, summary, logo

### Validation

```bash
docker exec <container> bash -c "cd /workspace && .devcontainer/manage/dev-docs.sh"
```

Verify:
- [x] New helper functions added to extract extended metadata
- [x] `tools.json` generation function implemented
- [x] `categories.json` generation function implemented
- [x] Help text updated to show new output files
- [ ] Test by running `dev-docs` (Phase 6)

---

## Phase 4: Add Static Test Validation — ✅ DONE

### Tasks

- [x] 4.1 Create new test file `test-extended-metadata.sh` for script extended fields:
  - Created `.devcontainer/additions/tests/static/test-extended-metadata.sh`
  - Validates SCRIPT_TAGS (required)
  - Validates SCRIPT_ABSTRACT (required, 50-150 chars)
  - Validates SCRIPT_WEBSITE (optional, must start with https://)
  - Validates SCRIPT_SUMMARY (optional, 150-500 chars)
  - Validates SCRIPT_RELATED (optional, checks IDs exist)

- [x] 4.2 Update `test-categories.sh` to validate new category fields:
  - Added `test_category_metadata()` - validates all required category fields
  - Added `test_category_backward_compat()` - verifies alias functions work
  - Tests: CATEGORY_NAME, CATEGORY_ABSTRACT, CATEGORY_SUMMARY, CATEGORY_TAGS, CATEGORY_ORDER

- [x] 4.3 Create new test file `test-generated-json.sh` for JSON output:
  - Created `.devcontainer/additions/tests/static/test-generated-json.sh`
  - Validates tools.json exists and is valid JSON
  - Validates tools.json has required fields (id, type, name, category, tags, abstract)
  - Validates categories.json exists and is valid JSON
  - Validates categories.json has required fields (id, name, order, tags, abstract, summary)
  - Supports `--generate` flag to regenerate JSON before testing

- [x] 4.4 Tests automatically included in CI via `run-all-tests.sh static`
  - Test orchestrator auto-discovers all `test-*.sh` files in static/ directory

### Validation

```bash
# Run all static tests
docker exec <container> bash -c "cd /workspace && .devcontainer/additions/tests/run-all-tests.sh static"

# Run specific test
docker exec <container> bash -c "cd /workspace && .devcontainer/additions/tests/static/test-extended-metadata.sh"
```

Tests catch:
- Missing required fields (TAGS, ABSTRACT)
- Invalid field formats (wrong length, bad URL)
- Invalid SCRIPT_RELATED references
- Broken JSON generation
- Category metadata issues

---

## Phase 5: Find and Download Logos — ✅ DONE

AI task: Search the internet for official logos and download them to the source directories.

All logos downloaded from official sources, Simple Icons, or created using Heroicons.

### Tool Logos (29 total) — ✅ Complete

**Language Development (10 logos):**
- [x] 5.1 `dev-python-logo.svg` - Python logo (python.org)
- [x] 5.2 `dev-typescript-logo.svg` - TypeScript logo (Simple Icons)
- [x] 5.3 `dev-golang-logo.svg` - Go logo (Simple Icons)
- [x] 5.4 `dev-rust-logo.svg` - Rust logo (rust-lang.org)
- [x] 5.5 `dev-csharp-logo.svg` - .NET logo (Simple Icons)
- [x] 5.6 `dev-java-logo.svg` - OpenJDK logo (Simple Icons)
- [x] 5.7 `dev-bash-logo.svg` - Bash logo (Simple Icons)
- [x] 5.8 `dev-cpp-logo.svg` - C++ logo (Simple Icons)
- [x] 5.9 `dev-fortran-logo.svg` - Fortran logo (Simple Icons)
- [x] 5.10 `dev-php-laravel-logo.svg` - Laravel logo (Simple Icons)

**AI Tools (1 logo):**
- [x] 5.11 `dev-ai-claudecode-logo.svg` - Claude logo (Wikimedia Commons)

**Cloud & Infrastructure (6 logos):**
- [x] 5.12 `tool-azure-dev-logo.svg` - Azure logo
- [x] 5.13 `tool-azure-ops-logo.svg` - Azure logo (copy)
- [x] 5.14 `tool-kubernetes-logo.svg` - Kubernetes logo (CNCF artwork)
- [x] 5.15 `tool-iac-logo.svg` - Terraform logo (Simple Icons)
- [x] 5.16 `tool-okta-logo.svg` - Okta logo (okta.com)
- [x] 5.17 `tool-powerplatform-logo.svg` - Power Platform placeholder

**Data & Analytics (2 logos):**
- [x] 5.18 `tool-dataanalytics-logo.svg` - Jupyter logo (jupyter.org)
- [x] 5.19 `tool-databricks-logo.svg` - Databricks logo (Simple Icons)

**Utilities (2 logos):**
- [x] 5.20 `tool-api-dev-logo.svg` - Postman/API icon (Simple Icons)
- [x] 5.21 `tool-dev-utils-logo.svg` - Docker icon (Simple Icons)

**Services (2 logos):**
- [x] 5.22 `srv-nginx-logo.svg` - Nginx logo (Simple Icons)
- [x] 5.23 `srv-otel-monitoring-logo.svg` - OpenTelemetry logo (Simple Icons)

**Config Scripts (6 logos):**
- [x] 5.24 `config-ai-claudecode-logo.svg` - Claude logo (copy)
- [x] 5.25 `config-nginx-logo.svg` - Nginx logo (copy)
- [x] 5.26 `config-supervisor-logo.svg` - Process icon (Heroicons)
- [x] 5.27 `config-git-logo.svg` - Git logo (git-scm.com)
- [x] 5.28 `config-devcontainer-identity-logo.svg` - User icon (Heroicons)
- [x] 5.29 `config-host-info-logo.svg` - Computer icon (Heroicons)

### Category Logos (8 total) — ✅ Complete

All category logos created using Heroicons (MIT license):
- [x] 5.30 `system-commands-logo.svg` - Terminal icon
- [x] 5.31 `language-dev-logo.svg` - Code icon
- [x] 5.32 `ai-tools-logo.svg` - Sparkles icon
- [x] 5.33 `cloud-tools-logo.svg` - Cloud icon
- [x] 5.34 `data-analytics-logo.svg` - Chart icon
- [x] 5.35 `background-services-logo.svg` - Server icon
- [x] 5.36 `infra-config-logo.svg` - Cog icon
- [x] 5.37 `contributor-tools-logo.svg` - Wrench icon

### Logo Sources Used

- **Simple Icons** (simpleicons.org) - Most tech brand SVGs
- **CNCF Artwork** (github.com/cncf/artwork) - Kubernetes
- **Heroicons** (heroicons.com) - Generic UI icons, all category logos
- **Official websites** - Python, Rust, Git, Jupyter, Okta
- **Wikimedia Commons** - Claude AI logo

### Reference Document

Created `website/static/img/LOGO-SOURCES.md` with full source attribution.

### Validation

- [x] All 29 tool logos exist in `website/static/img/tools/src/`
- [x] All 8 category logos exist in `website/static/img/categories/src/`
- [x] All files are valid SVG format

---

## Phase 6: Logo Processing Setup — ✅ DONE

Logo processing runs in GitHub Actions during deployment. Contributors can optionally install image tools locally for testing.

### Tasks

- [x] 6.1 Create new install script `install-dev-imagetools.sh`:
  - Installs ImageMagick, librsvg2-bin, webp tools
  - Category: CONTRIBUTOR_TOOLS
  - Standard metadata format with extended fields

- [x] 6.2 Create directory structure:
  - `website/static/img/tools/src/` - Source tool logos (31 SVG files)
  - `website/static/img/tools/` - Processed logos (gitignored)
  - `website/static/img/categories/src/` - Source category logos (8 SVG files)
  - `website/static/img/categories/` - Processed logos (gitignored)

- [x] 6.3 Create logo processing script `.devcontainer/manage/dev-logos.sh`:
  ```bash
  #!/bin/bash
  # Process all logos in src/ folders
  # - Resize to 512x512 pixels (centered, transparent padding)
  # - Convert to WebP format

  # Process tool logos
  mkdir -p website/static/img/tools
  for img in website/static/img/tools/src/*; do
    [ -f "$img" ] || continue
    filename=$(basename "$img" | sed 's/\.[^.]*$//')
    convert "$img" -resize 512x512 -background transparent -gravity center -extent 512x512 \
      "website/static/img/tools/${filename}.webp"
  done

  # Process category logos
  mkdir -p website/static/img/categories
  for img in website/static/img/categories/src/*; do
    [ -f "$img" ] || continue
    filename=$(basename "$img" | sed 's/\.[^.]*$//')
    convert "$img" -resize 512x512 -background transparent -gravity center -extent 512x512 \
      "website/static/img/categories/${filename}.webp"
  done
  ```

- [x] 6.4 Update `.github/workflows/deploy-docs.yml` to process logos:
  - Added ImageMagick, librsvg2-bin, webp installation step
  - Added `dev-logos.sh` processing step before build
  - Added path trigger for `dev-logos.sh` changes

- [x] 6.5 Add processed logo folders to `website/.gitignore`:
  - `/static/img/tools/*.webp`
  - `/static/img/categories/*.webp`

- [x] 6.6 Verify source logos exist for tools (31 SVG files)

- [x] 6.7 Verify source logos exist for categories (8 SVG files)

### Validation

**Local testing (after installing dev-imagetools):**
```bash
dev-logos  # or bash .devcontainer/manage/dev-logos.sh
cd website && npm run build
```

**CI validation:**
After GitHub Actions runs, verify on deployed site:
- Tool logos display correctly
- Category logos display correctly
- All logos are 512x512 WebP

---

## Phase 7: Regenerate Documentation and Test — ✅ DONE

### Tasks

- [x] 7.1 Run `dev-docs.sh` to regenerate all documentation
- [x] 7.2 Run full build to verify no broken links
- [x] 7.3 Logo processing verified (31 tool logos, 8 category logos)
- [x] 7.4 Verify `tools.json` contains all expected data (277 lines)
- [x] 7.5 Verify `categories.json` contains all expected data (76 lines)
- [x] 7.6 All 27 static tests pass

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

## Phase 8: Commit and Deploy — IN PROGRESS

### Tasks

- [x] 8.1 Commit all changes (a36806f - 90 files, 3950 insertions)
- [ ] 8.2 Push branch and create PR
- [ ] 8.3 Verify deployed site
- [ ] 8.4 Verify using Chrome on published site

### Validation

Verify on localhost before pushing:
- http://localhost:3000/devcontainer-toolbox/docs/tools-details#bash-development-tools
- Check: abstract, website, summary, tags, related, installation details

All features work on live site. Verify in Chrome.

---

## Acceptance Criteria

**Scripts:**
- [ ] All scripts have required extended metadata (TAGS, ABSTRACT)
- [ ] All scripts have optional fields where applicable (LOGO, WEBSITE, SUMMARY, RELATED)
- [ ] Tool logo files exist in `website/static/img/tools/src/` for scripts that have SCRIPT_LOGO

**Categories:**
- [ ] All categories have required metadata (TAGS)
- [ ] All categories have updated field names (NAME, ABSTRACT, SUMMARY)
- [ ] Category logo files exist in `website/static/img/categories/src/` for categories that have CATEGORY_LOGO
- [ ] Category helper functions work with new field names

**Tooling:**
- [ ] `dev-docs.sh` generates `tools.json` for React components
- [ ] `dev-docs.sh` generates `categories.json` for React components
- [ ] Static tests validate required fields and format of optional fields
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

**Category library:**
- `.devcontainer/additions/lib/categories.sh` (rename fields, add TAGS and LOGO)

**Tooling:**
- `.devcontainer/manage/dev-docs.sh`

**Tests (new and updated):**
- `.devcontainer/additions/tests/static/test-extended-metadata.sh` (new)
- `.devcontainer/additions/tests/static/test-categories.sh` (update for new fields)
- `.devcontainer/additions/tests/static/test-generated-json.sh` (new)

**New install script:**
- `.devcontainer/additions/install-dev-imagetools.sh` (optional, for local testing)

**Assets:**
- `website/static/img/tools/src/` (source tool logos - committed)
- `website/static/img/tools/` (processed tool logos - gitignored, generated at build)
- `website/static/img/categories/src/` (source category logos - committed)
- `website/static/img/categories/` (processed category logos - gitignored, generated at build)

**Manage scripts:**
- `.devcontainer/manage/dev-logos.sh` (ImageMagick-based processing)

**GitHub Actions:**
- `.github/workflows/deploy-docs.yml` (add logo processing step)
- `.github/workflows/` (add static tests to PR workflow)

**Data output:**
- `website/src/data/tools.json` (generated)
- `website/src/data/categories.json` (generated)

**All scripts:**
- All `install-*.sh`, `config-*.sh`, `service-*.sh` in `.devcontainer/additions/`

---

## Implementation Notes

### Logo Requirements

**For contributors (source logos):**
- Drop any image in `website/static/img/tools/src/`
- Accepted formats: SVG, PNG, WebP, JPG, GIF
- Any size (will be auto-resized)
- Filename: `<script-id>-logo.<ext>` (e.g., `dev-python-logo.png`)

**Automatic processing (in GitHub Actions):**
- Runs during website deployment (not locally)
- Uses ImageMagick `convert` command
- Resized to 512x512 pixels (centered, transparent padding)
- Converted to WebP format
- Output to `website/static/img/tools/` (gitignored)
- Referenced in scripts as `SCRIPT_LOGO="<script-id>-logo.webp"`

**Where to find logos:**
- Official tool/language websites (usually have press kits)
- [Simple Icons](https://simpleicons.org/) - Tech brand SVGs
- [Devicon](https://devicon.dev/) - Programming language icons
- [Heroicons](https://heroicons.com/) - Generic icons

### SCRIPT_ABSTRACT Guidelines

- Should be 1-2 sentences (50-150 characters)
- Brief description of what the tool provides
- Used in tool cards and listings
- Example: `"Full Python development environment with pip, venv, and VS Code extensions."`

### SCRIPT_SUMMARY Guidelines

- Should be 3-5 sentences (150-500 characters)
- Detailed description covering:
  - What features are included
  - Key use cases
  - Benefits and why you'd use it
- Used on tool detail pages
- Example: `"Complete Python development setup including virtual environment management, package installation via pip, and VS Code integration. Adds ipython for interactive development, pytest for testing, and common development utilities. Ideal for backend development, scripting, and data science projects."`

### SCRIPT_RELATED Guidelines

- Space-separated list of script IDs (without .sh extension)
- Only reference existing scripts
- Focus on complementary tools
- Example: Python relates to data-analytics, ai-claude-code

### Category Metadata Guidelines

**CATEGORY_TAGS:**
- Space-separated keywords for search
- Should cover what types of tools belong in the category
- Example: `"programming languages code development ide"`

**CATEGORY_ABSTRACT:**
- 1-2 sentences (50-150 characters)
- Brief description of what the category contains
- Example: `"Programming language development environments and tools."`

**CATEGORY_SUMMARY:**
- 3-5 sentences (150-500 characters)
- Detailed description of the category
- Example: `"Complete development setups for various programming languages including Python, TypeScript, Go, Rust, .NET, and Bash. Each tool provides language-specific tooling, VS Code extensions, and common development utilities."`

**CATEGORY_LOGO:**
- Filename in `website/static/img/categories/src/`
- Naming: `<category-id-lowercase>-logo.<ext>` (e.g., `language-dev-logo.svg`)
- Will be processed to 512x512 WebP

### Backward Compatibility

During the transition period:
- Required fields (TAGS, ABSTRACT) should warn first, then fail after Phase 5
- Optional fields (LOGO, WEBSITE, SUMMARY, RELATED) never fail, only validate format if present
