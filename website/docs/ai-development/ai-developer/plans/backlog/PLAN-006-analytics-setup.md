# Feature: Analytics Setup (Umami)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Draft (Definition Incomplete)

**Goal**: Add privacy-friendly analytics to track website usage without cookies or GDPR concerns.

**Last Updated**: 2026-01-17

**Prerequisites**: None (can be done anytime)

**Priority**: Future (requires account setup decision)

---

## Overview

Add analytics to understand how users interact with the DevContainer Toolbox website. Using Umami instead of Google Analytics because:

- No cookies = no cookie banner needed
- GDPR compliant out of the box
- Lightweight (~2KB script)
- Privacy-respecting (aligns with sovereignty mission)
- You own the data

### Why Umami Over Google Analytics

| Feature | Umami | Google Analytics |
|---------|-------|------------------|
| Cookies | None | Required |
| GDPR | Compliant by default | Requires consent banner |
| Script size | ~2KB | ~45KB |
| Data ownership | You own it | Google owns it |
| Privacy | Privacy-first | Tracking-first |
| Cost | Free (self-hosted) or $9/mo | Free (but you're the product) |

---

## Definition Tasks (To Complete Before Implementation)

- [ ] Decide: Umami Cloud ($9/mo) or self-hosted (free)?
- [ ] If self-hosted: where to host? (Docker on existing server?)
- [ ] Create Umami account/instance
- [ ] Get tracking script/site ID
- [ ] Decide what metrics matter most
- [ ] Consider: should analytics be mentioned on the site? (transparency)

---

## Hosting Options

### Option A: Umami Cloud (Recommended for simplicity)

**Cost**: $9/month (Hobby plan)
**URL**: https://umami.is/

**Pros:**
- No infrastructure to manage
- Automatic updates
- Reliable uptime

**Cons:**
- Monthly cost
- Data on Umami's servers (but privacy-respecting)

### Option B: Self-Hosted

**Cost**: Free (but need a server)
**Requirements**: Docker, PostgreSQL or MySQL

**Pros:**
- Free
- Full data ownership
- Can customize

**Cons:**
- Need to maintain server
- Updates are manual
- Need monitoring

### Option C: Self-Hosted on Existing Infrastructure

If urbalurba-infrastructure already has hosting, Umami could run there.

**Pros:**
- Uses existing resources
- Integrated with other services

**Cons:**
- Dependency on infrastructure repo
- May complicate deployment

---

## Proposed Implementation

### Docusaurus Plugin

Use `@dipakparmar/docusaurus-plugin-umami`:

```bash
npm install @dipakparmar/docusaurus-plugin-umami
```

```js
// docusaurus.config.ts
plugins: [
  [
    '@dipakparmar/docusaurus-plugin-umami',
    {
      websiteID: 'your-website-id',
      analyticsDomain: 'analytics.example.com', // or cloud.umami.is
      dataHostURL: 'https://analytics.example.com',
      // Only active in production
    },
  ],
],
```

### Key Metrics to Track

| Metric | Why |
|--------|-----|
| Page views | Which docs are most used |
| Tool page visits | Which tools are popular |
| Blog post reads | Content engagement |
| Referrers | How users find us |
| Countries | Geographic distribution |
| Devices | Mobile vs desktop |

---

## Proposed Phases (Draft)

### Phase 1: Account Setup
- Decide on hosting option
- Create Umami account/instance
- Get website ID and tracking domain

### Phase 2: Plugin Installation
- Install `@dipakparmar/docusaurus-plugin-umami`
- Configure with website ID
- Test locally (should not track in dev)

### Phase 3: Deployment & Verification
- Deploy to production
- Verify tracking works
- Check dashboard shows data

### Phase 4: Documentation
- Document analytics setup for contributors
- (Optional) Add privacy note to website footer

---

## Acceptance Criteria (Draft)

- [ ] Analytics tracking active in production
- [ ] No cookies or consent banner required
- [ ] Dashboard accessible to view metrics
- [ ] Only tracks production (not localhost)
- [ ] Documented in contributor docs

---

## Files to Modify (Estimated)

- `website/package.json` - Add Umami plugin
- `website/docusaurus.config.ts` - Plugin configuration
- `website/docs/contributors/website.md` - Document analytics

---

## Open Questions

1. Umami Cloud or self-hosted?
2. Who should have access to the analytics dashboard?
3. Should we mention analytics in the site footer? (transparency)
4. What's the budget for hosted services?
5. If self-hosted, where does it run?

---

## Cost Comparison

| Option | Monthly Cost | Annual Cost |
|--------|--------------|-------------|
| Umami Cloud (Hobby) | $9 | $108 |
| Self-hosted | $0 + server costs | Varies |
| Google Analytics | $0 | $0 (but privacy cost) |

---

## Reference

- [Umami](https://umami.is/) - Official site
- [Umami Cloud Pricing](https://umami.is/pricing)
- [Docusaurus Umami Plugin](https://github.com/dipakparmar/docusaurus-plugin-umami)
- INVESTIGATE-docusaurus-enhancements.md - "Analytics - Umami" section
