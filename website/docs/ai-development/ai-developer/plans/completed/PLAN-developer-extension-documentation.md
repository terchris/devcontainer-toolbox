# Plan: Developer Extension Documentation

## Status: Completed

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

## Phase 1: Create Library Documentation — ✅ DONE

Document the shared libraries that scripts use.

### Tasks

- [x] 1.1 Create `docs/contributors/libraries.md` with overview of all libraries:
  - component-scanner.sh - Script discovery
  - prerequisite-check.sh - Dependency validation
  - logging.sh - Automatic logging
  - tool-auto-enable.sh - Auto-enable for tools
  - service-auto-enable.sh - Auto-enable for services
  - categories.sh - Category definitions
  - install-common.sh - Shared install patterns
  - core-install-*.sh - Package installers

- [x] 1.2 Document key functions with examples:
  - `scan_install_scripts()` - Returns script metadata
  - `check_prerequisite_configs()` - Check dependencies
  - `auto_enable_tool()` / `auto_disable_tool()`
  - `log_info()`, `log_warn()`, `log_error()`

### Validation

User confirms docs/contributors/libraries.md covers all essential functions.

---

## Phase 2: Move Template Documentation — ✅ DONE

Move script creation guides to docs/contributors/.

### Tasks

- [x] 2.1 Move `README-additions-template.md` content to `docs/contributors/creating-install-scripts.md`

- [x] 2.2 Move `README-service-template.md` content to `docs/contributors/creating-service-scripts.md`

- [x] 2.3 Update `docs/contributors/adding-tools.md` to be an index page linking to:
  - creating-install-scripts.md
  - creating-service-scripts.md
  - libraries.md
  - architecture.md

- [x] 2.4 Delete moved .md files from `.devcontainer/additions/addition-templates/`
  - Keep README-secrets.md (user-facing, stays with .devcontainer.secrets)

### Validation

User confirms all links in adding-tools.md work correctly.

---

## Phase 3: Move Infrastructure Documentation — ✅ DONE

Move nginx and OTEL docs to docs/contributors/.

### Tasks

- [x] 3.1 Move `nginx/README-nginx.md` to `docs/contributors/infrastructure-nginx.md`

- [x] 3.2 Move `otel/README-otel.md` to `docs/contributors/infrastructure-otel.md`

- [x] 3.3 Create `docs/contributors/infrastructure.md` as index for infrastructure docs

- [x] 3.4 Delete moved .md files from `.devcontainer/additions/nginx/` and `otel/`

### Validation

User confirms infrastructure documentation is accessible from docs/contributors/README.md.

---

## Phase 4: Move Test Documentation — ✅ DONE

Consolidate test documentation.

### Tasks

- [x] 4.1 Move `tests/README.md` content to `docs/contributors/testing.md`

- [x] 4.2 Merge `tests/integration/README.md` into testing.md

- [x] 4.3 Delete moved .md files from `.devcontainer/additions/tests/`

### Validation

User confirms test documentation is complete in docs/contributors/testing.md.

---

## Phase 5: Update Main Additions README — ✅ DONE

Simplify README-additions.md to focus on usage, not development.

### Tasks

- [x] 5.1 Slim down `README-additions.md` to user-focused content only:
  - How to use dev-setup menu
  - Available script types
  - Links to docs/contributors/ for development

- [x] 5.2 Update `docs/contributors/README.md` to list all new documentation

- [x] 5.3 Update cross-references in architecture.md

### Validation

User confirms README-additions.md is concise and links to proper documentation.

---

## Final Documentation Structure

```
docs/contributors/
├── README.md                      # Index
├── RELEASING.md                   # Release process
├── adding-tools.md                # Overview + links
├── creating-install-scripts.md    # How to create install-*.sh
├── creating-service-scripts.md    # How to create service-*.sh
├── libraries.md                   # Library functions reference
├── architecture.md                # System architecture
├── menu-system.md                 # Dialog tool usage (split from architecture)
├── categories.md                  # Category definitions
├── services.md                    # Services index (renamed from infrastructure)
├── services-nginx.md              # Nginx service
├── services-otel.md               # OTEL service
├── services-dependencies.md       # Service dependencies
├── services-monitoring-requirements.md  # Monitoring requirements
├── testing.md                     # Running tests
├── testing-maintenance.md         # Maintaining test framework
└── CI-CD.md                       # GitHub Actions and CI

docs/ai-developer/
├── README.md                      # AI developer index
├── WORKFLOW.md                    # Plan to implementation flow
├── PLANS.md                       # Plan structure and templates
├── CREATING-SCRIPTS.md            # AI guide for creating scripts
└── plans/                         # Implementation plans
```

---

## Acceptance Criteria

- [x] All script creation documentation in docs/contributors/
- [x] Library functions documented with examples
- [x] Clear learning path: adding-tools.md → specific guides
- [x] No orphaned documentation in .devcontainer/additions/
- [x] README-additions.md is slim and user-focused (705 → 98 lines)
- [x] All cross-references updated and working

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

---

## Additional Work (Beyond Original Scope)

During implementation, additional improvements were made based on user feedback and validation.

### Documentation Restructuring

- **Split architecture.md** - Moved Dialog tool content to `menu-system.md`
- **Renamed infrastructure → services** - Better reflects content:
  - `infrastructure.md` → `services.md`
  - `infrastructure-nginx.md` → `services-nginx.md`
  - `infrastructure-otel.md` → `services-otel.md`
  - `service-dependencies.md` → `services-dependencies.md`
  - `monitoring-requirements.md` → `services-monitoring-requirements.md`

### New Documentation Created

- **CI-CD.md** (contributors/) - GitHub Actions, versioning, pre-merge checklist - single source of truth
- **testing-maintenance.md** - How to maintain the test framework (for framework maintainers)
- **CREATING-SCRIPTS.md** (ai-developer/) - AI guide for creating scripts with metadata reference

### README.md Improvements (New User Experience)

- **"What Gets Installed" table** - Explains folder structure at a glance
- **"New to Containers?" section** - Explains containers/devcontainers for newcomers
- **Collapsible manual zip download** - Option for users who prefer not to run curl|bash
- **Simpler Windows prerequisites** - Updated to `wsl --install` (works on Windows 10 19041+ and 11)
- **Rancher Desktop explanation** - Notes it's free vs Docker Desktop paid for companies
- **"Production bug?" benefit** - Added ops team use case
- **Removed duplicate content** - "Customize for Your Project" moved to configuration.md only

### getting-started.md Improvements

- **Clearer Windows vs Mac/Linux instructions** - Separate sections
- **Simplified WSL installation** - Single `wsl --install` command
- **"What Gets Installed" section** - Detailed folder structure explanation

### Contributor Documentation Improvements

- **adding-tools.md** - Added "Run inside the devcontainer" clarification
- **adding-tools.md** - Added "Submitting Your Contribution" section with full PR workflow
- **CREATING-SCRIPTS.md** - Added "Run inside the devcontainer" note in Testing section
- **CREATING-SCRIPTS.md** - Added "After Adding a Script" section (generate-manual.sh requirement)
- **Library guidance** - Changed from "don't modify" to guidance on when to create new libraries

### Cross-Reference Updates

- All files updated to use new service-* names
- testing.md references CI-CD.md instead of workflow files directly
- AI developer docs emphasize "tests must pass" and CI will reject failing PRs
- WORKFLOW.md updated with pre-merge version check steps
- Both adding-tools.md and CREATING-SCRIPTS.md now have consistent contribution guidance

---

## Completion Summary

**Original scope**: Move scattered documentation from `.devcontainer/additions/` to `docs/contributors/`

**Delivered**:
1. All 5 phases completed as planned
2. Significant improvements to new user onboarding (README.md, getting-started.md)
3. Clear contribution workflow for both human developers and AI assistants
4. CI/CD documentation as single source of truth
5. Test framework maintenance documentation for maintainers
6. Consistent naming conventions (services-* prefix)
7. Clean separation of concerns (architecture vs menu-system)

**Lines of documentation**: ~3,500 lines moved/created/updated
