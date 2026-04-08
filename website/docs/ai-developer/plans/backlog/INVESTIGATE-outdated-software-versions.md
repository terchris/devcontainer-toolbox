# Investigate: Outdated Software Versions in DCT Base Image

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Audit all software in the DCT base image (`image/Dockerfile`), identify outdated versions, assess upgrade risks, and create a plan to bring everything current.

**Priority**: Medium — no security incidents, but several components are significantly behind

**Last Updated**: 2026-04-06

---

## Current State (v1.7.16, image built 2026-04-05)

Base image: `mcr.microsoft.com/devcontainers/base:bookworm` (Debian 12)

### Version Audit

| Software | DCT Version | Latest Stable | Gap | Installed Via | Risk |
|----------|------------|---------------|-----|--------------|------|
| **Node.js** | 22.12.0 | 22.22.2 (Jod LTS) | 10 minor versions | Dockerfile (binary download) | Medium — security patches, npm compat |
| **npm** | 10.9.0 | (bundled with Node) | — | Bundled with Node | Updates with Node |
| **Debian** | 12 (Bookworm) | 13 (Trixie) available | 1 major | Base image | Low — Bookworm supported until 2028 |
| **git** | 2.50.1 | 2.53.0 | 3 minor | apt (Debian repos) | Low — apt-managed |
| **curl** | 7.88.1 | 8.19.0 | 1 major | apt (Debian repos) | Medium — major version behind, security patches |
| **jq** | 1.6 | 1.8.1 | 2 minor | apt (Debian repos) | Low — 1.7+ has useful features but 1.6 works |
| **Python** | 3.12.11 | 3.14.3 / 3.13.12 | — | Base image | Low — 3.12 is supported LTS |
| **pip** | 25.0.1 | (check at update time) | — | Python bundled | Low |
| **GitHub CLI (gh)** | 2.89.0 | 2.89.0 | Current | apt (GitHub repos) | None — up to date |
| **supervisord** | 4.2.5 | 4.2.5 | Current | apt | None — up to date |
| **wget** | 1.21.3 | (Debian-managed) | — | apt | Low |

### Not in Base Image (installed by user via dev-setup)

These are install scripts in `.devcontainer/additions/` — each manages its own version. Not covered here, but should be audited separately:
- Hugo, kubectl, k3d, Helm, Go, etc.
- Each `install-tool-*.sh` script downloads a specific version or latest

---

## Priority Assessment

### High Priority — Update in Dockerfile

1. **Node.js 22.12.0 → 22.22.2**
   - Installed via binary download in Dockerfile — version is hardcoded
   - 10 minor versions behind on the LTS line
   - Contains security patches and npm compatibility fixes
   - **Risk of update**: Low — same major version, same LTS line
   - **Change**: Update the download URL version string in `image/Dockerfile`

### Medium Priority — Consider

2. **jq 1.6 → 1.7+**
   - Installed via apt — Debian Bookworm ships 1.6
   - jq 1.7+ adds `env`, `debug/2`, `scan` improvements
   - **Option A**: Install from GitHub releases instead of apt (like Node)
   - **Option B**: Wait for Debian Trixie base image
   - **Risk of update**: Low if installing from release binary

3. **curl 7.x → 8.x**
   - Installed via apt — tied to Debian Bookworm
   - Major version behind, but Debian backports security patches
   - **Risk of update**: Medium — curl 8.x could have behavior changes
   - **Recommendation**: Leave as-is until Debian base image update

### Low Priority — No Action Needed

4. **Debian 12 → 13**: Bookworm is supported until 2028. The base image (`mcr.microsoft.com/devcontainers/base:bookworm`) is maintained by Microsoft. Monitor for `base:trixie` availability.

5. **Python 3.12**: Current supported LTS. No need to jump to 3.13/3.14 unless user templates require it.

6. **git 2.50.1**: Managed by apt, receives Debian security backports. 2.53.0 has no critical features DCT needs.

7. **gh 2.89.0**: Already current.

8. **supervisord 4.2.5**: Already current.

---

## Install Scripts Audit (`.devcontainer/additions/`)

These scripts are run by users via `dev-setup`. Each manages its own software version.

### Pinned Versions (10 scripts with hardcoded defaults)

| Script | Software | DCT Default | Latest | Gap | Notes |
|--------|----------|-------------|--------|-----|-------|
| `install-fwk-hugo.sh` | Hugo Extended | 0.157.0 | 0.160.0 | 3 minor | Overridable with `--version` |
| `install-dev-golang.sh` | Go | 1.21.0 | 1.26.1 | **5 major** | Very outdated (Aug 2023) |
| `install-dev-java.sh` | OpenJDK | 17 | 17 (LTS) | Current | Major-version pin, latest patch via apt |
| `install-dev-php-laravel.sh` | PHP | 8.4 | 8.4 | Current | Latest patch via Herd-lite |
| `install-dev-csharp.sh` | .NET SDK | 8.0 | 10.0 | **2 major** | 8.0 is LTS (supported until Nov 2026) |
| `install-tool-powershell.sh` | PowerShell | 7.5.4 | 7.6.0 | 1 minor | Comment: "Oct 2025" |
| `install-tool-azure-ops.sh` | PowerShell | 7.5.4 | 7.6.0 | 1 minor | Duplicate pin with above |
| `install-srv-otel-monitoring.sh` | OTel Collector | 0.140.1 | 0.149.0 | 9 minor | Comment: "Nov 2025" |
| `install-srv-otel-monitoring.sh` | script_exporter | 3.1.0 | 3.2.0 | 1 minor | Comment: "Jan 2025" |
| `otel/scripts/send-event-notification.sh` | OTel Collector | 0.113.0 | 0.149.0 | **36 minor** | Inconsistent with main OTel pin |

### Dynamic/Latest Versions (~20 scripts, no pinned default)

These download latest at install time: Rust (rustup), TypeScript (npm), Python (pip), kubectl (stable.txt), k9s (GitHub API), bash/cpp/imagetools/fortran (apt), api-dev, azure-dev/devops, dataanalytics, databricks, dev-utils, iac, okta, powerplatform, claude-code.

---

## Pinned vs Unpinned — Decision Framework

7 of 28 install scripts pin a `DEFAULT_VERSION`. The rest install "latest" at runtime. This split is intentional but undocumented. Here's the trade-off:

### When to pin (use `DEFAULT_VERSION`)

- **Languages and runtimes** (Go, Java, .NET, PHP, Node.js) — version affects code compatibility. A surprise major bump can break user projects.
- **Frameworks with theme/plugin compat** (Hugo) — a minor bump can break existing themes.
- **Infrastructure tools with config format changes** (OTel Collector) — config YAML schema can change between versions.
- **Anything we've tested** and want to guarantee works in DCT.

### When NOT to pin (install latest)

- **Utilities and CLI tools** (shellcheck, jq, curl) — latest is almost always fine, breaking changes are rare.
- **Package-managed tools** (apt, npm, pip installs) — the package manager handles compatibility.
- **Tools where version doesn't affect user code** (linters, formatters, dev-utils).

### The maintenance cost of pinning

Every pinned version becomes a maintenance liability. Without automated tooling:
- Pins go stale silently (our Go 1.21 sat for 3 years)
- Users get outdated software and assume it's current
- Manual audits don't scale as we add more scripts

**Rule: if you pin it, you must have a process to update it.** Renovate Bot solves this — it creates PRs automatically when pinned versions fall behind. Without Renovate (or equivalent), unpinned is safer than stale-pinned.

### DCT Pinning Rules (proposed)

**Rule 1: Pin if the version affects user code compatibility.**
Languages, runtimes, SDKs, and frameworks. A version change can break builds, imports, or APIs.
→ Pin: Go, Java, .NET, PHP, Node.js, Hugo, Python (base image)
→ Don't pin: shellcheck, jq, curl, wget, git

**Rule 2: Pin if config format changes between versions.**
Tools where the user writes config files tied to a specific schema.
→ Pin: OTel Collector (config YAML schema changes), Kubernetes tools (API versions)
→ Don't pin: linters (config is stable across versions)

**Rule 3: Don't pin if the tool is installed via a package manager that handles compatibility.**
apt, npm global, pip, rustup — these resolve dependencies themselves.
→ Don't pin: anything installed via `apt-get install`, `npm install -g`, `pip install`

**Rule 4: Don't pin utilities where "latest" is always safe.**
Small CLI tools, formatters, dev helpers. Breaking changes are rare and low-impact.
→ Don't pin: dev-utils, api-dev tools, azure CLI extensions

**Rule 5: Every pin MUST have a Renovate annotation.**
No pin without a maintenance path. Format:
```bash
# renovate: datasource=github-releases depName=golang/go
DEFAULT_VERSION="1.26.1"
```
If Renovate is not yet set up, document the pin with a date comment:
```bash
DEFAULT_VERSION="1.26.1"  # Pinned 2026-04-06, check https://go.dev/dl/
```

**Rule 6: Pin to the latest stable, not an arbitrary old version.**
When adding a new pin, always use the current stable release. Never copy a version from a tutorial or blog post without checking upstream.

**Rule 7: Use LTS/stable tracks, not bleeding edge.**
For software with LTS releases (Node.js, Java, .NET), pin to the active LTS, not the latest experimental/RC.
→ Node.js: pin to latest v22.x (Jod LTS), not v24.x until it becomes LTS
→ Java: pin to 17 or 21 (LTS), not 22 (short-term)
→ .NET: pin to 8.0 (LTS), not 10.0 (current but short-term support)

**Rule 8: `--version` flag must always be available.**
Every script with a `DEFAULT_VERSION` must accept `--version X.Y.Z` so users can override. The pin is a sensible default, not a constraint.

---

## Base Image Decision

Current: `mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`

Available upgrade: `1-3.13-bookworm` (Python 3.13, same Debian 12)

**Before upgrading to 3.13, must verify:**
- All 28 install scripts work on Python 3.13
- Pip packages in `install-dev-python.sh` are 3.13-compatible
- User templates that depend on Python (Flask, Django) work on 3.13
- No removed/deprecated stdlib modules break anything

**Recommendation:** Stay on 3.12 for now. It's LTS until Oct 2028 and all templates are tested against it. Python 3.13 upgrade should be a separate plan with testing.

---

## Questions to Answer

1. Should Node be pinned to a specific patch version (e.g., `22.22.2`) or track latest in the `v22.x` line?
2. Should we add a CI check that flags when Dockerfile-installed software is N versions behind?
3. Is there appetite to move to Node 24 LTS (Krypton) instead of staying on 22?
4. Should Go default be bumped to 1.24 (current LTS) or 1.26 (latest)?
5. Should .NET default stay at 8.0 LTS or move to 10.0?

---

## Recommendation

### Done

- **Node.js**: Updated 22.12.0 → 22.22.2 in Dockerfile

### High Priority — Outdated defaults that will confuse users

1. **Go 1.21.0 → 1.24.x or 1.26.1** — 5 major versions behind. Users installing Go get a 3-year-old version. Minimum: bump to 1.24 (latest LTS-like release).
2. **OTel send-event-notification.sh 0.113.0 → 0.149.0** — internal inconsistency, 36 versions behind the main OTel pin.

### Medium Priority — Worth updating

3. **Hugo 0.157.0 → 0.160.0** — 3 minor versions, theme compat risk is low
4. **PowerShell 7.5.4 → 7.6.0** — minor bump, two scripts to update
5. **OTel Collector 0.140.1 → 0.149.0** — 9 minor versions
6. **script_exporter 3.1.0 → 3.2.0** — minor bump
7. **jq 1.6 → 1.8.1** — Dockerfile change (GitHub release instead of apt)

### Low Priority / Deferred

8. **.NET 8.0** — LTS until Nov 2026, fine for now
9. **Base image Python 3.12 → 3.13** — needs separate testing plan
10. **curl, git, wget** — Debian-managed, leave for base image update

### Stale Dockerfile comment

Line 176 references "Docker CLI 27.5.1 (static binary)" — removed by docker-outside-of-docker migration. Should clean up.

---

## Automated Version Checking — Research

This is a growing problem: ~30 install scripts with pinned versions, plus the Dockerfile. Manual auditing doesn't scale. Research into existing tools:

### Renovate Bot — Recommended

The best fit for DCT. Battle-tested, used by CNCF projects and thousands of repos.

**What it handles:**
- Dockerfiles natively (`FROM` image tags, `ARG VERSION=` pins)
- Shell scripts via **regex manager** — requires annotating version pins with comments:
  ```bash
  # renovate: datasource=github-releases depName=golang/go
  DEFAULT_VERSION="1.21.0"
  ```
- Creates PRs automatically on a schedule
- Supports datasources: GitHub releases, Docker Hub, npm, PyPI, endoflife.date, and many more
- Single `renovate.json` config file

**What it can't do:**
- Won't auto-discover version pins without annotations
- Initial setup takes time (annotate scripts, configure datasources)

**Implementation effort:** Medium — annotate 10 pinned scripts, create `renovate.json`, enable GitHub App or Action.

### Dependabot — Too Limited

- Handles Dockerfiles (`FROM` only) and standard package managers (npm, pip, cargo)
- **Cannot** parse version pins in shell scripts — no regex/custom manager
- Not extensible enough for DCT's use case

### nvchecker — Lightweight Alternative

Python-based tool for detecting new versions. TOML config:
```toml
[go]
source = "github"
github = "golang/go"

[hugo]
source = "github"
github = "gohugoio/hugo"
```

- Detects outdated versions but does NOT auto-update files or create PRs
- Good for CI reporting ("these 3 things are outdated") without auto-PRs
- Less mainstream than Renovate

### endoflife.date API — Supplementary

Free REST API covering ~400 software products:
```bash
curl -s https://endoflife.date/api/golang.json | jq '.[0].latest'
```

- Best for compliance checks (is this version still supported?)
- Doesn't auto-update anything
- Renovate can use it as a datasource

### Trivy / Snyk — Different Problem (Security)

- Scan container images for CVE vulnerabilities
- Don't track version freshness — track known security issues
- Complementary to version checking, not a replacement

### Comparison

| Tool | Dockerfiles | Shell Scripts | Auto-PRs | Effort |
|------|-------------|---------------|----------|--------|
| **Renovate** | Native | Via regex annotations | Yes | Medium |
| **Dependabot** | Native | No | Yes | Low |
| **nvchecker** | Via regex | Yes | No (report only) | Medium |
| **Custom CI script** | Parse yourself | Parse yourself | Manual | High maintenance |
| **Trivy/Snyk** | CVE scan | No | No | Low |

### Recommendation

**Phase 1:** Set up Renovate with regex manager. Annotate the 10 pinned install scripts with `# renovate:` comments. Configure `renovate.json` with GitHub releases datasource. Enable weekly schedule. This gives automatic PRs when any pinned version falls behind.

**Phase 2:** Add CI testing for version bumps (see next section).

**Phase 3:** Add Trivy scanning on built images for CVE coverage (separate concern from version freshness).

**Phase 4 (optional):** Add endoflife.date API check in CI for compliance reporting (is any pinned version approaching end-of-life?).

---

## Testing Gap: Version Bumps Are Not Validated in CI

### Current CI test levels

| Level | What | Where | Catches bad version bump? |
|---|---|---|---|
| Level 1 — Static | Syntax, metadata, categories, flags | CI (GitHub Actions) | No |
| Level 2 — Unit | `--help`, `--verify`, library functions | CI | No |
| Level 3 — Install cycle | Actual install + uninstall | **Local only** | **Yes** — but manual |
| ShellCheck | Linting | CI | No |

### The problem

Level 3 (install cycle) is the only test that catches a broken version pin — dead download URL, renamed binary, changed archive structure. But Level 3 is local-only, not in CI. The `ci-tests.yml` comment says: *"Install cycle tests (Level 3) are for local testing only, they require a fully configured devcontainer environment."*

This means:
- Renovate creates a PR bumping Go to 1.27.0
- CI runs static + unit tests → all PASS (they don't install anything)
- PR gets merged
- User runs `dev-setup` → Go install **fails** because the download URL changed

Version bumps need CI validation.

### Options

**Option A: Full install cycle in CI (heavy)**

Run Level 3 for any script changed in a PR. Builds the container image, installs the tool, verifies `SCRIPT_CHECK_COMMAND` succeeds.

```yaml
- name: Install cycle test (changed scripts only)
  run: |
    CHANGED=$(git diff --name-only origin/main | grep 'install-.*\.sh$' || true)
    for script in $CHANGED; do
      docker run --rm devcontainer-test:latest \
        bash /workspace/.devcontainer/additions/tests/run-all-tests.sh install "$(basename $script)"
    done
```

- Pro: catches everything (download, install, binary works)
- Con: slow (downloads software), needs network, flaky if upstream is down
- Con: some scripts install large runtimes (Go ~150MB, .NET ~500MB)

**Option B: Download URL smoke test (light)**

For each pinned script, extract the download URL and do an HTTP HEAD request. Catches dead URLs and bad version strings without actually installing.

```bash
# Example: verify Go download URL resolves
VERSION="1.26.1"
ARCH="amd64"
URL="https://go.dev/dl/go${VERSION}.linux-${ARCH}.tar.gz"
HTTP_CODE=$(curl -sI -o /dev/null -w "%{http_code}" "$URL")
if [ "$HTTP_CODE" != "200" ]; then
  echo "FAIL: $URL returned $HTTP_CODE"
  exit 1
fi
```

- Pro: fast (~1s per script), no disk space, catches 80% of issues
- Con: doesn't catch post-download problems (changed binary name, archive structure)
- Con: requires extracting URL logic from each script (brittle)

**Option C: Install cycle for pinned scripts only, on schedule (balanced)**

Run Level 3 for ALL pinned scripts weekly (not on every PR). Catches drift where upstream changes something between our pin and the next bump.

```yaml
on:
  schedule:
    - cron: '0 6 * * 0'  # Weekly Sunday 6am
```

- Pro: catches real breakage before users hit it
- Pro: doesn't slow down PR feedback loop
- Con: failures discovered on a schedule, not at PR time

**Option D: Hybrid (recommended)**

Combine B + C:
- **On every PR that touches an install script:** run URL smoke test (Option B) — fast, catches dead URLs immediately
- **Weekly schedule:** run full install cycle (Option A/C) for all pinned scripts — catches everything else

This gives fast PR feedback + weekly safety net.

### What we already have

`test-install-cycle.sh` — a full install → verify → uninstall → verify test for ALL install scripts. It exists, works, and auto-discovers scripts via `get_scripts("install-*.sh")` glob. No hardcoded script list — any new script in `additions/` is automatically included. The only exclusions are scripts in `SKIP_SCRIPTS` (currently empty) and scripts without `SCRIPT_CHECK_COMMAND`.

**This is the equivalent of UIS's "run all" script.** It just isn't wired into CI.

### How to run it today (manual, inside devcontainer)

```bash
# Test all install scripts (slow — downloads everything)
.devcontainer/additions/tests/run-all-tests.sh install

# Test a single script (fast — targeted)
.devcontainer/additions/tests/run-all-tests.sh install install-dev-golang.sh
```

### What's missing: CI integration

The test infrastructure exists. What's missing is wiring it into GitHub Actions.

**Proposed CI strategy:**

**1. On PRs that touch install scripts: test ONLY the changed scripts**

Fast, targeted. If you change `install-dev-golang.sh`, CI runs the install cycle for Go only.

```yaml
# In ci-tests.yml, new job:
install-cycle:
  name: Install Cycle (changed scripts)
  runs-on: ubuntu-latest
  needs: build
  if: contains(github.event.pull_request.changed_files, 'install-')
  steps:
    - name: Get changed install scripts
      run: |
        CHANGED=$(gh pr diff ${{ github.event.pull_request.number }} --name-only \
          | grep 'additions/install-.*\.sh$' | xargs -I{} basename {} || true)
        echo "CHANGED_SCRIPTS=$CHANGED" >> $GITHUB_ENV
    - name: Run install cycle for changed scripts
      run: |
        for script in $CHANGED_SCRIPTS; do
          docker run --rm devcontainer-test:latest \
            bash /workspace/.devcontainer/additions/tests/run-all-tests.sh install "$script"
        done
```

Catches: dead download URLs, changed archive formats, broken install logic, broken uninstall. Runs in minutes (one script at a time).

**2. Weekly schedule: full install cycle for ALL scripts**

The safety net. Catches drift where upstream changes something between versions.

```yaml
# New workflow: ci-install-cycle-weekly.yml
on:
  schedule:
    - cron: '0 6 * * 0'  # Sunday 6am UTC
  workflow_dispatch:       # Manual trigger

jobs:
  full-install-cycle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build container
        run: docker build -t devcontainer-test:latest -f .devcontainer/Dockerfile.base .devcontainer/
      - name: Run full install cycle
        run: |
          docker run --rm devcontainer-test:latest \
            bash /workspace/.devcontainer/additions/tests/run-all-tests.sh install
      - name: Notify on failure
        if: failure()
        run: echo "::warning::Full install cycle failed — check which scripts are broken"
```

Takes 15-30 minutes (downloads all runtimes). Acceptable on a weekly schedule.

**3. This is a prerequisite for Renovate at scale**

Without CI validation, Renovate auto-PRs could merge broken version bumps. The chain should be:
1. Renovate creates PR bumping Go to 1.27.0
2. CI runs install cycle for `install-dev-golang.sh` → verifies download + install + check command
3. If PASS → safe to merge (manual or auto)
4. If FAIL → PR stays open, team investigates

### Summary: what to build

| What | When | Scope | Effort |
|------|------|-------|--------|
| PR install cycle (changed scripts only) | On every PR touching install scripts | 1-2 scripts | Low — add job to existing `ci-tests.yml` |
| Weekly full install cycle | Sunday 6am schedule | All ~28 scripts | Low — new workflow file |
| Renovate integration | After CI testing is in place | All pinned scripts | Medium — annotate scripts, create `renovate.json` |

Order matters: **CI testing first, then Renovate.** Don't automate version bumps until you can automatically validate them.

---

## GitHub Actions — Node.js 20 Deprecation

Discovered 2026-04-08 in CI build output:

```
Warning: Node.js 20 actions are deprecated. The following actions are running on
Node.js 20 and may not work as expected:
  - actions/checkout@v4
  - actions/setup-node@v4
  - actions/upload-artifact@v4
```

GitHub Actions runners will force these to Node.js 24 by default starting **June 2, 2026**. After that, Node.js 20 will be removed from runners on **September 16, 2026**.

### Affected actions in DCT workflows

| Action | Current | Status |
|--------|---------|--------|
| `actions/checkout@v4` | v4 (Node 20) | Newer version (v5) likely available |
| `actions/setup-node@v4` | v4 (Node 20) | Newer version (v5) likely available |
| `actions/upload-artifact@v4` | v4 (Node 20) | Newer version (v5) likely available |
| `actions/download-artifact@v4` | v4 (Node 20) | Newer version (v5) likely available |
| `docker/setup-qemu-action@v3` | v3 | Check for v4 |
| `docker/setup-buildx-action@v3` | v3 | Check for v4 |
| `docker/login-action@v3` | v3 | Check for v4 |
| `docker/build-push-action@v6` | v6 | Likely current |

### Action items

- [ ] Check latest version of each action on GitHub Marketplace
- [ ] Update all `@vN` references in `.github/workflows/*.yml`
- [ ] Test that workflows still pass after the bump
- [ ] Consider Renovate Bot for automated GitHub Actions version updates (it supports this natively, no regex annotations needed)

### Files to update

- `.github/workflows/ci-tests.yml`
- `.github/workflows/build-image.yml`
- `.github/workflows/deploy-docs.yml`

---

## Docusaurus Build Warning (separate issue)

Discovered 2026-04-08 during local docs build:

```
Warning: Duplicate routes found!
- Attempting to create page at /docs/ai-developer/, but a page already exists
  at this route.
```

There are two files producing the same URL `/docs/ai-developer/`. Likely both `README.md` and `index.md` (or similar) exist in `website/docs/ai-developer/`. Need to delete one or rename it.

This is a Docusaurus structure issue, not an outdated version issue. Tracking it here for visibility — should be fixed in a separate PR.

---

## Next Steps

- [x] Update Node.js version in `image/Dockerfile` (22.12.0 → 22.22.2, 2026-04-06)
- [x] Test image build + `node --version` (v22.22.2) + `npm --version` (10.9.7)
- [x] Update Go default: 1.21.0 → 1.26.1 (2026-04-06)
- [ ] Sync OTel versions (send-event-notification.sh 0.113.0 → match main pin)
- [ ] Update Hugo default: 0.157.0 → 0.160.0
- [ ] Update PowerShell default: 7.5.4 → 7.6.0 (two scripts)
- [ ] Update OTel Collector default: 0.140.1 → 0.149.0
- [ ] Update script_exporter default: 3.1.0 → 3.2.0
- [ ] Decide on jq upgrade path (GitHub release vs apt)
- [x] Clean up stale Docker CLI comment in Dockerfile (2026-04-06)
- [ ] Set up Renovate Bot with regex manager for automated version tracking
- [ ] Annotate 10 pinned install scripts with `# renovate:` comments
- [ ] Create `renovate.json` configuration
