# Plan: Developer Extension Documentation

## Status: Backlog

**Goal**: Consolidate and improve documentation for developers who want to extend devcontainer-toolbox with new tools, making it easy to contribute.

**Priority**: Medium

**Last Updated**: 2026-01-15

---

## Problem

Current state:
- Excellent documentation exists but is scattered in `.devcontainer/additions/` subfolders
- `docs/contributors/adding-tools.md` is a brief summary that references the scattered docs
- Library functions (lib/*.sh) have no documentation
- Developers must hunt through multiple folders to understand how to add scripts

Goal:
- Move detailed documentation to `docs/contributors/`
- Create a clear learning path for developers
- Document the library system
- Keep `.devcontainer/additions/` focused on code, not docs

---

## Current Documentation Inventory

**In `.devcontainer/additions/`:**
| File | Lines | Content | Action |
|------|-------|---------|--------|
| `README-additions.md` | 706 | Main system guide | Move to docs |
| `addition-templates/README-additions-template.md` | 1,111 | How to create scripts | Move to docs |
| `addition-templates/README-service-template.md` | 1,324 | Service script guide | Move to docs |
| `addition-templates/README-secrets.md` | 52 | Secrets folder | Keep (user-facing) |
| `nginx/README-nginx.md` | 613 | Nginx reverse proxy | Move to docs |
| `otel/README-otel.md` | 983 | OTEL monitoring | Move to docs |
| `tests/README.md` | 106 | Test framework | Move to docs |
| `tests/integration/README.md` | 33 | Integration tests | Merge into test docs |

**In `docs/contributors/`:**
| File | Content | Action |
|------|---------|--------|
| `adding-tools.md` | Brief summary | Expand with moved content |
| `architecture.md` | System architecture | Keep, update references |

**Missing:**
- Library function documentation
- Quick reference guide

---

## Phase 1: Create Library Documentation

Document the shared libraries that scripts use.

### Tasks

- [ ] 1.1 Create `docs/contributors/libraries.md` with overview of all libraries:
  - component-scanner.sh - Script discovery
  - prerequisite-check.sh - Dependency validation
  - logging.sh - Automatic logging
  - tool-auto-enable.sh - Auto-enable for tools
  - service-auto-enable.sh - Auto-enable for services
  - categories.sh - Category definitions
  - install-common.sh - Shared install patterns
  - core-install-*.sh - Package installers

- [ ] 1.2 Document key functions with examples:
  - `scan_install_scripts()` - Returns script metadata
  - `check_prerequisite_configs()` - Check dependencies
  - `auto_enable_tool()` / `auto_disable_tool()`
  - `log_info()`, `log_warn()`, `log_error()`

### Validation

User confirms docs/contributors/libraries.md covers all essential functions.

---

## Phase 2: Move Template Documentation

Move script creation guides to docs/contributors/.

### Tasks

- [ ] 2.1 Move `README-additions-template.md` content to `docs/contributors/creating-install-scripts.md`

- [ ] 2.2 Move `README-service-template.md` content to `docs/contributors/creating-service-scripts.md`

- [ ] 2.3 Update `docs/contributors/adding-tools.md` to be an index page linking to:
  - creating-install-scripts.md
  - creating-service-scripts.md
  - libraries.md
  - architecture.md

- [ ] 2.4 Delete moved .md files from `.devcontainer/additions/addition-templates/`
  - Keep README-secrets.md (user-facing, stays with .devcontainer.secrets)

### Validation

User confirms all links in adding-tools.md work correctly.

---

## Phase 3: Move Infrastructure Documentation

Move nginx and OTEL docs to docs/contributors/.

### Tasks

- [ ] 3.1 Move `nginx/README-nginx.md` to `docs/contributors/infrastructure-nginx.md`

- [ ] 3.2 Move `otel/README-otel.md` to `docs/contributors/infrastructure-otel.md`

- [ ] 3.3 Create `docs/contributors/infrastructure.md` as index for infrastructure docs

- [ ] 3.4 Delete moved .md files from `.devcontainer/additions/nginx/` and `otel/`

### Validation

User confirms infrastructure documentation is accessible from docs/contributors/README.md.

---

## Phase 4: Move Test Documentation

Consolidate test documentation.

### Tasks

- [ ] 4.1 Move `tests/README.md` content to `docs/contributors/testing.md`

- [ ] 4.2 Merge `tests/integration/README.md` into testing.md

- [ ] 4.3 Delete moved .md files from `.devcontainer/additions/tests/`

### Validation

User confirms test documentation is complete in docs/contributors/testing.md.

---

## Phase 5: Update Main Additions README

Simplify README-additions.md to focus on usage, not development.

### Tasks

- [ ] 5.1 Slim down `README-additions.md` to user-focused content only:
  - How to use dev-setup menu
  - Available script types
  - Links to docs/contributors/ for development

- [ ] 5.2 Update `docs/contributors/README.md` to list all new documentation

- [ ] 5.3 Update cross-references in architecture.md

### Validation

User confirms README-additions.md is concise and links to proper documentation.

---

## Final Documentation Structure

```
docs/contributors/
├── README.md                      # Index
├── adding-tools.md                # Overview + links
├── creating-install-scripts.md    # How to create install-*.sh
├── creating-service-scripts.md    # How to create service-*.sh
├── libraries.md                   # Library functions reference
├── architecture.md                # System architecture (existing)
├── categories.md                  # Category definitions (existing)
├── testing.md                     # Test framework
├── infrastructure.md              # Infrastructure index
├── infrastructure-nginx.md        # Nginx documentation
├── infrastructure-otel.md         # OTEL documentation
├── service-dependencies.md        # Service dependencies (existing)
└── ...
```

---

## Acceptance Criteria

- [ ] All script creation documentation in docs/contributors/
- [ ] Library functions documented with examples
- [ ] Clear learning path: adding-tools.md → specific guides
- [ ] No orphaned documentation in .devcontainer/additions/
- [ ] README-additions.md is slim and user-focused
- [ ] All cross-references updated and working

---

## Files to Create

- `docs/contributors/libraries.md`
- `docs/contributors/creating-install-scripts.md`
- `docs/contributors/creating-service-scripts.md`
- `docs/contributors/infrastructure.md`
- `docs/contributors/infrastructure-nginx.md`
- `docs/contributors/infrastructure-otel.md`
- `docs/contributors/testing.md`

## Files to Modify

- `docs/contributors/README.md`
- `docs/contributors/adding-tools.md`
- `docs/contributors/architecture.md`
- `.devcontainer/additions/README-additions.md`

## Files to Delete

- `.devcontainer/additions/addition-templates/README-additions-template.md`
- `.devcontainer/additions/addition-templates/README-service-template.md`
- `.devcontainer/additions/nginx/README-nginx.md`
- `.devcontainer/additions/otel/README-otel.md`
- `.devcontainer/additions/tests/README.md`
- `.devcontainer/additions/tests/integration/README.md`
