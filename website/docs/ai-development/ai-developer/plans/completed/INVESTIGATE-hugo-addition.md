# Investigate: Add Hugo as a DCT Addition

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Completed

**Goal**: Create an `install-fwk-hugo.sh` addition script so developers working on Hugo sites can install Hugo via `dev-setup`.

**Completed**: 2026-03-20

**Last Updated**: 2026-03-20

---

## Background

### Why Hugo needs to be in DCT

The `helpers-no/sovereignsky-site` repo currently uses a custom `.devcontainer/devcontainer.json` instead of DCT. The only reason: DCT doesn't have Hugo. Since DCT already has Node.js and Python (which the site also needs), adding Hugo would let the repo switch to DCT — eating our own dog food.

### The architecture decision

We investigated where framework tools belong (see `helpers-no/sovereignsky-site` investigation). The conclusion:

| Tool type | Where it belongs | Examples |
|-----------|-----------------|----------|
| **Standalone binaries** | DCT additions (`install-dev-*` / `install-fwk-*`) | Go, Rust, Hugo, Helm |
| **npm packages** | Not needed — npm already in DCT | Docusaurus, Next.js, Astro |
| **Project scaffolding** | Dev Templates repo | `hugo-basic-site`, `typescript-basic-webserver` |

Hugo is a standalone binary — same category as Go or Rust. It belongs in DCT as an opt-in addition.

### Future framework additions this enables

Once we establish the pattern with Hugo, the same approach works for other standalone binary frameworks:

| Framework | Install method | Priority |
|-----------|---------------|----------|
| **Hugo** | Binary download from GitHub releases | High — needed now |
| **Helm** | Binary download | Medium — useful for K8s work |
| **Protobuf/gRPC** | Binary download | Low |
| **Flutter** | Binary download | Low |

npm-based frameworks (Docusaurus, Next.js, Astro, SvelteKit, Nuxt) do NOT need additions — they work via `npx` since Node.js is already in DCT.

---

## Questions to Answer

1. What is the correct way to install Hugo extended on Linux (the devcontainer OS)?
2. How do we support version pinning (e.g., `--version 0.157.0`)?
3. Should the script install from GitHub releases or use a package manager?
4. What VS Code extensions should be included for Hugo development?
5. How do we verify the installation works?

---

## Current State

### Install script template

The canonical template is `addition-templates/_template-install-script.sh`. Key patterns:

- **SCRIPT_DIR**: `SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"` — uses `readlink -f`
- **SCRIPT_VER**: starts at `"0.0.1"` for new scripts
- **Libraries to source** (only source what you need):
  - `lib/tool-auto-enable.sh` — auto-enable for container rebuild
  - `lib/logging.sh` — logging to `/tmp/devcontainer-install/`
  - `lib/install-common.sh` — `show_script_help`, `show_install_header`, `detect_architecture`, `process_standard_installations`
  - `lib/core-install-system.sh` — system package processing
  - `lib/core-install-extensions.sh` — VS Code extension processing
- **process_installations patterns**:
  - Pattern 1 (simple): just call `process_standard_installations`
  - Pattern 2 (custom prefix): custom install logic first, then `process_standard_installations` for packages/extensions
  - Pattern 3 (fully custom): skip library entirely (rare)
- **Mode flags**: `DEBUG_MODE`, `UNINSTALL_MODE`, `FORCE_MODE` — initialized to 0, exported after parsing
- **SCRIPT_COMMANDS format**: `"category|flag|description|function|requires_arg|param_prompt"`

### How `install-dev-golang.sh` handles binary download

Go is the closest reference for Hugo since both are standalone binary downloads:

```bash
# Architecture detection via detect_architecture() from install-common.sh
SYSTEM_ARCH=$(detect_architecture)

# Download tarball
curl -fsSL "$download_url" -o "$temp_file"

# Extract (Go extracts a directory to /usr/local)
sudo tar -C /usr/local -xzf "$temp_file"

# Cleanup
rm -f "$temp_file"
```

**No shared library function exists for tarball downloads** — each script handles it inline. Go's `install_go_binary()` is a custom function within the script.

### Key difference: Hugo vs Go installation

| Aspect | Go | Hugo |
|--------|-----|------|
| Tarball contents | `go/` directory tree | `hugo` binary + LICENSE + README |
| Install location | `/usr/local/go/` (directory) | `/usr/local/bin/hugo` (single file) |
| PATH changes | Needs `.bashrc` modification | None — `/usr/local/bin` already in PATH |
| Core libs needed | `core-install-system`, `core-install-extensions`, `core-install-go` | `core-install-system`, `core-install-extensions` only |
| Additional packages | `PACKAGES_GO` (gopls, delve, etc.) | None — Hugo is self-contained |

### Hugo installation details

Hugo Extended is distributed as a single binary. On Linux (arm64 and amd64):

```bash
# URL pattern:
# https://github.com/gohugoio/hugo/releases/download/v{VERSION}/hugo_extended_{VERSION}_linux-{arch}.tar.gz
# where {arch} is "amd64" or "arm64"

# Extract just the hugo binary to /usr/local/bin
sudo tar -C /usr/local/bin -xzf "$temp_file" hugo
```

### VS Code extensions for Hugo

- `budparr.language-hugo-vscode` — Hugo language support
- `eliostruyf.vscode-front-matter` — Front matter CMS (optional)

---

## Recommendation

Create `install-fwk-hugo.sh` following the same pattern as `install-dev-golang.sh`:

- **Script name**: `install-fwk-hugo.sh` (`fwk` prefix for new `FRAMEWORKS` category)
- **SCRIPT_ID**: `fwk-hugo`
- **SCRIPT_CATEGORY**: `FRAMEWORKS` (new category — standalone binary frameworks)
- **Default version**: 0.157.0 (current stable compatible with Blowfish theme v2.100.0)
- **Version pinning**: `--version` flag to install specific version
- **Uninstall**: `--uninstall` flag to remove Hugo
- **Check command**: `command -v hugo >/dev/null 2>&1`
- **Architecture detection**: Support both arm64 and amd64
- **VS Code extensions**: Install `budparr.language-hugo-vscode`

---

## Files to Create/Modify

See [PLAN-install-fwk-hugo.md](PLAN-install-fwk-hugo.md) for the complete file list. Summary:

| File | Action |
|------|--------|
| `.devcontainer/additions/install-fwk-hugo.sh` | Create — the install script |
| `.devcontainer/additions/lib/categories.sh` | Modify — add `FRAMEWORKS` category |
| `.devcontainer/manage/dev-docs.sh` | Modify — add `FRAMEWORKS` to 4 hardcoded category lists |
| `website/src/utils/anchors.ts` | Modify — add `FRAMEWORKS` mapping + `fwk-` prefix strip |
| `website/static/img/categories/src/frameworks-logo.svg` | Create — Lucide "blocks" icon (ISC license) |
| `website/static/img/tools/src/fwk-hugo-logo.svg` | Create — Simple Icons Hugo icon (CC0) |

**Note:** Tool pages (`website/docs/tools/frameworks/hugo.mdx`) are auto-generated by `dev-docs` — do not create manually. Logos are SVG sources; `dev-logos` converts them to production WebP.

---

## Next Steps

- [x] Create PLAN-install-fwk-hugo.md with the implementation details
- [ ] After Hugo addition: Create issue in `helpers-no/dev-templates` for `hugo-basic-site` template
- [ ] After both: Switch `helpers-no/sovereignsky-site` to use DCT
