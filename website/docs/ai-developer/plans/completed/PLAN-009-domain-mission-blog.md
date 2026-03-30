# Feature: Domain, Branding, Mission Alignment & Blog

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed ✅

**Goal**: Launch DevContainer Toolbox (DCT) at dct.sovereignsky.no with original branding, aligned with SovereignSky's digital sovereignty mission, and a blog for content.

**Last Updated**: 2026-01-18

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

---

## Phase 1: Custom Domain Setup — ✅ DONE

### Tasks

- [x] 1.1 Create `website/static/CNAME` file with `dct.sovereignsky.no`
- [x] 1.2 Update `website/docusaurus.config.ts`:
  - Set `url: 'https://dct.sovereignsky.no'`
  - Set `baseUrl: '/'`
- [x] 1.3 Update all hardcoded URLs (17 occurrences in README files and docs)
- [x] 1.4 Configure GitHub Pages custom domain setting
- [x] 1.5 Fix CI workflow to use correct file paths (index.mdx not index.md)

### Manual Steps Required (for user)

**DNS Configuration (at your DNS provider for sovereignsky.no):**
```
Type: CNAME
Name: dct
Value: terchris.github.io
```

**GitHub Repository Settings:**
1. Go to repository Settings → Pages
2. Under "Custom domain", enter: `dct.sovereignsky.no`
3. Check "Enforce HTTPS" (after DNS propagates)

---

## Phase 2: Branding — ✅ DONE

### Tasks

- [x] 2.1 Create logo for DevContainer Toolbox (logo.svg with shield, cube, code brackets)
- [x] 2.2 Save logo as `website/static/img/logo.svg`
- [x] 2.3 Create favicon from logo (multi-size favicon.ico)
- [x] 2.4 Define color scheme in `website/src/css/custom.css`:
  - Primary: Green #3a8f5e (light mode), #25c2a0 (dark mode)
  - Secondary: Navy blue #1e3a5f
- [x] 2.5 Create social card image `website/static/img/social-card.jpg`
- [x] 2.6 Update `docusaurus.config.ts` with logo and social card paths
- [x] 2.7 Create branding documentation page (`website/docs/contributors/branding.md`)

---

## Phase 3: Mission Alignment — ✅ DONE

### Tasks

- [x] 3.1 Create About page (`website/docs/about.md`) with sovereignty mission
- [x] 3.2 Homepage features already emphasize local/open-source benefits
- [x] 3.3 Update footer with SovereignSky section and links
- [x] 3.4 "Edit this page" links configured via editUrl

---

## Phase 4: Blog Setup — ✅ DONE

### Tasks

- [x] 4.1 Enable blog in `docusaurus.config.ts`
- [x] 4.2 Create `website/blog/` folder with folder-based structure
- [x] 4.3 Create `website/blog/authors.yml` with author info
- [x] 4.4 Write first blog post: "Why DevContainer Toolbox Exists"
- [x] 4.5 Write second blog post: "You Hold the Keys to National Sovereignty"
- [x] 4.6 Add Blog to navbar in `docusaurus.config.ts`
- [x] 4.7 Test blog functionality on live site

---

## Phase 5: Final Integration & Testing — ✅ DONE

### Tasks

- [x] 5.1 Test full site on live domain (dct.sovereignsky.no):
  - All pages load ✓
  - Logo displays correctly ✓
  - Colors work in light/dark mode ✓
  - Blog works with both posts ✓
  - About page accessible in sidebar ✓
  - Footer links work ✓
- [x] 5.2 Check responsive design (mobile) - hamburger menu, stacked layout works
- [x] 5.3 Verify social card preview - OG tags configured, image loads (1408×752)
- [x] 5.4 Fix AI demo GIF path (was hardcoded to old baseUrl)
- [x] 5.5 All changes committed and merged via PRs

---

## Acceptance Criteria

- [x] Site builds and deploys to dct.sovereignsky.no
- [x] Custom logo and branding applied
- [x] About page explains sovereignty mission
- [x] Blog is functional with two posts
- [x] Footer links to SovereignSky and helpers.no
- [x] Social card displays correctly when shared
- [x] Works in both light and dark mode

---

## Pull Requests

- PR #21: Initial domain, branding, mission, and blog setup
- PR #22: Fix CI workflow file paths (index.mdx)
- PR #23: Fix AI demo GIF path using useBaseUrl

---

## Files Created

- `website/static/CNAME` - Custom domain
- `website/static/img/logo.svg` - Logo
- `website/static/img/social-card.jpg` - Social sharing image
- `website/docs/about.md` - About/mission page
- `website/blog/authors.yml` - Blog author info
- `website/blog/2026-01-18-why-devcontainer-toolbox-exists/` - First blog post
- `website/blog/2026-01-15-developer-power-sovereignty/` - Second blog post
- `website/docs/contributors/branding.md` - Branding guidelines

## Files Modified

- `website/docusaurus.config.ts` - Domain, blog, navbar, footer, logos
- `website/src/css/custom.css` - Brand colors, footer styling
- `website/src/components/AiDemo/index.tsx` - Fixed GIF path
- `.github/workflows/ci-tests.yml` - Fixed documentation file paths
- Multiple README files - Updated URLs to dct.sovereignsky.no
