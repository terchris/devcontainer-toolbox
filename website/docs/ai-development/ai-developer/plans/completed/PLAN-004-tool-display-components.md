# Feature: Tool Display Components

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed ✅

**Goal:** Create React components to display tools with logos, abstracts, and extended metadata on the website.

**Completed:** 2026-01-17

**PR:** #19

**Source:** PLAN-003 (Extended Script and Category Metadata)

---

**Prerequisites:** PLAN-003 (completed - provides tools.json, categories.json, and logo assets)
**Blocks:** PLAN-005 (Interactive Homepage)
**Related:** None
**Priority:** High (enables visual tool browsing)

---

## Overview

PLAN-003 added extended metadata (tags, abstract, logo, website, summary, related) to all tools and categories. This plan creates React components to display this information visually.

### Data Sources

Available from PLAN-003:
- `website/src/data/tools.json` - Tool metadata with all extended fields
- `website/src/data/categories.json` - Category metadata
- `website/static/img/tools/*.webp` - Processed tool logos (512x512)
- `website/static/img/categories/*.webp` - Processed category logos (512x512)

### Components to Create

1. **ToolCard** - Displays a single tool with logo, name, abstract
2. **ToolGrid** - Grid layout for multiple ToolCards
3. **CategoryCard** - Displays a category with logo and description
4. **CategoryGrid** - Grid layout for CategoryCards
5. **ToolDetails** - Full tool page with all metadata
6. **RelatedTools** - Shows related tools as linked cards

---

## Visual Mockups

### ToolCard (Single Tool)

```
┌─────────────────────────────────────────────────────┐
│  ┌──────┐                                           │
│  │      │  Python Development Tools                 │
│  │  🐍  │  ─────────────────────────────────────    │
│  │      │  Full Python development environment      │
│  └──────┘  with pip, venv, and VS Code extensions.  │
│            Tags: python, pip, venv, pytest          │
└─────────────────────────────────────────────────────┘
     64x64
     logo
```

### ToolGrid (Desktop - 3 columns)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              Development Tools (10 tools)                                │
├─────────────────────────────┬─────────────────────────────┬─────────────────────────────┤
│ ┌──────┐                    │ ┌──────┐                    │ ┌──────┐                    │
│ │  🐍  │ Python Dev Tools   │ │  TS  │ TypeScript Tools   │ │  Go  │ Go Dev Tools       │
│ └──────┘ Full Python dev... │ └──────┘ TypeScript with... │ └──────┘ Go runtime and...  │
├─────────────────────────────┼─────────────────────────────┼─────────────────────────────┤
│ ┌──────┐                    │ ┌──────┐                    │ ┌──────┐                    │
│ │  🦀  │ Rust Dev Tools     │ │  C#  │ C# Dev Tools       │ │  ☕  │ Java Dev Tools     │
│ └──────┘ Rust via rustup... │ └──────┘ .NET SDK and...    │ └──────┘ JDK, Maven, and... │
├─────────────────────────────┴─────────────────────────────┴─────────────────────────────┤
│                                    [ View All 10 Tools → ]                               │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### ToolGrid (Mobile - 1 column)

```
┌─────────────────────────┐
│   Development Tools     │
├─────────────────────────┤
│ ┌──────┐                │
│ │  🐍  │ Python Tools   │
│ └──────┘ Full Python... │
├─────────────────────────┤
│ ┌──────┐                │
│ │  TS  │ TypeScript     │
│ └──────┘ TypeScript...  │
├─────────────────────────┤
│ ┌──────┐                │
│ │  Go  │ Go Tools       │
│ └──────┘ Go runtime...  │
├─────────────────────────┤
│   [ View All Tools → ]  │
└─────────────────────────┘
```

### CategoryCard

```
┌───────────────────────────────────────────┐
│  ┌────┐                                   │
│  │ </> │  Development Tools               │
│  └────┘  ──────────────────────────────   │
│          Programming language setups      │
│          for Python, Go, Rust, and more   │
│                                           │
│          10 tools available    [ Browse → ]│
└───────────────────────────────────────────┘
```

### CategoryGrid (Homepage section)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   Browse by Category                                     │
├─────────────────────────────┬─────────────────────────────┬─────────────────────────────┤
│  ┌────┐                     │  ┌────┐                     │  ┌────┐                     │
│  │</>│ Development Tools   │  │ ☁️ │ Cloud Tools         │  │ 📊 │ Data & Analytics   │
│  └────┘ 10 tools            │  └────┘ 5 tools             │  └────┘ 2 tools            │
├─────────────────────────────┼─────────────────────────────┼─────────────────────────────┤
│  ┌────┐                     │  ┌────┐                     │  ┌────┐                     │
│  │ 🤖 │ AI & ML Tools       │  │ ⚙️ │ Infrastructure      │  │ 🔧 │ Contributor Tools  │
│  └────┘ 1 tool              │  └────┘ 3 tools             │  └────┘ 1 tool             │
└─────────────────────────────┴─────────────────────────────┴─────────────────────────────┘
```

### Enhanced Tools Page (Full Layout)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  DevContainer Toolbox    Docs    v1.4.2                              GitHub   🔍 Search │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  # Available Tools                                                                       │
│                                                                                          │
│  20+ development tools ready to install with one click.                                  │
│                                                                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐│
│  │                              Browse by Category                                      ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   ││
│  │  │ </> Dev     │ │ ☁️ Cloud    │ │ 📊 Data     │ │ 🤖 AI       │ │ ⚙️ Infra    │   ││
│  │  │ 10 tools    │ │ 5 tools     │ │ 2 tools     │ │ 1 tool      │ │ 3 tools     │   ││
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   ││
│  └─────────────────────────────────────────────────────────────────────────────────────┘│
│                                                                                          │
│  ## Development Tools                                                                    │
│  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐                      │
│  │ 🐍 Python         │ │ TS TypeScript     │ │ Go Golang         │                      │
│  │ Full Python dev...│ │ TypeScript with...│ │ Go runtime and... │                      │
│  └───────────────────┘ └───────────────────┘ └───────────────────┘                      │
│  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐                      │
│  │ 🦀 Rust           │ │ C# .NET           │ │ ☕ Java            │                      │
│  │ Rust via rustup...│ │ .NET SDK and...   │ │ JDK, Maven, and...│                      │
│  └───────────────────┘ └───────────────────┘ └───────────────────┘                      │
│                                                                                          │
│  ## Cloud & Infrastructure Tools                                                         │
│  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐                      │
│  │ ☁️ Azure Dev      │ │ ☁️ Azure Ops      │ │ ☸️ Kubernetes     │                      │
│  │ Azure CLI, Func...│ │ PowerShell, Az... │ │ kubectl, helm,... │                      │
│  └───────────────────┘ └───────────────────┘ └───────────────────┘                      │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### RelatedTools (Horizontal scroll on tool detail page)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  Related Tools                                                                           │
│  ────────────────────────────────────────────────────────────────────────────────────── │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                     │
│  │ 🐍 Python   │  │ Go Golang   │  │ 🦀 Rust     │  │ 📊 Data     │  ← scroll →         │
│  │ Full dev... │  │ Go runtime..│  │ Systems...  │  │ Jupyter,... │                     │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘                     │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

### Tool Detail Page (Enhanced)

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  DevContainer Toolbox    Docs                                                            │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                          │
│  ┌────────────┐                                                                          │
│  │            │   Python Development Tools                                               │
│  │    🐍      │   ════════════════════════════                                           │
│  │            │                                                                          │
│  │  128x128   │   Full Python development environment with pip, venv,                    │
│  └────────────┘   and VS Code extensions.                                                │
│                                                                                          │
│  **Website:** [python.org](https://python.org)                                           │
│  **Category:** Development Tools                                                         │
│  **Tags:** `python` `pip` `venv` `pytest` `ipython`                                      │
│                                                                                          │
│  ───────────────────────────────────────────────────────────────────────────────────────│
│                                                                                          │
│  ## Description                                                                          │
│                                                                                          │
│  Complete Python development setup including virtual environment management,             │
│  package installation via pip, and VS Code integration. Adds ipython for                 │
│  interactive development, pytest for testing, and common development utilities.          │
│                                                                                          │
│  ───────────────────────────────────────────────────────────────────────────────────────│
│                                                                                          │
│  ## Installation                                                                         │
│                                                                                          │
│  ```bash                                                                                 │
│  # Via dev-setup menu                                                                    │
│  dev-setup                                                                               │
│                                                                                          │
│  # Or directly                                                                           │
│  .devcontainer/additions/install-dev-python.sh                                           │
│  ```                                                                                     │
│                                                                                          │
│  ───────────────────────────────────────────────────────────────────────────────────────│
│                                                                                          │
│  ## Related Tools                                                                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                                      │
│  │ 📊 Data     │  │ 🤖 Claude   │  │ Go Golang   │                                      │
│  │ Analytics   │  │ Code        │  │ Go runtime  │                                      │
│  └─────────────┘  └─────────────┘  └─────────────┘                                      │
│                                                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: ToolCard Component — ✅ DONE

Create a reusable card component for displaying a single tool.

### Tasks

- [x] 1.1 Create `website/src/components/ToolCard/index.tsx`
- [x] 1.2 Create `website/src/components/ToolCard/styles.module.css`
- [x] 1.3 Component props: `tool` object with all fields, `showTags` boolean
- [x] 1.4 Display: logo (64x64), name (linked to detail page), abstract (2 lines max)
- [x] 1.5 Hover effect: subtle elevation/shadow
- [x] 1.6 Responsive: flex layout works on all screens

### Validation

```bash
cd website && npm run start
# Verify ToolCard renders correctly with sample data
```

---

## Phase 2: ToolGrid Component — ✅ DONE

Create a grid component that displays multiple tools.

### Tasks

- [x] 2.1 Create `website/src/components/ToolGrid/index.tsx`
- [x] 2.2 Create `website/src/components/ToolGrid/styles.module.css`
- [x] 2.3 Import tools from `@site/src/data/tools.json`
- [x] 2.4 Props: `category`, `limit`, `showViewAll`, `showTags`, `title`
- [x] 2.5 Responsive grid: 1 col mobile, 2 col tablet, 3-4 col desktop
- [x] 2.6 Optional "View All" link when `limit` is set and more tools exist

### Validation

```bash
# Add ToolGrid to a test page and verify filtering works
```

---

## Phase 3: CategoryCard and CategoryGrid — ✅ DONE

Create components for displaying categories.

### Tasks

- [x] 3.1 Create `website/src/components/CategoryCard/index.tsx`
- [x] 3.2 Create `website/src/components/CategoryGrid/index.tsx`
- [x] 3.3 CategoryCard: logo (48x48), name, abstract, tool count, links to category section
- [x] 3.4 CategoryGrid: responsive grid (1-4 cols), sorted by order, excludes empty
- [x] 3.5 Import from both categories.json and tools.json for counting

### Validation

```bash
# Verify categories display with correct tool counts
```

---

## Phase 4: Enhanced Tools Page — ✅ DONE

Replace or enhance the current tools page with visual components.

### Tasks

- [x] 4.1 Create `website/src/pages/tools.tsx` with matching CSS
- [x] 4.2 Display CategoryGrid at top with "Browse by Category" title
- [x] 4.3 Display ToolGrid for each category, sorted by order
- [ ] 4.4 Add search/filter by tags (deferred to future enhancement)
- [x] 4.5 Existing `/docs/tools/` links unchanged (new page is `/tools`)

### Validation

```bash
cd website && npm run build
# Verify no broken links, visual display works
```

---

## Phase 5: RelatedTools Component — ✅ DONE

Show related tools on tool detail pages.

### Tasks

- [x] 5.1 Create `website/src/components/RelatedTools/index.tsx`
- [x] 5.2 Takes `relatedIds` prop (array of tool IDs), `title` prop
- [x] 5.3 Displays as horizontal scrollable row of mini cards (48x48 logo)
- [ ] 5.4 Integrate into tool detail pages (deferred - requires MDX migration)

### Validation

```bash
# Verify related tools display correctly on a sample tool page
```

---

## Phase 6: Integration and Testing — ✅ DONE

### Tasks

- [x] 6.1 Run full build to verify no errors (warnings only for existing TOC anchors)
- [x] 6.2 Test on localhost with Chrome
- [ ] 6.3 Verify responsive design on mobile viewport (deferred)
- [x] 6.4 Verify all logos load correctly (fixed useBaseUrl)
- [x] 6.5 Verify links work (tool pages, category pages)

### Validation

```bash
docker exec <container> bash -c "cd /workspace/website && npm run build"
# Test in Chrome at localhost:3000
```

---

## Phase 7: Sidebar Reordering — ✅ DONE

Restructure the documentation sidebar for better organization.

### New Sidebar Order

```
1. DevContainer Toolbox (intro)
2. Getting Started
3. Tools (with category folders and tool pages)
4. What Are DevContainers?
5. AI Development (parent folder)
   ├── AI Developer (Internal)
   └── AI Demos & Recordings
6. Commands Reference
7. Configuration
8. Troubleshooting
9. Contributing
```

### Tasks

- [x] 7.1 Update sidebar positions in frontmatter:
  - intro.md → position 1
  - getting-started/ → position 2
  - tools/ → position 3
  - what-are-devcontainers/ → position 4
  - commands.md → position 6
  - configuration.md → position 7
  - troubleshooting.md → position 8
  - contributing.md → position 9
- [x] 7.2 `docs/ai-development/` folder already existed with `_category_.json` (updated position 5)
- [x] 7.3 Move `docs/ai-developer/` → `docs/ai-development/ai-developer/`
- [x] 7.4 Move `docs/ai-docs/` → `docs/ai-development/ai-docs/`
- [x] 7.5 Update `_category_.json` files for nested folders
- [x] 7.6 Fix relative links in moved files (../contributors/ → ../../contributors/)

---

## Phase 8: Individual Tool Pages — ✅ DONE

Create dedicated pages for each tool (no anchor links).

### Tasks

- [x] 8.1 Updated dev-docs.sh to generate individual tool pages:
  - Added `generate_tool_pages()` function
  - Generates category folders, _category_.json, index.mdx, and tool .mdx files
  - 5 category index pages + 21 individual tool pages
- [x] 8.2 Added utility functions in anchors.ts:
  - `getCategoryFolder()` - maps category ID to folder name
  - `getToolFilename()` - strips prefixes from tool ID
  - `getToolPath()` - generates full tool page path
- [x] 8.3 Updated components to link to new pages:
  - ToolCard uses `getToolPath()`
  - CategoryCard uses `getCategoryFolder()`
  - RelatedTools uses `getToolPath()`
- [x] 8.4 Removed old files: tools-details.md, partial tool pages
- [x] 8.5 Fixed broken link in ai-development/index.md

---

## Phase 9: Commit and Deploy — PENDING

### Tasks

- [ ] 9.1 Commit all changes
- [ ] 9.2 Bump version in version.txt
- [ ] 9.3 Push and create PR
- [ ] 9.4 Verify on deployed site

---

## Acceptance Criteria

- [ ] ToolCard displays logo, name, abstract correctly
- [ ] ToolGrid shows tools in responsive grid
- [ ] CategoryCard displays category info with tool count
- [ ] Tools page shows visual browsing experience
- [ ] All components are responsive (mobile-friendly)
- [ ] No broken images or links
- [ ] Build passes without errors

---

## Files to Create

**Components:**
- `website/src/components/ToolCard/index.tsx`
- `website/src/components/ToolCard/styles.module.css`
- `website/src/components/ToolGrid/index.tsx`
- `website/src/components/ToolGrid/styles.module.css`
- `website/src/components/CategoryCard/index.tsx`
- `website/src/components/CategoryCard/styles.module.css`
- `website/src/components/CategoryGrid/index.tsx`
- `website/src/components/CategoryGrid/styles.module.css`
- `website/src/components/RelatedTools/index.tsx`
- `website/src/components/RelatedTools/styles.module.css`

**Pages (optional - may use MDX instead):**
- `website/src/pages/tools.tsx`

---

## Design Notes

### Color Scheme

Use existing Docusaurus theme colors:
- Primary: `--ifm-color-primary` (green #25c2a0)
- Background: `--ifm-background-color`
- Card background: slightly elevated from page background

### Logo Display

- Tool cards: 64x64px logos
- Category cards: 48x48px logos
- Detail pages: 128x128px logos
- Use `object-fit: contain` to preserve aspect ratio

### Typography

- Tool name: `font-weight: 600`
- Abstract: `font-size: 0.9rem`, `color: var(--ifm-color-emphasis-700)`
- Tags: small badges with category color

---

## Implementation Notes

### Importing JSON Data

```tsx
import toolsData from '@site/src/data/tools.json';
import categoriesData from '@site/src/data/categories.json';

const { tools } = toolsData;
const { categories } = categoriesData;
```

### Logo Paths

```tsx
// Logo path pattern
const logoPath = `/img/tools/${tool.logo}`;
// e.g., /img/tools/dev-python-logo.webp
```

### Filtering by Category

```tsx
const filteredTools = tools.filter(tool => tool.category === categoryId);
```
