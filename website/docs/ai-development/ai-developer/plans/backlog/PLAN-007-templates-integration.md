# Feature: Templates Integration

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Draft (Definition Incomplete)

**Goal**: Merge project templates from urbalurba-dev-templates into DevContainer Toolbox, allowing users to start projects with pre-configured templates.

**Last Updated**: 2026-01-17

**Prerequisites**:
- PLAN-003 complete (extended metadata)
- PLAN-004 complete (tool display components)

**Priority**: Future (larger scope)

---

## Overview

Currently, `dev-template.sh` downloads templates from [urbalurba-dev-templates](https://github.com/terchris/urbalurba-dev-templates). This plan merges templates into devcontainer-toolbox so the website covers both **Tools** AND **Templates/Starters**.

### Website Structure After Implementation

```
DevContainer Toolbox
├── Tools (current)
│   ├── Languages (Python, TypeScript, Go...)
│   ├── Cloud & Infrastructure
│   └── AI & ML
│
└── Templates (new)
    ├── Frontend (React, Next.js, Vue...)
    ├── Backend (Express, FastAPI, Spring...)
    └── Full Stack (Next.js + API, etc.)
```

---

## Definition Tasks (To Complete Before Implementation)

- [ ] Review urbalurba-dev-templates repo structure
- [ ] Decide on template metadata format (TEMPLATE_* fields)
- [ ] Decide where templates live in the repo (`templates/` folder?)
- [ ] Decide how `dev-template.sh` will work after merge
- [ ] Design template cards for website (reuse ToolCard or create TemplateCard?)
- [ ] Plan template documentation pages

---

## Proposed Scope (Needs Review)

### Template Metadata Format

```bash
# --- Core metadata (required) ---
TEMPLATE_ID="nextjs-starter"
TEMPLATE_VER="1.0.0"
TEMPLATE_NAME="Next.js Starter"
TEMPLATE_DESCRIPTION="Next.js 14 with TypeScript, Tailwind, and ESLint"
TEMPLATE_CATEGORY="FRONTEND"

# --- Extended metadata (for website) ---
TEMPLATE_LOGO="nextjs-logo.svg"
TEMPLATE_WEBSITE="https://nextjs.org"
TEMPLATE_TAGS="react nextjs typescript tailwind frontend"
TEMPLATE_ABSTRACT="Production-ready Next.js 14 starter with App Router..."
TEMPLATE_RELATED="react-starter vite-starter"

# --- Template-specific fields ---
TEMPLATE_TOOLS="dev-typescript"           # Required tools to install
TEMPLATE_REPO="https://github.com/..."    # Source repo (if external)
TEMPLATE_DEMO="https://demo.example.com"  # Live demo URL (optional)
```

### Shared Metadata Fields (Tools & Templates)

| Field | Purpose |
|-------|---------|
| `*_ID` | Unique identifier |
| `*_VER` | Version number |
| `*_NAME` | Display name |
| `*_DESCRIPTION` | Short description (1 line) |
| `*_CATEGORY` | Category for grouping |
| `*_LOGO` | Icon/logo filename |
| `*_WEBSITE` | Official website URL |
| `*_TAGS` | Search keywords |
| `*_ABSTRACT` | Longer description (2-3 sentences) |
| `*_RELATED` | Related item IDs |

---

## Proposed Phases (Draft)

### Phase 1: Planning & Design
- Review urbalurba-dev-templates
- Finalize metadata format
- Design website integration

### Phase 2: Template Migration
- Create `templates/` folder
- Migrate templates with new metadata
- Update `dev-template.sh`

### Phase 3: Website Integration
- Create `dev-templates.sh` to generate `templates.json`
- Create TemplateCard component (or reuse ToolCard)
- Add templates section to homepage
- Create template documentation pages

### Phase 4: Testing & Documentation
- Test template creation workflow
- Update user documentation
- Update contributor docs

---

## Acceptance Criteria (Draft)

- [ ] Templates merged into devcontainer-toolbox repo
- [ ] Template metadata format defined and documented
- [ ] Website displays templates alongside tools
- [ ] `dev-template.sh` works with merged templates
- [ ] Template documentation pages generated

---

## Files to Create (Estimated)

- `templates/` - Template folder (merged from external repo)
- `.devcontainer/manage/dev-templates.sh` - Generate templates.json
- `website/src/components/TemplateCard/` - Or reuse ToolCard
- `website/src/data/templates.json` - Template data
- `website/docs/templates/` - Template documentation

## Files to Modify (Estimated)

- `.devcontainer/manage/dev-template.sh` - Update for merged templates
- `website/src/pages/index.tsx` - Add templates section
- `website/docusaurus.config.ts` - Add templates to navbar

---

## Open Questions

1. Should templates live in this repo or remain separate?
2. How do templates relate to tools? (e.g., Next.js template requires TypeScript tools)
3. Should we show "recommended tools" for each template?
4. What categories do we need for templates?
5. How does this affect the homepage layout?

---

## Reference

- [urbalurba-dev-templates](https://github.com/terchris/urbalurba-dev-templates)
- INVESTIGATE-docusaurus-enhancements.md - "Future Scope: Templates Integration" section
