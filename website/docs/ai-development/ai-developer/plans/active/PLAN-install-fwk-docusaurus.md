# Feature: Docusaurus Scaffold Command Script

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Active

**Goal**: Add a cmd script that scaffolds a ready-to-go Docusaurus site in `website/`, matching the project's proven setup.

**Last Updated**: 2026-03-29

---

## Overview

Docusaurus is a React-based static site generator by Meta, commonly used for documentation websites. Unlike Hugo (standalone binary), Docusaurus is npm-based and runs as a local project dependency.

This is a **`cmd-fwk-docusaurus.sh`** script (not `install-*`), because it scaffolds a project rather than installing a global tool. Node.js is already pre-installed in the base devcontainer image.

**What the script does:**
1. Creates a `website/` directory with a complete Docusaurus setup
2. Generates config files (`docusaurus.config.ts`, `sidebars.ts`, `tsconfig.json`, `package.json`)
3. Creates starter content (`docs/`, `blog/`, `src/pages/`, `src/css/`)
4. Runs `npm install` to set up dependencies
5. Idempotent — refuses to overwrite if `website/` already exists

**Starting point includes** (based on this repo's proven setup):
- TypeScript configuration (`docusaurus.config.ts`)
- Mermaid diagram support
- Local search plugin
- Image zoom plugin
- Auto-generated sidebars from filesystem
- Custom CSS with Docusaurus theme variables
- Starter index page and docs page
- Blog with `authors.yml`

**Key design decisions:**
- Always scaffolds in `website/` (hardcoded, no directory argument)
- Generates files directly (not `npx create-docusaurus`) for full control over starting point
- Uses `npx` check as `SCRIPT_CHECK_COMMAND` since Node.js is the only prerequisite
- Category: `FRAMEWORKS`

---

## Phase 1: Create Command Script — DONE

### Tasks

- [x] 1.1 Create `.devcontainer/additions/cmd-fwk-docusaurus.sh` based on cmd template
- [x] 1.2 Set metadata: `SCRIPT_ID="cmd-fwk-docusaurus"`, `SCRIPT_CATEGORY="FRAMEWORKS"`
- [x] 1.3 Set extended metadata (tags, abstract, website, summary, related to `fwk-hugo`)
- [x] 1.4 Define `SCRIPT_COMMANDS` with `--create` and `--help`
- [x] 1.5 Implement `cmd_create` function:
  - Check `website/` doesn't already exist (abort if it does)
  - Create directory structure: `website/{docs,blog,src/css,src/pages,static/img}`
  - Generate `package.json` with Docusaurus 3.x deps (core, preset-classic, mermaid, search, image-zoom)
  - Generate `docusaurus.config.ts` (TypeScript, generic/clean — no project-specific content)
  - Generate `sidebars.ts` (auto-generated from filesystem)
  - Generate `tsconfig.json`
  - Generate `src/css/custom.css` with Docusaurus theme variable stubs
  - Generate `src/pages/index.tsx` with minimal homepage
  - Generate `docs/index.md` with starter content
  - Generate `blog/authors.yml` with placeholder author
  - Run `npm install` inside `website/`
- [x] 1.6 VS Code extensions — N/A for cmd scripts (no `EXTENSIONS` array processing)

### Validation

User confirms script structure and generated files look correct.

---

## Phase 2: Testing — DONE (partial — full tests require devcontainer)

### Tasks

- [x] 2.1 Verify `--help` flag works ✓
- [x] 2.2 Bash syntax check passes; shellcheck/static tests require devcontainer
- [ ] 2.3 Test `--create` inside devcontainer (requires devcontainer)

### Validation

User confirms tests pass or script looks correct.

---

## Acceptance Criteria

- [ ] `cmd-fwk-docusaurus.sh --create` scaffolds a working Docusaurus site in `website/`
- [ ] Generated site builds successfully (`cd website && npm run build`)
- [ ] Generated site starts dev server (`cd website && npm run start`)
- [ ] Script refuses to overwrite existing `website/` directory
- [ ] `--help` flag works
- [ ] Script is idempotent (safe to run twice — second run is a no-op)
- [ ] All core and extended metadata fields are set
- [ ] No shellcheck warnings

---

## Files to Modify

- `.devcontainer/additions/cmd-fwk-docusaurus.sh` (new)
