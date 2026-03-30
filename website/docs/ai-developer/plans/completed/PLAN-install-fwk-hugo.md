# Feature: Add Hugo Install Script

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Create `install-fwk-hugo.sh` so developers can install Hugo Extended via `dev-setup`.

**Completed**: 2026-03-20

**Last Updated**: 2026-03-20

**Investigation**: [INVESTIGATE-hugo-addition.md](INVESTIGATE-hugo-addition.md)

---

## Overview

Hugo Extended is a standalone binary distributed via GitHub releases. The install script follows the same pattern as `install-dev-golang.sh` — download a tarball, extract to `/usr/local/bin`, support `--version` and `--uninstall` flags.

Hugo Extended (not plain Hugo) is needed because it includes SCSS/SASS support required by most themes including Blowfish.

---

## Phase 1: Create the Install Script — ✅ DONE

### Tasks

- [x] 1.1 Add `FRAMEWORKS` category — requires changes in **5 places**:
  - `.devcontainer/additions/lib/categories.sh`:
    - Add table row: order `8`, ID `FRAMEWORKS`, name `Frameworks & Standalone Binaries`, tags `framework binary standalone hugo helm`, logo `frameworks-logo.webp`
    - Add `readonly CATEGORY_FRAMEWORKS="FRAMEWORKS"` to constants block (~line 203)
  - `.devcontainer/manage/dev-docs.sh` — **5 changes** needed:
    - Add `SCRIPTS_FRAMEWORKS=""` variable declaration (~line 75)
    - Add `FRAMEWORKS` branch to `add_to_category()` case statement (~line 391)
    - Add `FRAMEWORKS` branch to `get_category_scripts()` case statement (~line 407)
    - Add `FRAMEWORKS) echo "frameworks" ;;` to `get_category_folder()` (~line 425)
    - Add `name="${name#fwk-}"` to `get_tool_filename()` (~line 432) — without this, URLs mismatch with `anchors.ts`
  - `website/src/utils/anchors.ts`:
    - Add `FRAMEWORKS: 'frameworks',` to `getCategoryFolder()` mapping
    - Add `.replace(/^fwk-/, '')` to `getToolFilename()`
  - `website/static/img/categories/src/frameworks-logo.svg` — category logo
    - Source: Lucide "blocks" icon (ISC license, permissive) — building-block shapes fitting "frameworks & standalone binaries"
    - Download from lucide.dev or the lucide GitHub repo
- [x] 1.2 Create `.devcontainer/additions/install-fwk-hugo.sh` following `install-dev-golang.sh` pattern
  - Core metadata: `SCRIPT_ID="fwk-hugo"`, `SCRIPT_CATEGORY="FRAMEWORKS"`
  - Default version: `0.157.0`
  - Check command: `[ -f /usr/local/bin/hugo ] || command -v hugo >/dev/null 2>&1` (check install path first per template best practice)
  - Download from: `https://github.com/gohugoio/hugo/releases/download/v{VERSION}/hugo_extended_{VERSION}_linux-{arch}.tar.gz`
  - Install to: `/usr/local/bin/hugo` (single binary, no directory like Go)
  - Architecture detection: `amd64` / `arm64`
  - VS Code extension: `budparr.language-hugo-vscode`
  - `SCRIPT_COMMANDS` for dev-setup menu: default install, `--version`, `--uninstall`, `--help`
  - Extended metadata (required for website):
    - `SCRIPT_TAGS="hugo static-site-generator ssg framework web"`
    - `SCRIPT_ABSTRACT="Hugo Extended static site generator with SCSS/SASS support."`
    - `SCRIPT_LOGO="fwk-hugo-logo.webp"`
    - `SCRIPT_WEBSITE="https://gohugo.io"`
    - `SCRIPT_SUMMARY="Hugo Extended static site generator — the world's fastest framework for building websites. Includes SCSS/SASS compilation, image processing, and VS Code language support. Supports version pinning for theme compatibility."`
    - `SCRIPT_RELATED=""` (no related tools yet in FRAMEWORKS category)
- [x] 1.3 Make the script executable: `chmod +x`
- [x] 1.4 Run static tests: `.devcontainer/additions/tests/run-all-tests.sh static install-fwk-hugo.sh` — 27/27 passed

### Validation

User confirms script structure looks correct. Static tests pass.

---

## Phase 2: Logos & Documentation — ✅ DONE

### Tasks

- [x] 2.1 Add Hugo tool logo to `website/static/img/tools/src/fwk-hugo-logo.svg`
  - Source: Simple Icons Hugo icon (CC0 / public domain)
  - Brand color: `#FF4088`
- [x] 2.2 Run `dev-logos` to convert SVG sources to production WebP (both category and tool logos)
  - Ran inside devcontainer — `fwk-hugo-logo.webp` and `frameworks-logo.webp` generated
- [x] 2.3 Run `dev-docs` to regenerate `website/docs/tools/index.mdx` and category folders
  - Generated `website/docs/tools/frameworks/` with `hugo.mdx`, `index.mdx`, `_category_.json`
  - Updated `website/src/data/categories.json` and `tools.json`

### Validation

`dev-docs` generated correctly. `dev-logos` deferred to devcontainer (SVG sources committed). Category and tool appear in JSON data.

---

## Phase 3: Testing (in devcontainer) — ✅ DONE

### Tasks

- [x] 3.1 Run install: `.devcontainer/additions/install-fwk-hugo.sh` — installed 0.157.0 successfully
- [x] 3.2 Verify: `hugo version` — `hugo v0.157.0+extended linux/arm64`
- [x] 3.3 Run uninstall: `.devcontainer/additions/install-fwk-hugo.sh --uninstall` — removed cleanly
- [x] 3.4 Verify: `command -v hugo` — not found (PASS)
- [x] 3.5 Run with `--version 0.145.0` — installed `hugo v0.145.0+extended linux/arm64` successfully

### Validation

All tests passed. Install, uninstall, and version pinning all work correctly.

---

## Acceptance Criteria

- [ ] `FRAMEWORKS` category appears in `dev-setup` menu and on website
- [ ] `install-fwk-hugo.sh` installs Hugo Extended
- [ ] `--version` flag works for version pinning
- [ ] `--uninstall` removes Hugo cleanly
- [ ] `--help` shows usage information
- [ ] Script is idempotent (safe to run twice)
- [ ] Architecture detection works (amd64/arm64)
- [ ] Static tests pass
- [ ] `dev-setup` menu shows Hugo under Frameworks category
- [ ] `dev-docs` generates frameworks category folder and Hugo tool page
- [ ] Logos render correctly (category + tool)

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `.devcontainer/additions/install-fwk-hugo.sh` | Create — install script |
| `.devcontainer/additions/lib/categories.sh` | Modify — add `FRAMEWORKS` table row + readonly constant |
| `.devcontainer/manage/dev-docs.sh` | Modify — add `FRAMEWORKS` to 4 hardcoded category lists + `fwk-` prefix strip in `get_tool_filename()` |
| `website/src/utils/anchors.ts` | Modify — add `FRAMEWORKS` to `getCategoryFolder()` + `fwk-` to `getToolFilename()` |
| `website/static/img/categories/src/frameworks-logo.svg` | Create — Lucide "blocks" icon (ISC license) |
| `website/static/img/tools/src/fwk-hugo-logo.svg` | Create — Simple Icons Hugo icon (CC0) |

---

## Implementation Notes

### Template and pattern to follow

Base the script on `addition-templates/_template-install-script.sh` using **Pattern 2** (custom prefix):
- Custom `install_hugo_binary()` function for the download/extract
- Then `process_standard_installations` for extensions

### Libraries to source

Only source what Hugo needs (not the full set from the template):

```bash
source "${SCRIPT_DIR}/lib/tool-auto-enable.sh"
source "${SCRIPT_DIR}/lib/logging.sh"
source "${SCRIPT_DIR}/lib/install-common.sh"      # detect_architecture, show_script_help, etc.
source "${SCRIPT_DIR}/lib/core-install-system.sh"
source "${SCRIPT_DIR}/lib/core-install-extensions.sh"
```

Do NOT source: `core-install-go.sh`, `core-install-node.sh`, `core-install-python.sh`, `core-install-pwsh.sh`, `core-install-dotnet.sh`

### Binary download approach

No shared library function exists for tarball downloads. Write an inline `install_hugo_binary()` function following the same pattern as Go's `install_go_binary()`:

```bash
install_hugo_binary() {
    local version="$1" arch="$2"
    local url="https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_extended_${version}_linux-${arch}.tar.gz"
    local temp_file="/tmp/hugo_extended_${version}_linux-${arch}.tar.gz"

    curl -fsSL "$url" -o "$temp_file"
    sudo tar -C /usr/local/bin -xzf "$temp_file" hugo   # extract only the hugo binary
    rm -f "$temp_file"
}
```

### Key differences from Go script

| Aspect | Go | Hugo |
|--------|-----|------|
| Tarball contents | `go/` directory tree | `hugo` binary + LICENSE + README |
| Install location | `/usr/local/go/` (directory) | `/usr/local/bin/hugo` (single file) |
| PATH changes | Needs `.bashrc` modification | None — `/usr/local/bin` already in PATH |
| Uninstall | `sudo rm -rf /usr/local/go` | `sudo rm -f /usr/local/bin/hugo` |
| Additional packages | `PACKAGES_GO` (gopls, delve) | None — Hugo is self-contained |

### Other notes

- `SCRIPT_VER="0.0.1"` per template convention
- `SCRIPT_DIR` uses `readlink -f` per template: `SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"`
- Mode flags (`DEBUG_MODE`, `UNINSTALL_MODE`, `FORCE_MODE`) initialized to 0, exported after parsing
