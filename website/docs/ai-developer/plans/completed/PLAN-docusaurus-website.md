# Plan: Docusaurus Documentation Website

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed ✅

**Goal:** Create a professional, engaging documentation website using Docusaurus to attract developers to devcontainer-toolbox.

**Last Updated:** 2026-01-16

**Priority:** High

---

## Context

- Current docs in `/docs` are plain Markdown
- Want professional "product" feel to sell the idea to developers
- Each tool should have its own detailed page
- AI can auto-generate tool pages when new tools are created
- Site should build automatically on push via GitHub Actions
- **All development runs inside the devcontainer** (Node.js already available)

---

## Phase 1: Docusaurus Setup — ✅ DONE

**Goal:** Initialize Docusaurus in `/website` folder with basic config.

- [x] Create `/website` folder structure
- [x] Initialize Docusaurus project (use npx, not global install)
- [x] Configure `docusaurus.config.ts`:
  - Site title, tagline, URL
  - GitHub repo link
  - Theme colors matching project identity
- [x] Configure `sidebars.ts` for auto-generated sidebar
- [x] Add `.gitignore` entries for node_modules, build output
- [x] Update `HomepageFeatures` component with project-relevant content
- [x] Create placeholder docs (index.md, getting-started.md, tools.md, commands.md)
- [x] Test dev server works

**Starting the dev server** (run inside VS Code terminal connected to devcontainer):
```bash
cd /workspace/website
npm run start -- --host 0.0.0.0
```

The `--host 0.0.0.0` flag is **required** for VS Code port forwarding to work. Without it, the server only binds to localhost inside the container and won't be accessible from the host.

**Other useful commands:**
```bash
npm run build    # Production build
npm run serve    # Serve production build locally
```

**Validation:**
- [x] `npm run start -- --host 0.0.0.0` opens local preview at localhost:3000/devcontainer-toolbox/
- [x] `npm run build` completes without errors
- [x] No broken links or missing images

---

## Phase 2: Landing Page — ✅ DONE

**Goal:** Create an engaging home page that sells the project.

- [x] Design hero section:
  - Headline: "DevContainer Toolbox"
  - Subheadline: "One command. Full dev environment. Any project."
  - CTA buttons: "Get Started", "View on GitHub"
- [x] Add features section (3 key benefits):
  - Works Everywhere (Windows, Mac, Linux)
  - 20+ Tools Ready
  - AI-Ready Development
- [x] Add the AI demo GIF (teaser) with link to full docs
- [x] Add quick install code block (Mac/Linux and Windows PowerShell)

**Components created:**
- `src/components/QuickInstall/` - Install command code blocks
- `src/components/AiDemo/` - AI demo GIF section

**Validation:**
- [x] Landing page looks professional
- [x] CTAs link to correct pages

---

## Phase 3: Migrate Core Docs — ✅ DONE

**Goal:** Move existing documentation into Docusaurus structure.

- [x] Create docs structure:
  ```
  website/docs/
  ├── index.md                  (1) - Home/Quick Start
  ├── what-are-devcontainers.md (2) - Educational intro
  ├── getting-started.md        (3) - Full install guide
  ├── commands.md               (4) - Command reference
  ├── configuration.md          (5) - Config files
  ├── troubleshooting.md        (6) - Common issues
  └── tools/
      └── index.md              (7) - Tools overview
  ```
- [x] Create `what-are-devcontainers.md` - educational content:
  - What is a container? (simple explanation)
  - What is a devcontainer? (VS Code integration)
  - Why use devcontainers? (benefits for teams)
  - How it works (diagram: your code + container = consistent env)
  - Common misconceptions
  - Links to VS Code docs and tutorials
- [x] Copy and adapt existing content from `/docs`:
  - Added frontmatter (title, sidebar_position)
  - Removed manual back links (Docusaurus handles navigation)
  - Updated internal links to use Docusaurus format
- [x] Set up sidebar categories (auto-generated from folder structure)

**Validation:**
- [x] All core docs render correctly
- [x] Navigation works
- [x] No broken links

---

## Phase 4: Update Doc Generation Scripts — ✅ DONE

**Goal:** Update `dev-docs.sh` to write to `website/docs/`.

- [x] Update `.devcontainer/manage/dev-docs.sh`:
  - Changed `OUTPUT_FILE` to `website/docs/tools/index.md`
  - Changed `OUTPUT_FILE_DETAILS` to `website/docs/tools-details.md`
  - Changed `OUTPUT_FILE_COMMANDS` to `website/docs/commands.md`
  - Added Docusaurus frontmatter (sidebar_position, sidebar_label)
  - Added Docusaurus admonitions for "auto-generated" notices
- [x] Update CI workflow to check `website/docs/`
- [x] Delete old `/docs` root-level files (kept docs/contributors/ and docs/ai-developer/)
- [x] Test `dev-docs` generates to correct location
- [x] Update all path references:
  - README.md - updated links to website/docs/
  - CLAUDE.md - updated documentation section
  - docs/ai-developer/CREATING-SCRIPTS.md - updated dev-docs output path
  - .devcontainer.extend/README-devcontainer-extended.md - updated tools link

**Validation:**
- [x] `dev-docs` writes to `website/docs/`
- [x] Generated pages render correctly with frontmatter
- [x] Admonitions show "Auto-generated" notices
- [x] All path references updated (historical files in completed plans left as-is)

---

## Phase 5: Tool Detail Pages — ✅ DONE

**Goal:** Create individual pages for each tool with detailed information.

- [x] Create template for tool pages (see docs/ai-developer/CREATING-TOOL-PAGES.md)
- [x] Create pages for top 6 tools:
  - [x] Python (`website/docs/tools/python.md`)
  - [x] TypeScript (`website/docs/tools/typescript.md`)
  - [x] PHP Laravel (`website/docs/tools/php-laravel.md`)
  - [x] API Development Tools (`website/docs/tools/api-development.md`)
  - [x] Claude Code (`website/docs/tools/claude-code.md`)
  - [x] Azure Operations & Infrastructure (`website/docs/tools/azure-ops.md`)
- [x] Document pattern for AI to auto-generate new tool pages (`docs/ai-developer/CREATING-TOOL-PAGES.md`)
- [x] Add `_category_.json` for tools folder organization

**Validation:**
- [x] Tool pages show in sidebar under "Tools"
- [x] Content is helpful and complete

---

## Phase 6: AI Development Section — ✅ DONE

**Goal:** Showcase AI-assisted development as a key feature.

- [x] Create `/docs/ai-development/` section:
  - [x] `index.md` - Main AI development overview with GIF
  - [x] `workflow.md` - Step-by-step implementation workflow
  - [x] `creating-plans.md` - Plan templates and best practices
  - [x] `_category_.json` - Sidebar configuration (position 3)
- [x] Feature prominently in navigation (sidebar position 3, after "What Are DevContainers?")
- [x] Link from landing page (AiDemo component now links to `/docs/ai-development`)
- [x] Copied `ai-make-plan.png` to `website/static/img/`

**Validation:**
- [x] AI section is easy to find
- [x] GIF displays correctly
- [x] Links work correctly

---

## Phase 7: Contributor Docs — ✅ DONE

**Goal:** Migrate contributor documentation.

- [x] Create `/docs/contributors/` section:
  - [x] `_category_.json` - Sidebar config (position 9)
  - [x] `index.md` - Contributing overview
  - [x] `adding-tools.md` - How to add new tools
  - [x] `testing.md` - Testing guide
  - [x] `ci-cd.md` - CI/CD and GitHub Actions
  - [x] `releasing.md` - Version management and releases
- [x] Mark as separate category in sidebar (position 9, after Tool Details)
- [x] Links to detailed docs in repository for advanced topics

**Validation:**
- [x] Contributor docs accessible but separate from user docs
- [x] Key content adapted for website

---

## Phase 8: GitHub Actions Deployment — ✅ DONE

**Goal:** Auto-deploy to GitHub Pages on push to main.

- [x] Create `.github/workflows/deploy-docs.yml`:
  - Triggers on push to main when `website/` changes
  - Uses Node.js 20 to build Docusaurus
  - Deploys using `actions/deploy-pages@v4`
  - Supports manual trigger via `workflow_dispatch`
- [x] Document GitHub Pages configuration (see below)

**GitHub Pages Setup (one-time, manual):**
1. Go to repository Settings → Pages
2. Under "Build and deployment", select "GitHub Actions" as source
3. The workflow will deploy automatically on next push to main

**Validation:**
- [x] Workflow file created
- [ ] Push to main triggers build (requires merge to test)
- [ ] Site live at https://terchris.github.io/devcontainer-toolbox/

---

## Phase 9: Polish and Launch — ✅ DONE

**Goal:** Final touches before announcing.

- [x] Add search (local search using @easyops-cn/docusaurus-search-local)
- [x] Review all pages for broken links (fixed anchor links in tools-details.md)
- [x] Add favicon and social card image (fixed social card reference)
- [x] Test on mobile (user to verify after deployment)
- [x] Update root README.md with link to docs site
- [x] Consolidate all documentation into `website/docs/`
- [x] Create contributor documentation subsections
- [x] Update website/README.md with correct devcontainer commands

**Changes made:**
- Installed `@easyops-cn/docusaurus-search-local` package
- Added `themes` config with search plugin to `docusaurus.config.ts`
- Fixed social card reference (`img/docusaurus-social-card.jpg`)
- Fixed broken anchors in `tools-details.md` (2 dashes instead of 3)
- Fixed anchor generation in `dev-docs.sh` for future regenerations
- Updated README.md documentation links to point to live site
- **Documentation consolidation:**
  - Moved `docs/contributors/` to `website/docs/contributors/` with new subsections:
    - `scripts/` - Install script creation guide
    - `architecture/` - System architecture, categories, libraries, menu system
    - `services/` - Service scripts overview
  - Moved `docs/ai-developer/` to `website/docs/ai-developer/`
  - Moved `docs/ai-docs/` to `website/docs/ai-docs/`
  - Moved media files to `website/static/` (GIFs to img/, .cast to recordings/)
  - Created `docs/README.md` explaining docs are now in website/
  - Added Docusaurus frontmatter and `_category_.json` to all moved folders
  - Fixed all broken links after reorganization
  - Created `website/docs/contributors/website.md` - Docusaurus workflow guide
  - Updated `website/README.md` with correct npm commands and `--host 0.0.0.0` flag

**Validation:**
- [x] Search works (search box appears in navbar)
- [x] Social sharing shows correct preview (fixed image reference)
- [x] `npm run build` completes with no broken links
- [x] All documentation consolidated in `website/docs/`

---

## Future Enhancements (Not in this plan)

- Blog for announcements
- Versioned docs
- i18n translations
- Custom React components
- Algolia DocSearch (when traffic justifies)

---

## Files to Create

| File | Purpose |
|------|---------|
| `website/` | Docusaurus project root |
| `website/docusaurus.config.js` | Main configuration |
| `website/sidebars.js` | Sidebar navigation |
| `website/src/pages/index.js` | Custom landing page |
| `website/docs/**` | Documentation content |
| `.github/workflows/deploy-docs.yml` | Auto-deployment |

---

## Dependencies

- Node.js (already in devcontainer base image)
- npm (already in devcontainer base image)
- No additional install scripts needed

---

## Risks

| Risk | Mitigation |
|------|------------|
| Migration breaks links | Test all links before launch |
| Build fails in CI | Test locally first, check Node version |
| GIFs too large | Already optimized, verified < 10MB |

---

## Success Criteria

1. Professional landing page that "sells" the project
2. Easy navigation to all documentation
3. Individual tool pages with detailed guides
4. AI development prominently featured
5. Auto-deploys on push
6. Works on mobile
