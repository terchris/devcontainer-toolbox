# Investigate: Container Image Retention Policy

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Automatically delete old container image versions from ghcr.io, keeping only the N most recent.

**Priority**: Low — no functional impact, but ghcr.io is growing indefinitely

**Last Updated**: 2026-04-08

---

## Problem

Every push to `main` that changes `version.txt`, `image/`, or `.devcontainer/` triggers a new image build and push to `ghcr.io/helpers-no/devcontainer-toolbox`. Both the versioned tag (e.g., `:1.7.31`) and `:latest` are pushed.

**Nothing is ever deleted.** As of 2026-04-08, the registry has all tags from `1.7.6` (March 18) through `1.7.31` — 26+ tagged versions, plus 169 total package versions including untagged manifest layers.

This will grow indefinitely. Each image is ~700MB so storage adds up over time.

## Goal

Keep only the 10 most recent versions on ghcr.io. Delete everything older automatically.

---

## Options

### Option 1: GitHub native package retention (UI)

Go to: `https://github.com/orgs/helpers-no/packages/container/devcontainer-toolbox/settings`

**What it offers:** Manual deletion, basic visibility settings.

**Limitation:** GitHub's UI does not have a "keep N most recent" policy. You can only manually delete versions one at a time. Not viable for automation.

### Option 2: Scheduled cleanup workflow (recommended)

Add a new GitHub Actions workflow that runs on a schedule (e.g., weekly) using [`actions/delete-package-versions@v5`](https://github.com/actions/delete-package-versions).

```yaml
name: Cleanup Old Image Versions
on:
  schedule:
    - cron: '0 3 * * 0'  # Sunday 3am UTC
  workflow_dispatch:

permissions:
  packages: write

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/delete-package-versions@v5
        with:
          package-name: 'devcontainer-toolbox'
          package-type: 'container'
          min-versions-to-keep: 10
          delete-only-untagged-versions: false
```

**Pros:**
- Standard approach used by many projects
- Decoupled from build workflow (build stays focused)
- Can be triggered manually for ad-hoc cleanup
- Configurable per package

**Cons:**
- One more workflow file to maintain
- Cleanup is delayed (weekly, not immediate)

### Option 3: Cleanup step in build-image.yml

Add the cleanup step at the end of `build-image.yml`. Runs on every image build.

**Pros:**
- Immediate cleanup after each build
- One workflow file

**Cons:**
- Couples build with cleanup (failures affect each other)
- Cleanup runs on every build even if nothing has changed

---

## Questions to Answer

1. **What does "10 most recent" mean?**
   - Last 10 by creation date?
   - Last 10 by version number?
   - The action uses creation date by default — likely fine since versions are monotonic.

2. **Should `:latest` be excluded from deletion?**
   - The action keeps tagged versions by default. `:latest` is a tag, so it's safe.
   - But: if `:latest` points to an old image (rare), it could get deleted. Need to verify the action's behavior.

3. **What about untagged manifest layers?**
   - Multi-arch builds create attestation manifests that have no tags
   - `delete-only-untagged-versions: true` would only clean these up (safer)
   - `delete-only-untagged-versions: false` cleans up tagged versions too (what we want)

4. **What about images currently in use?**
   - If a user is on `:1.7.20` and we delete it, can they still pull it?
   - Once deleted, no — they'd have to update to a newer version
   - 10 most recent ≈ ~10 days of versions at current bump rate, should be enough buffer

5. **Should we run a one-time manual cleanup first?**
   - Current state: 26+ tagged versions, 169 total package versions
   - First run of the workflow would delete ~16 tags + many untagged manifests
   - May want to verify the dry-run output before letting it run

---

## Recommendation

**Option 2** — scheduled cleanup workflow with `min-versions-to-keep: 10`. Run weekly on Sunday 3am UTC. Test with `workflow_dispatch` first to verify the right versions get deleted.

---

## Next Steps

- [ ] Verify `actions/delete-package-versions@v5` is the latest version
- [ ] Verify how the action handles `:latest` tag (does it preserve it?)
- [ ] Create `.github/workflows/cleanup-images.yml` with `min-versions-to-keep: 10`
- [ ] Run manually first via `workflow_dispatch` to verify dry-run output
- [ ] After verification, enable scheduled run
- [ ] Document in `ci-pipeline.md` (will then be 4 workflows again)
