# Investigate: Script-level updates without full container rebuilds

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

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

## Investigation: Distribution Method for Phase 2-3

### Context

- Scripts live in `.devcontainer/additions/` (44 files, 1.3MB) and `.devcontainer/manage/` (332K)
- Total ~1.6MB of shell scripts
- Container mounts these at `/opt/devcontainer-toolbox/`
- Current GitHub release already has a `dev_containers.zip` asset (423KB)
- `dev-sync` needs to: check version, download scripts, replace atomically
- Containers have `curl`, `git`, `tar`, `unzip` available

### Option A: tar.gz bundle via GitHub Releases

**How it works:** CI creates a tar.gz of `additions/` + `manage/`, attaches to GitHub release. `dev-sync` downloads and extracts.

| Pro | Con |
|-----|-----|
| Single download, atomic swap | Requires CI workflow to create bundles |
| Works offline after download | Downloads everything even for 1-file change |
| Simple: curl + tar | Need to manage release assets |
| Can pin to specific version | Extra release artifact to maintain |

### Option B: GitHub raw file download (git archive)

**How it works:** `dev-sync` uses `git archive --remote` or GitHub API to download just the `.devcontainer/` tree as a tarball.

| Pro | Con |
|-----|-----|
| Always latest from main | GitHub doesn't support `git archive --remote` |
| No CI workflow needed | GitHub API tarball includes entire repo |
| No release management | Must filter to just `.devcontainer/` locally |
| Simple infrastructure | Rate-limited (60 req/hr unauthenticated) |

### Option C: GitHub API — download individual changed files

**How it works:** `dev-sync` fetches `tools.json` to find changed versions, then downloads only the changed files via GitHub raw content API.

| Pro | Con |
|-----|-----|
| Minimal bandwidth | Many HTTP requests for multiple changes |
| Surgical updates | Complex diff/merge logic |
| No CI changes needed | Rate-limited (60 req/hr unauthenticated) |
| | Hard to handle deleted/renamed files |
| | No atomicity — partial update risk |

### Option D: Reuse existing zip release asset

**How it works:** The `build-image.yml` workflow already creates `dev_containers.zip`. `dev-sync` downloads this existing asset.

| Pro | Con |
|-----|-----|
| **Already exists** — no new CI work | Zip contains entire .devcontainer/ tree |
| Same asset users download for install | ~423KB (acceptable size) |
| Versioned via GitHub releases | Includes Dockerfile, configs not needed for sync |
| `unzip` is available in container | Need to filter to just additions/ + manage/ |

### Option E: Lightweight version file + tar.gz (hybrid)

**How it works:** CI publishes a tiny `scripts-version.txt` to a known URL (GitHub Pages or release). `dev-sync` checks this first (1 HTTP request). Only downloads the bundle if version differs.

| Pro | Con |
|-----|-----|
| Fast version check (< 1KB) | Two-step process |
| Bundle only downloaded when needed | Requires version file to be published |
| Works with either tar.gz or zip | |
| Minimal bandwidth for "no update" case | |

### Comparison Matrix

| Criteria | A: tar.gz | B: git archive | C: individual files | D: existing zip | E: hybrid |
|----------|-----------|----------------|-------------------|----------------|-----------|
| CI work needed | Medium | None | None | **None** | Low |
| Download size | ~200KB | ~full repo | Variable | 423KB | ~200KB |
| Atomicity | Yes | Yes | No | Yes | Yes |
| Bandwidth efficient | Medium | Poor | Best case good | Medium | **Best** |
| Complexity | Low | Medium | High | **Lowest** | Low |
| Offline support | Yes | No | No | Yes | Yes |
| Rate limit risk | None | Medium | High | None | None |

### Recommendation

**Option D+E hybrid**: Use the existing `dev_containers.zip` release asset with a lightweight version check.

1. **Version check**: `dev-sync` fetches `version.txt` from GitHub raw content (1 small request, already works in `dev-update.sh`)
2. **Download**: If version differs, download `dev_containers.zip` from the latest GitHub release (already generated by CI)
3. **Extract**: Unzip to temp, copy `additions/` + `manage/` atomically
4. **No new CI workflow needed** — piggyback on the existing release pipeline

This avoids building a new CI pipeline entirely. The existing `build-image.yml` already creates the zip. We just need `dev-sync` to consume it.

**The only addition to CI**: publish a `scripts-version.txt` alongside the zip (a one-line file containing the version from `tools.json`). This is a minor change to the existing workflow.

---

## Progress

- [x] **Phase 1**: Pre-commit hook + tools.json versions — ✅ DONE (PLAN-dev-sync-foundation, PR #55)
- [x] **Phase 5**: Website shows tool versions — ✅ DONE (version column on tool detail pages)
- [x] **Phase 2**: CI/CD — scripts-version.txt generation — ✅ DONE (PLAN-dev-sync-command, Phase 1)
- [x] **Phase 3**: `dev-sync` command — ✅ DONE (PLAN-dev-sync-command, Phase 2)
- [x] **Phase 4**: Auto-sync on startup — ✅ DONE (PLAN-dev-sync-command, Phase 3)

## Next Steps

All phases complete. See `PLAN-dev-sync-command.md` for the full implementation.
