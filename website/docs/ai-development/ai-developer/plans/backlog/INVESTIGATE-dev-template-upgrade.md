# Investigate: Upgrade dev-template with CI/CD, extended metadata, and documentation

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Done

**Goal**: Investigate how to upgrade the template system with CI/CD validation, extended TEMPLATE_INFO metadata, a category-grouped menu, and Docusaurus documentation pages.

**Last Updated**: 2026-02-19

**GitHub Issue**: #63 (request #2: improved menu), plus broader template system improvement

**Depends on**: The zip download fix (INVESTIGATE-dev-template-zip-download-fix.md) should be done first.

---

## Questions to Answer

1. How can we reuse dev-setup's category menu system for templates?
2. What TEMPLATE_INFO fields are needed to generate documentation pages like tool pages?
3. Should the templates repo have its own CI/CD pipeline?
4. Can the toolbox website display template documentation?

---

## Findings

### 1. Category Menu Reuse

**dev-setup.sh** has a 3-level menu: Main menu → Category menu → Items in category. It uses:
- `categories.sh` — centralized pipe-delimited category table
- `component-scanner.sh` — scans shell scripts for metadata
- Arrays grouped by category (`TOOLS_BY_CATEGORY`, `CATEGORY_COUNTS`)
- `dialog` menus built dynamically from these arrays

**dev-template.sh** currently has a flat 1-level menu with 3 hardcoded categories (`WEB_SERVER`, `WEB_APP`, `OTHER`).

**Reuse approach**: Templates need their own category table (different domain than toolbox categories). The dialog menu patterns from dev-setup can be followed but the scanning is different — templates use TEMPLATE_INFO files instead of shell script metadata, so `component-scanner.sh` itself can't be reused directly. The menu-building pattern (arrays + category grouping + dialog) can be replicated.

### 2. TEMPLATE_INFO Field Design

To generate documentation pages matching the tool page style (e.g., `/docs/tools/development-tools/bash`), templates need extended metadata. Here is the mapping:

**Current TEMPLATE_INFO (4 fields):**

```bash
TEMPLATE_NAME="TypeScript Basic Webserver"
TEMPLATE_DESCRIPTION="Express.js server with TypeScript, health endpoint, and Docker support"
TEMPLATE_CATEGORY="WEB_SERVER"
TEMPLATE_PURPOSE="Provides a minimal starting point for developers..."
```

**Proposed TEMPLATE_INFO (12 fields):**

```bash
TEMPLATE_ID="typescript-basic-webserver"
TEMPLATE_NAME="TypeScript Basic Webserver"
TEMPLATE_CATEGORY="WEB_SERVER"
TEMPLATE_ABSTRACT="Express.js server with TypeScript, health endpoint, and Docker support"
TEMPLATE_SUMMARY="Provides a minimal starting point for building a Node.js web server using Express and TypeScript. Includes Docker support, Kubernetes manifests for ArgoCD, GitHub Actions CI/CD, and a /health endpoint."
TEMPLATE_TAGS="typescript express docker webserver kubernetes argocd"
TEMPLATE_LOGO="typescript-basic-webserver-logo.svg"
TEMPLATE_WEBSITE="https://expressjs.com"
TEMPLATE_INCLUDES="Dockerfile, GitHub Actions workflow, Kubernetes manifests, health endpoint, TypeScript config"
TEMPLATE_PREREQUISITES="dev-typescript"
TEMPLATE_RELATED="golang-basic-webserver python-basic-webserver"
```

**Field changes from current:**

| Current Field | Change | New Field | Reason |
|---|---|---|---|
| — | new | `TEMPLATE_ID` | Unique identifier (= directory name) |
| `TEMPLATE_NAME` | keep | `TEMPLATE_NAME` | Display title |
| `TEMPLATE_DESCRIPTION` | rename | `TEMPLATE_ABSTRACT` | Align with toolbox naming (50-150 chars) |
| — | new | `TEMPLATE_SUMMARY` | Detailed description for overview box (150-500 chars) |
| `TEMPLATE_CATEGORY` | keep | `TEMPLATE_CATEGORY` | Category ID |
| `TEMPLATE_PURPOSE` | merge | — | Absorbed into TEMPLATE_SUMMARY |
| — | new | `TEMPLATE_TAGS` | Search keywords |
| — | new | `TEMPLATE_LOGO` | Logo filename |
| — | new | `TEMPLATE_WEBSITE` | Reference URL |
| — | new | `TEMPLATE_INCLUDES` | What the template ships |
| — | new | `TEMPLATE_PREREQUISITES` | Required toolbox tools |
| — | new | `TEMPLATE_RELATED` | Related template IDs |

### 3. Template Page Layout

A template documentation page (e.g., `/docs/templates/web-servers/typescript-basic-webserver`) would have:

| Page Section | Source Field |
|---|---|
| Header card: logo | `TEMPLATE_LOGO` |
| Header card: title | `TEMPLATE_NAME` |
| Header card: subtitle | `TEMPLATE_ABSTRACT` |
| Header card: tags | `TEMPLATE_TAGS` |
| Overview box | `TEMPLATE_SUMMARY` |
| Quick info: ID, Website | `TEMPLATE_ID`, `TEMPLATE_WEBSITE` |
| What's Included | `TEMPLATE_INCLUDES` |
| Prerequisites | `TEMPLATE_PREREQUISITES` (links to tool pages) |
| Usage | Hardcoded (`dev-template`) |
| Related Templates | `TEMPLATE_RELATED` |

### 4. Templates Repo CI/CD

The templates repo (`terchris/urbalurba-dev-templates`) currently has no CI/CD. Adding a pipeline would:

- **Validate on push/PR**: check TEMPLATE_INFO has required fields, `manifests/deployment.yaml` exists, categories are valid
- **Publish on merge to main**: generate `templates.json` from all TEMPLATE_INFO files, create `templates.zip` as a GitHub release artifact

This gives a stable, validated download URL and a JSON file the toolbox website can consume.

A draft issue for the templates repo is at: `plans/backlog/ISSUE-urbalurba-dev-templates-cicd.md`

### 5. Template Categories

Templates need their own category table (separate from toolbox categories):

| Order | ID | Name | Abstract |
|---|---|---|---|
| 0 | `WEB_SERVER` | Web Servers | Backend web servers and API services |
| 1 | `WEB_APP` | Web Applications | Frontend web applications and SPAs |
| 2 | `MICROSERVICE` | Microservices | Lightweight microservices and functions |
| 3 | `DATA_SERVICE` | Data Services | Data pipelines and processing services |

### 6. Documentation Pipeline Reuse

The toolbox documentation pipeline:
```
install-*.sh → generate-tools-json.sh → tools.json → React components → MDX pages
```

Can be replicated for templates:
```
TEMPLATE_INFO → generate-templates-json.sh → templates.json → React components → MDX pages
```

The toolbox website would download `templates.json` from the templates repo release at build time and render pages using TemplateGrid/TemplateCard components (based on ToolGrid/ToolCard).

---

## Recommendation

This is a multi-phase upgrade spanning two repos. Break into ordered plans:

1. **Templates repo CI/CD** — Extend TEMPLATE_INFO, add validation workflow, add release workflow publishing `templates.zip` + `templates.json`
2. **dev-template.sh upgrade** — Switch from archive URL to release URL, read `templates.json`, build category-grouped menu, prerequisite warnings
3. **Template documentation** — Download `templates.json` at website build time, create TemplateGrid/TemplateCard components, generate template MDX pages

Each plan depends on the previous. Plan 3 is optional and can wait.

---

## Next Steps

- [ ] Do the zip download fix first (separate investigation)
- [ ] Then create ordered plans for this upgrade when ready
