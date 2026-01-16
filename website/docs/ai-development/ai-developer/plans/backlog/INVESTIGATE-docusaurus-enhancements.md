# Investigate: Docusaurus Website Enhancements

## Status: Active

**Goal:** Research ways to enhance the Docusaurus website - better tool displays, custom theming, images, and useful plugins.

**Last Updated:** 2026-01-16

---

## Critical Issue: Hardcoded Repository URLs

The site currently has hardcoded URLs to `terchris/devcontainer-toolbox`. When contributing to the main repo, these need to change.

**Files with hardcoded URLs:**
- `docusaurus.config.ts` - url, organizationName, editUrl, GitHub links
- `README.md` - docs site links, install scripts
- Various `.md` files - GitHub links, CLAUDE.md references

**Solution Options:**

### Option 1: Environment Variables (Recommended)
```typescript
// docusaurus.config.ts
const GITHUB_ORG = process.env.GITHUB_ORG || 'terchris';
const GITHUB_REPO = process.env.GITHUB_REPO || 'devcontainer-toolbox';

const config: Config = {
  url: `https://${GITHUB_ORG}.github.io`,
  baseUrl: `/${GITHUB_REPO}/`,
  organizationName: GITHUB_ORG,
  projectName: GITHUB_REPO,
  // ...
};
```

GitHub Actions can set these from repository context:
```yaml
env:
  GITHUB_ORG: ${{ github.repository_owner }}
  GITHUB_REPO: ${{ github.event.repository.name }}
```

### Option 2: Single Config File
Create `website/site.config.js`:
```js
module.exports = {
  githubOrg: 'terchris',
  githubRepo: 'devcontainer-toolbox',
};
```

### Option 3: GitHub Pages Custom Domain
If using a custom domain, URLs become repo-independent.

**Recommendation:** Option 1 (Environment Variables)
- Works automatically in GitHub Actions
- Local dev uses defaults
- No manual changes needed when forking

**Implementation:**
1. Update `docusaurus.config.ts` to use env vars
2. Update GitHub Actions workflow to pass repo context
3. For markdown files, use relative links where possible
4. Document the env vars in `website/README.md`

---

## Future Scope: Templates Integration

**Current state:**
- `dev-template.sh` downloads templates from [urbalurba-dev-templates](https://github.com/terchris/urbalurba-dev-templates)
- Templates work with [urbalurba-infrastructure](https://github.com/terchris/urbalurba-infrastructure)

**Future plan:**
- Merge templates into devcontainer-toolbox
- Website covers both **Tools** AND **Templates/Starters**

**Design implications:**

The website structure should accommodate:
```
DevContainer Toolbox
├── Tools (current)
│   ├── Languages (Python, TypeScript, Go...)
│   ├── Cloud & Infrastructure
│   └── AI & ML
│
├── Templates (future)
│   ├── Frontend (React, Next.js, Vue...)
│   ├── Backend (Express, FastAPI, Spring...)
│   └── Full Stack (Next.js + API, etc.)
│
└── Infrastructure (future)
    └── Terraform, K8s configs...
```

**Homepage sections to plan for:**
1. **Tools** - Install development environments
2. **Templates** - Start new projects from templates
3. **Infrastructure** - Deploy to cloud (future)

**Card-based navigation benefits:**
- Easy to add "Templates" section alongside "Tools"
- Same card components work for both
- Use cases can combine tools + templates:
  - "Build a Python API" → Python tools + FastAPI template
  - "React + Azure" → TypeScript tools + React template + Azure tools

**Template metadata (mirrors script metadata):**
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
TEMPLATE_ABSTRACT="Production-ready Next.js 14 starter with App Router, TypeScript, Tailwind CSS, and ESLint preconfigured. Includes example pages and API routes."
TEMPLATE_RELATED="react-starter vite-starter"

# --- Template-specific fields ---
TEMPLATE_TOOLS="dev-typescript"           # Required tools to install
TEMPLATE_REPO="https://github.com/..."    # Source repo (if external)
TEMPLATE_DEMO="https://demo.example.com"  # Live demo URL (optional)
```

**Shared metadata fields (Tools & Templates):**
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

**Note:** Design decisions now should consider this expansion. Keep component names generic (e.g., `ItemCard` not `ToolCard`).

---

## Future Scope: Infrastructure Services

The [urbalurba-infrastructure](https://github.com/terchris/urbalurba-infrastructure) repo contains deployment packages for:

**AI & ML:**
- LiteLLM (AI gateway)
- OpenWebUI
- Environment management

**Authentication:**
- Authentik (SSO/Identity)

**Databases:**
- PostgreSQL, MySQL, MongoDB
- Qdrant (vector database)

**Data Science:**
- JupyterHub
- Apache Spark
- Unity Catalog

**Development:**
- ArgoCD (GitOps)
- Templates

**Monitoring:**
- Grafana, Prometheus
- Loki (logs), Tempo (traces)
- OpenTelemetry

**Queues & Messaging:**
- RabbitMQ
- Redis

**Search:**
- Elasticsearch

**Networking:**
- Cloudflare
- Tailscale

**Hosts:**
- Azure AKS
- MicroK8s (Azure, Multipass, Raspberry Pi)
- Rancher Kubernetes

**Website structure with infrastructure:**
```
DevContainer Toolbox
├── Tools (development environments)
├── Templates (project starters)
└── Infrastructure (deployment packages)
    ├── AI & ML
    ├── Databases
    ├── Monitoring
    ├── Queues
    └── ...
```

**Infrastructure metadata:**
```bash
# --- Core metadata ---
PACKAGE_ID="postgresql"
PACKAGE_VER="15.0"
PACKAGE_NAME="PostgreSQL Database"
PACKAGE_DESCRIPTION="Production-ready PostgreSQL with backups and monitoring"
PACKAGE_CATEGORY="DATABASES"

# --- Extended metadata ---
PACKAGE_LOGO="postgresql-logo.svg"
PACKAGE_WEBSITE="https://postgresql.org"
PACKAGE_TAGS="database sql postgres relational"
PACKAGE_ABSTRACT="PostgreSQL deployed on Kubernetes with automated backups, monitoring via Prometheus, and connection pooling with PgBouncer."
PACKAGE_RELATED="pgadmin mysql mongodb"

# --- Infrastructure-specific ---
PACKAGE_REQUIRES="kubernetes helm"
PACKAGE_NAMESPACE="databases"
PACKAGE_HELM_CHART="bitnami/postgresql"
```

**Three content types with unified metadata:**
| Type | Prefix | Source Repo |
|------|--------|-------------|
| Tools | `SCRIPT_*` | devcontainer-toolbox |
| Templates | `TEMPLATE_*` | devcontainer-toolbox (merged) |
| Infrastructure | `PACKAGE_*` | urbalurba-infrastructure (separate) |

---

## Cross-Repo Data Sharing

The `urbalurba-infrastructure` repo will remain **separate**, but its metadata needs to be available on this website.

**Options for sharing metadata:**

### Option 1: JSON Metadata File (Recommended)
Infrastructure repo publishes a `packages.json`:
```json
{
  "packages": [
    {
      "id": "postgresql",
      "name": "PostgreSQL Database",
      "description": "Production-ready PostgreSQL...",
      "category": "DATABASES",
      "logo": "postgresql-logo.svg",
      "website": "https://postgresql.org",
      "tags": ["database", "sql", "postgres"],
      "docsUrl": "https://urbalurba-infrastructure.../docs/postgresql"
    }
  ]
}
```

**Website fetches at build time:**
```typescript
// docusaurus.config.ts or a plugin
const infraPackages = await fetch(
  'https://raw.githubusercontent.com/terchris/urbalurba-infrastructure/main/packages.json'
).then(r => r.json());
```

### Option 2: Shared Metadata Schema
Define a schema both repos follow:
```
/metadata/
  schema.json        # Shared JSON schema
  tools.json         # From devcontainer-toolbox
  templates.json     # From devcontainer-toolbox
  packages.json      # From urbalurba-infrastructure (fetched)
```

### Option 3: GitHub Action Sync
Infrastructure repo has a GitHub Action that:
1. Generates `packages.json` from package metadata
2. Creates a PR to devcontainer-toolbox with updated data
3. Or publishes to a shared location (GitHub Pages, CDN)

### Option 4: Docusaurus Remote Content Plugin
Use `docusaurus-plugin-remote-content` to fetch docs:
```js
plugins: [
  [
    'docusaurus-plugin-remote-content',
    {
      name: 'infrastructure-packages',
      sourceBaseUrl: 'https://raw.githubusercontent.com/terchris/urbalurba-infrastructure/main/',
      documents: ['packages.json'],
    },
  ],
],
```

### Full Documentation Integration

Not just metadata - the **entire documentation** from urbalurba-infrastructure must be available on this website.

**Options for pulling full docs:**

#### Option A: Git Submodule
```bash
# In devcontainer-toolbox
git submodule add https://github.com/terchris/urbalurba-infrastructure.git external/infrastructure
```

Docusaurus config:
```js
docs: {
  path: 'docs',
  include: ['**/*.md'],
},
plugins: [
  [
    '@docusaurus/plugin-content-docs',
    {
      id: 'infrastructure',
      path: 'external/infrastructure/docs',
      routeBasePath: 'infrastructure',
      sidebarPath: './sidebarsInfrastructure.ts',
    },
  ],
],
```

**Pros:** Full docs available, version controlled
**Cons:** Must update submodule manually

#### Option B: Remote Content Plugin (Recommended)
Use `docusaurus-plugin-remote-content` to fetch all docs:

```js
plugins: [
  [
    'docusaurus-plugin-remote-content',
    {
      name: 'infrastructure-docs',
      sourceBaseUrl: 'https://raw.githubusercontent.com/terchris/urbalurba-infrastructure/main/docs/',
      outDir: 'docs/infrastructure',
      documents: [
        'index.md',
        'package-databases-postgresql.md',
        'package-monitoring-grafana.md',
        // ... or use a manifest file
      ],
    },
  ],
],
```

**Pros:** Always fetches latest, no submodule management
**Cons:** Need to maintain document list (or use manifest)

#### Option C: Build-Time Sync Script
GitHub Action fetches docs before build:

```yaml
# .github/workflows/deploy-docs.yml
jobs:
  build:
    steps:
      - name: Fetch infrastructure docs
        run: |
          git clone --depth 1 https://github.com/terchris/urbalurba-infrastructure.git /tmp/infra
          cp -r /tmp/infra/docs website/docs/infrastructure

      - name: Build Docusaurus
        run: npm run build
```

**Pros:** Simple, full control
**Cons:** Docs not in git (generated at build time)

#### Option D: Manifest-Based Sync (Recommended)
Infrastructure repo publishes a `docs-manifest.json`:

```json
{
  "version": "1.0.0",
  "baseUrl": "https://raw.githubusercontent.com/terchris/urbalurba-infrastructure/main/docs/",
  "documents": [
    {"path": "index.md", "category": "overview"},
    {"path": "package-databases-postgresql.md", "category": "databases"},
    {"path": "package-monitoring-grafana.md", "category": "monitoring"}
  ]
}
```

Website fetches manifest, then fetches all listed docs at build time.

**Recommendation:** Option C (Build-Time Sync) or Option A (Submodule)

**Data flow with full docs:**
```
urbalurba-infrastructure/
├── docs/
│   ├── index.md
│   ├── package-databases-postgresql.md
│   ├── package-monitoring-grafana.md
│   └── ... (80+ docs)
├── docs-manifest.json (list of all docs)
└── packages.json (metadata for cards)
        │
        ▼ (clone/fetch at build time)
devcontainer-toolbox/website/
├── docs/
│   ├── tools/           # Local
│   ├── templates/       # Local
│   └── infrastructure/  # Fetched from infra repo
│       ├── index.md
│       ├── databases/
│       │   └── postgresql.md
│       └── monitoring/
│           └── grafana.md
└── src/data/
    └── packages.json (for cards/navigation)
```

**Website structure:**
```
https://devcontainer-toolbox.../
├── /docs/tools/          → Development tools
├── /docs/templates/      → Project templates
└── /docs/infrastructure/ → Infrastructure packages
    ├── /databases/
    ├── /monitoring/
    └── /ai/
```

**Benefits:**
- Single website for everything
- Full documentation searchable
- Unified navigation
- Repos stay independent
- Always up-to-date (fetched at build)

---

## Research Findings

### Current Setup
We already have:
- `@easyops-cn/docusaurus-search-local` - Local search
- Prism syntax highlighting (bash, powershell, json)
- Dark/light mode with system preference
- Custom CSS support

### Recommended Plugins to Add

#### 1. Mermaid Diagrams (High Priority)
**Plugin:** `@docusaurus/theme-mermaid` (official)

Great for visualizing:
- Tool installation flows
- Architecture diagrams
- Devcontainer structure

**Setup:**
```bash
npm install @docusaurus/theme-mermaid
```

```js
// docusaurus.config.ts
export default {
  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],
};
```

#### 2. Image Zoom (Medium Priority)
**Plugin:** `docusaurus-plugin-image-zoom`

Allows users to click on images to zoom - great for screenshots.

```bash
npm install docusaurus-plugin-image-zoom
```

#### 3. Ideal Image (Medium Priority)
**Plugin:** `@docusaurus/plugin-ideal-image` (official)

Responsive images with lazy loading - better performance.

```bash
npm install @docusaurus/plugin-ideal-image
```

#### 4. Version Badge in Navbar (High Priority)
Built-in feature - no plugin needed. Display version from `version.txt` in navbar.

**Implementation:** Read version at build time in `docusaurus.config.ts`:

```typescript
import fs from 'fs';

const version = fs.readFileSync('../version.txt', 'utf8').trim();

// In navbar items:
{
  type: 'html',
  position: 'right',
  value: `<span class="badge badge--secondary">v${version}</span>`,
},
```

**Benefits:**
- Users see which version docs apply to
- Auto-updates when version.txt changes
- No manual maintenance

#### 5. Announcement Bar (Low Priority)
Built-in feature - no plugin needed. Add to themeConfig:

```js
announcementBar: {
  id: 'new_release',
  content: '🎉 Version 1.4.0 released with new documentation site!',
  backgroundColor: '#25c2a0',
  textColor: '#fff',
  isCloseable: true,
},
```

#### 6. Analytics - Umami (Medium Priority)
**Plugin:** `@dipakparmar/docusaurus-plugin-umami`

Privacy-friendly analytics without cookie banners.

```bash
npm install @dipakparmar/docusaurus-plugin-umami
```

**Options:**
| Service | Cost | Notes |
|---------|------|-------|
| [Umami Cloud](https://umami.is/) | $9/mo | Easiest setup |
| Self-hosted | Free | Need server (Docker available) |

**Why Umami over Google Analytics:**
- No cookies = no cookie banner needed
- GDPR compliant out of the box
- ~2KB script (lightweight)
- Only active in production
- You own the data

### Plugins to Skip (For Now)

| Plugin | Reason |
|--------|--------|
| Algolia DocSearch | Requires approval process, local search works fine |
| PWA | Adds complexity, not essential for docs |
| Google Analytics | Privacy concerns, requires cookie consent |

### Plugins for Future Consideration

#### OpenAPI Documentation
**Plugins:** `docusaurus-openapi-docs`, `Redocusaurus`

Generates interactive API reference docs from OpenAPI/Swagger specs.
- Converts `openapi.yaml` → beautiful MDX pages
- Includes "try it out" demo panels
- Supports Swagger 2.0 and OpenAPI 3.x

**When to add:** If devcontainer-toolbox adds a REST API

**Resources:**
- [docusaurus-openapi-docs](https://github.com/PaloAltoNetworks/docusaurus-openapi-docs)
- [Redocusaurus](https://github.com/rohit-gohri/redocusaurus)

#### TypeDoc - TypeScript API Docs
**Plugin:** `docusaurus-plugin-typedoc-api`

Auto-generates API documentation from TypeScript source code.
- Reads JSDoc comments from code
- Creates `/api/*` routes automatically
- Documents public exports only

**When to add:** If devcontainer-toolbox adds a TypeScript CLI or library

**Resources:**
- [docusaurus-plugin-typedoc-api](https://github.com/milesj/docusaurus-plugin-typedoc-api)

---

## Theme Enhancements

### Custom Branding Ideas

1. **Custom Logo** - Replace default Docusaurus logo with project-specific icon
2. **Color Scheme** - Adjust primary color (currently default green #25c2a0)
3. **Social Card** - Create custom OG image for social sharing

### Tool Page Improvements

Current tool pages are plain markdown. Options to enhance:

1. **Feature Cards** - Use Docusaurus admonitions or custom components
2. **Icons/Badges** - Add category badges (e.g., "Language", "Cloud", "AI")
3. **Quick Start Boxes** - Highlighted install commands
4. **Screenshots** - Add terminal screenshots or GIFs for each tool
5. **Related Tools** - Link similar tools at bottom of each page

### Extended Script Metadata (Source of Truth)

Current metadata in each script:
```bash
SCRIPT_ID="dev-python"
SCRIPT_VER="0.0.1"
SCRIPT_NAME="Python Development Tools"
SCRIPT_DESCRIPTION="Adds ipython, pytest-cov, and VS Code extensions"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command -v ipython >/dev/null 2>&1"
```

**Proposed additional metadata fields:**

| Field | Purpose | Example |
|-------|---------|---------|
| `SCRIPT_LOGO` | Icon/logo filename | `python-logo.svg` |
| `SCRIPT_WEBSITE` | Official tool website | `https://python.org` |
| `SCRIPT_TAGS` | Search keywords | `"python pip venv"` |
| `SCRIPT_ABSTRACT` | Longer description (2-3 sentences) | For tool detail pages |
| `SCRIPT_RELATED` | Related tool IDs | `"dev-data-analytics dev-ai"` |

**Benefits:**
- Single source of truth (script file)
- `dev-docs` auto-generates richer tool pages
- New tools automatically get proper documentation
- No manual website updates needed

**Implementation:**
1. Add new metadata fields to script template
2. Update `dev-docs.sh` to read and output new fields
3. Store logos in `website/static/img/tools/`
4. Update existing scripts incrementally

### Interactive Category Browser (Homepage)

Make the homepage more interactive - users click a category to see its tools.

**Option 1: Tabs Component (Built-in)**
```jsx
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

<Tabs>
  <TabItem value="lang" label="Languages" default>
    Python, TypeScript, Go, Rust...
  </TabItem>
  <TabItem value="cloud" label="Cloud & Infrastructure">
    Azure, Terraform, Kubernetes...
  </TabItem>
  <TabItem value="ai" label="AI & ML">
    Claude Code...
  </TabItem>
</Tabs>
```

**Option 2: Custom Filter Component (More Flexible)**
Create `src/components/ToolBrowser/`:
- Grid of category buttons/cards
- Click category → show tools in that category
- Optional: "All" button to show everything
- Can include icons for each category

**Option 3: Clickable Category Cards**
Each category as a card with:
- Category icon
- Category name
- Tool count badge
- Click → scrolls to or filters tool list

**Data Source:**
- Read from generated JSON (from `dev-docs.sh`)
- Or import tools data at build time
- Categories from `SCRIPT_CATEGORY` values

**Recommendation:** Option 2 (Custom Filter Component)
- Most flexible and visually appealing
- Can show tool cards with logos
- Better UX than tabs for many categories

### Example Tool Page Structure

```markdown
# Python Development

![Python Logo](/img/tools/python-logo.svg)

:::tip Quick Install
Run `dev-setup` and select "Python Development"
:::

## What's Included
- Python 3.x with pip
- Virtual environment support
- Common development packages

## Features
| Feature | Description |
|---------|-------------|
| Version | 3.12+ |
| Package Manager | pip, pipx |
| ...

## Getting Started
[code examples]

## Related Tools
- Data Analytics
- AI & Machine Learning
```

---

## Inspiration Sites

Reviewed these for ideas:

| Site | Good Ideas |
|------|------------|
| [Docusaurus.io](https://docusaurus.io) | Clean design, good code examples |
| [Vite](https://vitejs.dev) | Minimal, fast, great icons |
| [Tailwind CSS](https://tailwindcss.com/docs) | Excellent search, code examples |
| [Dyte](https://docs.dyte.io) | Feature cards, topic navigation ⭐ |

### Dyte Design Analysis (Reference for Our Site)

Dyte uses a **topic-based card navigation** approach:

**Homepage Structure:**
1. **Hero Section** - 3 large feature cards with icons and descriptions
2. **How-To Guides** - Grid of popular guides
3. **Sample Applications** - Real-world examples with "Clone" / "View" links
4. **SDK Hub** - Organized by platform (React, iOS, Android, etc.)

**Card Design Pattern:**
```
┌─────────────────────────────┐
│  🐍 Icon                    │
│                             │
│  Python Development         │
│                             │
│  Full Python setup with     │
│  pip, venv, and VS Code     │
│  extensions.                │
│                             │
│  [Get Started] [View Tools] │
└─────────────────────────────┘
```

**Key UX Patterns:**
- Multiple entry points (by category, by use case, by platform)
- Cards have icon + heading + description + action links
- Modular sections for different audiences
- Visual hierarchy guides the reader

### Applying Dyte Patterns to DevContainer Toolbox

**Homepage Redesign Ideas:**

1. **Hero Cards (3 columns):**
   - "Language Development" → Python, TypeScript, Go...
   - "Cloud & Infrastructure" → Azure, Terraform, K8s...
   - "AI-Ready Development" → Claude Code, isolated environment

2. **"Get Started" Section:**
   - Card: "New to DevContainers?" → What Are DevContainers
   - Card: "Install Now" → Quick Start guide
   - Card: "Browse Tools" → Interactive tool browser

3. **Use Case Cards:**
   - "Backend Developer" → Python + API + Database tools
   - "Cloud Engineer" → Azure + Terraform + K8s
   - "AI Developer" → Claude Code + Python + isolated env

4. **Tool Category Cards:**
   Each category as a clickable card:
   ```
   ┌────────────┐ ┌────────────┐ ┌────────────┐
   │ 💻         │ │ ☁️         │ │ 🤖         │
   │ Languages  │ │ Cloud      │ │ AI & ML    │
   │ 10 tools   │ │ 5 tools    │ │ 1 tool     │
   │ [Browse →] │ │ [Browse →] │ │ [Browse →] │
   └────────────┘ └────────────┘ └────────────┘
   ```

**Components to Create:**
- `FeatureCard` - Large card with icon, title, description, CTA
- `ToolCategoryCard` - Smaller card with icon, name, count, link
- `UseCaseCard` - Card linking to curated tool combinations
- `QuickStartCard` - Prominent getting started paths

---

## Implementation Plans

Each plan delivers a **launchable increment** - the site remains functional after each plan.

**Naming:** Plans use `PLAN-00n-*` format to indicate execution order (see [PLANS.md](../../PLANS.md)).

---

### PLAN-001: Configurable Repository URLs
**Priority:** Critical (must do first)
**Depends on:** Nothing
**Launchable after:** Yes - site works on any fork

**Scope:**
- Make `docusaurus.config.ts` use environment variables for GitHub org/repo
- Update GitHub Actions to pass `${{ github.repository_owner }}`
- Convert hardcoded links to relative where possible
- Document env vars in `website/README.md`

**Files to modify:**
- `website/docusaurus.config.ts`
- `.github/workflows/deploy-docs.yml`
- Various `.md` files with hardcoded URLs

---

### PLAN-002: Quick Enhancements
**Priority:** High
**Depends on:** PLAN-001
**Launchable after:** Yes - improved UX

**Scope:**
- Add version badge to navbar (read from `version.txt`)
- Add Mermaid diagrams support (`@docusaurus/theme-mermaid`)
- Add image zoom plugin (`docusaurus-plugin-image-zoom`)
- Add announcement bar (config only, no plugin)

**Files to modify:**
- `website/docusaurus.config.ts`
- `website/package.json`

---

### PLAN-003: Extended Script Metadata
**Priority:** High (foundation for tool pages)
**Depends on:** Nothing (can run parallel to PLAN-002)
**Launchable after:** Yes - existing site unchanged, new metadata ready

**Scope:**

**1. Define extended metadata fields:**
- SCRIPT_LOGO - Icon filename (e.g., "python-logo.svg")
- SCRIPT_WEBSITE - Official tool URL
- SCRIPT_TAGS - Search keywords
- SCRIPT_ABSTRACT - Longer description (2-3 sentences)
- SCRIPT_RELATED - Related tool IDs

**2. Update documentation & templates:**
- Update `website/docs/ai-developer/CREATING-SCRIPTS.md` with new fields
- Update `website/docs/contributors/scripts/install-scripts.md`
- Update script template files (`_template-install.sh`, etc.)
- Ensure new tools are created with all metadata fields

**3. Update tooling:**
- Update `dev-docs.sh` to read and output new fields
- Update `dev-docs.sh` to output `tools.json` for React components
- Investigate how `dev-setup.sh` can use new metadata:
  - Show SCRIPT_ABSTRACT in menu descriptions?
  - Use SCRIPT_TAGS for search/filter?
  - Display SCRIPT_WEBSITE as "More info" link?

**4. Add validation:**
- Update static tests to validate new metadata fields exist
- Warn if SCRIPT_LOGO file doesn't exist
- Validate SCRIPT_RELATED references valid tool IDs
- Ensure CI fails if metadata is incomplete

**5. Update ALL existing tools:**
- Add extended metadata to ALL scripts (21+ scripts)
- Add logos for ALL tools to `website/static/img/tools/`
- Verify each tool passes validation

**Files to modify:**
- `.devcontainer/manage/dev-docs.sh`
- `.devcontainer/manage/dev-setup.sh` (investigate enhancements)
- `.devcontainer/additions/_template-*.sh` (all templates)
- `.devcontainer/additions/tests/` (validation tests)
- `website/docs/ai-developer/CREATING-SCRIPTS.md`
- `website/docs/contributors/scripts/install-scripts.md`
- `website/static/img/tools/` (new folder with all logos)
- ALL `install-*.sh`, `config-*.sh`, `service-*.sh` scripts

---

### PLAN-004: Enhanced Tool Pages
**Priority:** Medium
**Depends on:** PLAN-003
**Launchable after:** Yes - better tool documentation

**Scope:**
- Update `dev-docs.sh` to generate richer markdown tool pages with:
  - Logo display at top of page
  - "Quick Install" admonition boxes (:::tip)
  - Website links
  - Tags display
  - Abstract/longer description
  - Related tools section at bottom
- Regenerate all tool documentation with new format

**Files to modify:**
- `.devcontainer/manage/dev-docs.sh` (markdown generation)
- `website/docs/tools/` (regenerated output)

---

### PLAN-005: Interactive Homepage
**Priority:** Medium
**Depends on:** PLAN-003 (needs tools.json)
**Launchable after:** Yes - Dyte-inspired navigation

**Scope:**
- Create reusable card components:
  - `ItemCard` (generic card for tools/templates/packages)
  - `CategoryCard` (clickable category with count)
  - `UseCaseCard` (curated combinations)
- Create `ToolBrowser` component (filter by category)
- Redesign homepage with card-based sections:
  - Hero with 3 feature cards
  - "Get Started" section
  - Interactive tool browser
  - Use case cards

**Files to create:**
- `website/src/components/ItemCard/`
- `website/src/components/CategoryCard/`
- `website/src/components/ToolBrowser/`
- `website/src/pages/index.tsx` (update)

---

### PLAN-006: Analytics Setup
**Priority:** Low
**Depends on:** Nothing
**Launchable after:** Yes - tracking enabled

**Scope:**
- Set up Umami Cloud account (or self-hosted)
- Install `@dipakparmar/docusaurus-plugin-umami`
- Configure plugin (only active in production)
- Document analytics in contributor docs

**Files to modify:**
- `website/docusaurus.config.ts`
- `website/package.json`
- `website/docs/contributors/website.md`

---

### PLAN-007: Templates Integration
**Priority:** Medium (after tools are solid)
**Depends on:** PLAN-003, PLAN-005
**Launchable after:** Yes - templates documented alongside tools

**Scope:**
- Define TEMPLATE_* metadata format
- Merge templates from urbalurba-dev-templates
- Create `dev-templates.sh` to generate `templates.json`
- Add templates section to homepage
- Create template documentation pages

**Files to create/modify:**
- `templates/` folder (merged from external repo)
- `.devcontainer/manage/dev-templates.sh`
- `website/docs/templates/`
- Homepage components (add templates section)

---

### PLAN-008: Infrastructure Documentation
**Priority:** Low (separate repo integration)
**Depends on:** PLAN-005
**Launchable after:** Yes - infrastructure docs available

**Scope:**
- Set up build-time sync from urbalurba-infrastructure
- Configure multi-instance docs (separate sidebar)
- Add infrastructure section to homepage
- Create `packages.json` manifest in infrastructure repo

**Files to modify:**
- `.github/workflows/deploy-docs.yml` (fetch infra docs)
- `website/docusaurus.config.ts` (multi-instance docs)
- `website/sidebarsInfrastructure.ts` (new)
- Infrastructure repo: add `docs-manifest.json`

---

### PLAN-009: Branding & Polish
**Priority:** Low
**Depends on:** All above (final polish)
**Launchable after:** Yes - professional appearance

**Scope:**
- Design custom logo (replace Docusaurus default)
- Adjust color scheme (custom primary color)
- Custom social card image
- Improve footer with more links
- Add "Edit this page" links

**Files to modify:**
- `website/static/img/logo.svg`
- `website/src/css/custom.css`
- `website/static/img/social-card.png`
- `website/docusaurus.config.ts`

---

## Plan Dependencies

```
PLAN-001 (URLs) ────────────────────────────────────┐
       │                                            │
       ▼                                            │
PLAN-002 (Quick Enhancements)                       │
                                                    │
PLAN-003 (Extended Metadata) ───────┬───────────────┤
       │                            │               │
       ▼                            ▼               │
PLAN-004 (Tool Pages)        PLAN-005 (Homepage)    │
                                    │               │
                                    ▼               │
                             PLAN-007 (Templates)   │
                                    │               │
                                    ▼               │
                             PLAN-008 (Infrastructure)
                                                    │
PLAN-006 (Analytics) ───────────────────────────────┤
                                                    │
                                                    ▼
                                          PLAN-009 (Branding)
```

## Recommended Execution Order

| Order | Plan | Why |
|-------|------|-----|
| 1 | PLAN-001 | Critical - enables contributions |
| 2 | PLAN-002 | Quick wins, immediate value |
| 3 | PLAN-003 | Foundation for everything else |
| 4 | PLAN-004 | Better tool docs |
| 5 | PLAN-005 | Homepage transformation |
| 6 | PLAN-006 | Can do anytime |
| 7 | PLAN-007 | After tools are solid |
| 8 | PLAN-008 | After homepage done |
| 9 | PLAN-009 | Final polish |

**Parallel execution possible:**
- PLAN-002 + PLAN-003 (no dependencies between them)
- PLAN-006 (independent, can run anytime)

---

## Sources

- [Docusaurus Plugins](https://docusaurus.io/docs/api/plugins)
- [Community Plugin Directory](https://docusaurus.community/plugindirectory/)
- [Awesome Docusaurus](https://github.com/webbertakken/awesome-docusaurus)
- [Docusaurus Diagrams](https://docusaurus.io/docs/next/markdown-features/diagrams)
- [Docusaurus Showcase](https://docusaurus.io/showcase)
- [Umami Analytics](https://umami.is/)
- [Docusaurus Umami Plugin](https://github.com/dipakparmar/docusaurus-plugin-umami)
- [docusaurus-openapi-docs](https://github.com/PaloAltoNetworks/docusaurus-openapi-docs)
- [docusaurus-plugin-typedoc-api](https://github.com/milesj/docusaurus-plugin-typedoc-api)

---

## Next Steps

Create specific PLAN files in `backlog/` for implementation:

1. `PLAN-001-configurable-urls.md` - Environment variables for GitHub org/repo
2. `PLAN-002-quick-enhancements.md` - Version badge, Mermaid, image zoom
3. `PLAN-003-extended-metadata.md` - New script fields, validation, all tools
4. `PLAN-004-enhanced-tool-pages.md` - Richer markdown generation
5. `PLAN-005-interactive-homepage.md` - Card components, tool browser
6. `PLAN-006-analytics-setup.md` - Umami integration
7. `PLAN-007-templates-integration.md` - Merge templates repo
8. `PLAN-008-infrastructure-docs.md` - Cross-repo documentation
9. `PLAN-009-branding-polish.md` - Logo, colors, social card

