# Feature: Domain, Branding, Mission Alignment & Blog

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Launch DevContainer Toolbox (DCT) at dct.sovereignsky.no with original branding, aligned with SovereignSky's digital sovereignty mission, and a blog for content.

**Last Updated**: 2026-01-17

**Prerequisites**: PLAN-004 complete (tool display components)

---

## Overview

DevContainer Toolbox will be hosted at **dct.sovereignsky.no** as part of the SovereignSky initiative for Norwegian digital sovereignty. The site needs:

1. **Custom domain** - dct.sovereignsky.no
2. **Original branding** - logo, colors, social card (not copying SovereignSky, which has no branding yet)
3. **Mission alignment** - messaging that connects to sovereignty themes
4. **Blog** - for tutorials, announcements, and sovereignty topics

### Context: SovereignSky

[sovereignsky.no](http://sovereignsky.no) is a digital sovereignty resource hub for Norway, created by [helpers.no](https://helpers.no). It addresses the critical dependency of Norwegian digital infrastructure on foreign cloud services (subject to US CLOUD Act).

**DevContainer Toolbox's role**: Provide developers with open-source, locally-runnable, privacy-respecting development environments - reducing dependency on cloud-based dev tools.

**Reference**: SovereignSky site at `/Users/terje.christensen/learn/projects-2025/sovereignsky-site`

---

## Phase 1: Custom Domain Setup

### Tasks

- [ ] 1.1 Create `website/static/CNAME` file with `dct.sovereignsky.no`
- [ ] 1.2 Update `website/docusaurus.config.ts`:
  - Set `url: 'https://dct.sovereignsky.no'`
  - Set `baseUrl: '/'`
- [ ] 1.3 Update GitHub repository settings (manual step - document for user):
  - Settings → Pages → Custom domain: `dct.sovereignsky.no`
- [ ] 1.4 Document DNS setup for user:
  - CNAME record: `dct.sovereignsky.no` → `<github-username>.github.io`
- [ ] 1.5 Update `README.md` with new domain
- [ ] 1.6 Test locally that build works with new config

### Validation

User confirms:
- Build succeeds locally
- DNS instructions are clear
- Ready to configure DNS when going live

---

## Phase 2: Branding — ✅ DONE

### Image Creation Workflow

Using Gemini (gemini.google.com/app) for AI-generated images:
1. Claude proposes image prompt
2. User confirms/adjusts the prompt
3. Claude uses Chrome to submit prompt to Gemini
4. Claude downloads the generated image
5. Claude analyzes the image and advises on suitability
6. Repeat until satisfied

### Tasks

- [x] 2.1 Create logo for DevContainer Toolbox:
  - Should convey: development tools, containers, independence/sovereignty
  - Simple, works at small sizes (favicon)
  - Used Gemini to generate reference (gemini-logo.png)
  - Created logo.svg based on reference (needs human refinement)
- [x] 2.2 Save logo as `website/static/img/logo.svg` (convert if needed)
  - Created SVG with shield, cube, and code brackets
  - **TODO**: Human designer to refine logo.svg to match gemini-logo.png
- [x] 2.3 Create favicon from logo
  - Generated multi-size favicon.ico from logo.svg using ImageMagick
- [x] 2.7 Create branding documentation page
  - Added `website/docs/contributors/branding.md` with:
    - Logo files and usage guidelines
    - Commands to generate assets from SVG
    - Color palette documentation
    - Reference goal (gemini-logo.png) vs current (logo.svg)
- [x] 2.4 Define color scheme in `website/src/css/custom.css`:
  - Primary: Green #3a8f5e (from logo cube) for light mode
  - Primary: Bright green #25c2a0 for dark mode (better readability)
  - Secondary: Navy blue #1e3a5f (from logo shield)
  - Added documentation comments referencing branding page
- [x] 2.5 Create social card image `website/static/img/social-card.png`:
  - Generated 1424x752px image using Gemini (Option 3: Abstract geometric)
  - Navy blue background with green isometric cubes
  - "DevContainer Toolbox" title and tagline
  - Dev tool icons (gears, code brackets, terminal)
- [x] 2.6 Update `docusaurus.config.ts` with logo and social card paths
  - Logo path updated to logo.svg ✓
  - Social card updated to social-card.png ✓

### Validation

User confirms:
- Logo looks good
- Colors work in light and dark mode
- Social card conveys the right message

---

## Phase 3: Mission Alignment

### Tasks

- [ ] 3.1 Create `website/src/pages/about.md` with:
  - What is DevContainer Toolbox
  - Connection to digital sovereignty
  - Why local, open-source dev tools matter
  - Link to sovereignsky.no for broader context
- [ ] 3.2 Update homepage feature descriptions to emphasize sovereignty:
  - "Works Everywhere" → emphasize: runs locally, no cloud required
  - "Open Source" → emphasize: transparency, no vendor lock-in
  - "AI-Ready" → emphasize: AI tools where data stays on your machine
- [ ] 3.3 Update footer in `docusaurus.config.ts`:
  - Add link to sovereignsky.no
  - Add link to helpers.no
  - Keep GitHub link
- [ ] 3.4 Add "Edit this page" links to docs (Docusaurus config)

### Validation

User confirms:
- About page clearly explains the mission
- Homepage messaging aligns with sovereignty themes
- Footer links are correct

---

## Phase 4: Blog Setup

### Tasks

- [ ] 4.1 Enable blog in `docusaurus.config.ts`:
  ```js
  blog: {
    showReadingTime: true,
    blogTitle: 'DevContainer Toolbox Blog',
    blogDescription: 'Sovereign development tools for Norwegian digital resilience',
    postsPerPage: 10,
    blogSidebarTitle: 'Recent posts',
    blogSidebarCount: 5,
  },
  ```
- [ ] 4.2 Create `website/blog/` folder
- [ ] 4.3 Create `website/blog/authors.yml` with author info
- [ ] 4.4 Write first blog post: "Why DevContainer Toolbox Exists"
  - The sovereignty angle
  - Dev tools that work offline, locally, independently
  - Connection to Totalforsvarsaret 2026
- [ ] 4.5 Add Blog to navbar in `docusaurus.config.ts`
- [ ] 4.6 Test blog functionality locally

### Validation

User confirms:
- Blog appears in navbar
- First blog post renders correctly
- Blog sidebar shows recent posts

---

## Phase 5: Final Integration & Testing

### Tasks

- [ ] 5.1 Test full site locally:
  - All pages load
  - Logo displays correctly
  - Colors work in light/dark mode
  - Blog works
  - About page accessible
  - Footer links work
- [ ] 5.2 Check responsive design (mobile)
- [ ] 5.3 Verify social card preview (use social card validator tools)
- [ ] 5.4 Update SovereignSky projects page to link to dct.sovereignsky.no (coordinate with sovereignsky repo)
- [ ] 5.5 Commit all changes
- [ ] 5.6 Push and create PR

### Validation

User confirms:
- Site looks good locally
- Ready to go live
- DNS can be configured

---

## Acceptance Criteria

- [ ] Site builds and deploys to dct.sovereignsky.no
- [ ] Custom logo and branding applied
- [ ] About page explains sovereignty mission
- [ ] Blog is functional with first post
- [ ] Footer links to SovereignSky and helpers.no
- [ ] Social card displays correctly when shared
- [ ] Works in both light and dark mode

---

## Files to Create

- `website/static/CNAME` - Custom domain
- `website/static/img/logo.svg` - Logo
- `website/static/img/social-card.png` - Social sharing image
- `website/src/pages/about.md` - About/mission page
- `website/blog/authors.yml` - Blog author info
- `website/blog/2026-01-xx-why-devcontainer-toolbox.md` - First blog post

## Files to Modify

- `website/docusaurus.config.ts` - Domain, blog, navbar, footer, logos
- `website/src/css/custom.css` - Brand colors
- `website/src/components/HomepageFeatures/index.tsx` - Update messaging
- `README.md` - Update with new domain

---

## Implementation Notes

### Logo Ideas

Consider these concepts for the logo:
- Container/box shape (represents DevContainer)
- Tool or wrench element (represents toolbox)
- Abstract "independence" symbol
- Simple, recognizable at small sizes

### Color Scheme Ideas

| Color | Meaning | Use |
|-------|---------|-----|
| Deep blue | Trust, reliability, stability | Primary |
| Teal/cyan | Independence, technology | Accent |
| Green | Growth, open source | Success states |

### Blog Post Categories

Use tags for categorization:
- `release` - Version announcements
- `tutorial` - How-to guides
- `sovereignty` - Digital sovereignty topics
- `tools` - Deep dives on specific tools

### First Blog Post Outline

**Title**: "Why DevContainer Toolbox Exists: Sovereign Development for Norway"

1. The problem: Norwegian dev teams depend on US cloud services
2. What happens if access is cut off?
3. DevContainer Toolbox: local-first, open-source dev environments
4. Connection to Totalforsvarsaret 2026
5. How to get started
