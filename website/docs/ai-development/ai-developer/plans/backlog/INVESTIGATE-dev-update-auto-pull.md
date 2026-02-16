# Investigate: Script-level updates without full container rebuilds

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Enable updating toolbox scripts inside a running container without rebuilding the image.

**GitHub Issues**: #54 (supersedes #45)

**Last Updated**: 2026-02-16

---

## Summary of Issue #54

Issue #54 introduces two distinct concepts:

| Concept | What changes | Command | Rebuild? | Version |
|---------|-------------|---------|----------|---------|
| **Script sync** | Script fixes, new tools, commands | `dev-sync` | No | `tools.json` version (auto) |
| **Container update** | Base image, OS packages, runtimes | `dev-update` | Yes | `version.txt` (manual) |

The issue describes 4 main components:
1. **`dev-sync` command** — downloads updated scripts from GitHub without rebuilding
2. **Version numbers in `tools.json`** — top-level version + per-tool `SCRIPT_VER`
3. **Pre-commit hook** — auto-bumps `SCRIPT_VER` patch version on commit
4. **Auto-sync on container start** — runs `dev-sync` during startup

Plus supporting work:
- CI/CD pipeline to generate and publish script bundles
- Symlink management for new/removed `dev-*` commands
- Atomic replacement with rollback
- Website documentation showing tool versions

---

## Current State

### What exists

- `dev-update.sh` — checks `version.txt` against GitHub, shows manual `docker pull` instructions
- `generate-tools-json.sh` — generates `tools.json` from script metadata at build time
- `tools.json` — has `generated` timestamp but no version field
- Every install script has `SCRIPT_VER` — but it's not extracted into `tools.json`
- `extract_var()` in the generator already handles `SCRIPT_VER`-style fields

### What's missing

- No `dev-sync` command
- No top-level version in `tools.json`
- No per-tool version in `tools.json` (despite `SCRIPT_VER` existing in every script)
- No pre-commit hook for auto-bumping
- No CI/CD pipeline for script bundles
- No `scripts-version.txt` on GitHub for quick version check

---

## Phased Approach

This is a large feature. I recommend breaking it into phases that each deliver value independently:

### Phase 1: Foundation — Pre-commit hook + tools.json versions

**No CI/CD changes needed. Can be done now.**

1. Add `.githooks/pre-commit` (hook code provided in issue #54)
2. Add `SCRIPT_VER` extraction to `generate-tools-json.sh`
3. Add top-level `"version"` field to `tools.json`
4. Document `git config core.hooksPath .githooks` in contributor docs

**Value**: Every script change gets a version bump. `tools.json` tracks versions. Foundation for everything else.

### Phase 2: CI/CD — Bundle generation pipeline

**Requires GitHub Actions workflow.**

1. Create workflow that runs on push to `main`
2. Runs `generate-tools-json.sh` to build `tools.json` with versions
3. Compares against previous `tools.json` to detect changes
4. If changed: bumps top-level version, creates tar.gz bundle, publishes as GitHub release
5. Creates `scripts-version.txt` as a lightweight version check file

**Value**: Script bundles are available for `dev-sync` to download.

### Phase 3: `dev-sync` command

**Requires Phase 2 (needs bundles to exist).**

1. Create `dev-sync.sh` in `manage/`
2. Fetch `scripts-version.txt` from GitHub
3. Compare with local `tools.json` version
4. If newer: download bundle, extract to temp, atomic swap
5. Create/remove symlinks for new/removed `dev-*` commands
6. Report what changed (per-tool version diffs)
7. Handle edge cases (offline, self-update, permissions)

**Value**: Users can update scripts without rebuilding.

### Phase 4: Auto-sync on startup

**Requires Phase 3.**

1. Add `dev-sync --quiet` to entrypoint or `postStartCommand`
2. Cache sync status to `/tmp/devcontainer-toolbox-sync-status`
3. Handle offline gracefully (skip silently)
4. Show notifications in `dev-help`/`dev-setup` if sync failed

**Value**: Scripts are always up-to-date automatically.

### Phase 5: Website documentation

**Can be done anytime after Phase 1.**

1. Update website generator to include `version` field from `tools.json`
2. Show version on tool detail pages

**Value**: Users can see which version of each tool is documented.

---

## Recommendation

**Start with Phase 1** — it's self-contained, delivers value immediately, and is the foundation for all other phases. The pre-commit hook and tools.json version fields can be implemented and merged independently.

Phases 2-4 are more complex and involve CI/CD pipeline work. They should be planned as separate issues/PRs.

Phase 5 is a small documentation improvement that can be done anytime.

---

## What to implement now

For this session, I recommend implementing **Phase 1 only**:

1. `.githooks/pre-commit` — auto-bump hook (code provided in issue)
2. `generate-tools-json.sh` — add `SCRIPT_VER` extraction + top-level version
3. Contributor documentation update

This gives us the version infrastructure that all future phases build on, without needing CI/CD changes or new commands.

---

## Next Steps

- [ ] Create `PLAN-dev-sync-foundation.md` for Phase 1
- [ ] Future: Create separate plans/issues for Phases 2-5
