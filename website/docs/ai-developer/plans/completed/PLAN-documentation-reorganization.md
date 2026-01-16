# Plan: Documentation Reorganization

## Status: ✅ Completed

**Goal**: Consolidate all documentation into `docs/` folder with clear separation between user and contributor docs.

**Completed**: 2026-01-14

---

## Overview

Previously documentation was scattered:
- `.devcontainer/docs/` - Mixed user and contributor docs
- `docs/contributors/` - Contributor workflow docs
- Root `README.md` - User getting started

**Final structure:**
```
docs/
├── README.md                    # User documentation index
├── getting-started.md           # Installation and first steps
├── commands.md                  # All dev-* commands reference
├── tools.md                     # Available tools (auto-generated)
├── tools-details.md             # Detailed tool info (auto-generated)
├── configuration.md             # enabled-tools.conf, enabled-services.conf, secrets
├── troubleshooting.md           # Common issues and solutions
├── dev-setup.png                # Screenshot of dev-setup menu
│
└── contributors/                # Maintainer documentation
    ├── README.md                # Contributor index
    ├── PLANS.md                 # How to write plans
    ├── WORKFLOW.md              # Issue to implementation flow
    ├── RELEASING.md             # Version and release process
    ├── architecture.md          # System architecture
    ├── adding-tools.md          # How to add install scripts
    ├── categories.md            # Category reference
    ├── service-dependencies.md  # Service dependency flow
    ├── monitoring-requirements.md # Container monitoring requirements
    └── plans/                   # Implementation plans
```

---

## Phase 1: Setup User Docs Structure — ✅ DONE

- [x] 1.1 Create `docs/README.md` as user documentation index
- [x] 1.2 Create `docs/getting-started.md`
- [x] 1.3 Regenerate tools manual with `generate-manual.sh`
- [x] 1.4 Create `docs/tools.md` and `docs/tools-details.md`
- [x] 1.5 Create `docs/commands.md` with all dev-* commands reference
- [x] 1.6 Create `docs/configuration.md` documenting config files

---

## Phase 2: Move Contributor Docs — ✅ DONE

- [x] 2.1 Move `additions-system-architecture.md` to `docs/contributors/architecture.md`
- [x] 2.2 Move `categories-reference.md` to `docs/contributors/categories.md`
- [x] 2.3 Move `service-dependency-flow.md` to `docs/contributors/service-dependencies.md`
- [x] 2.4 Move `container-monitoring-requirements.md` to `docs/contributors/monitoring-requirements.md`
- [x] 2.5 Update `docs/contributors/README.md` to reference new files

---

## Phase 3: Update References and Cleanup — ✅ DONE

- [x] 3.1 Update root `README.md` to link to `docs/`
- [x] 3.2 Update any internal links in moved documents
- [x] 3.3 Delete `.devcontainer/docs/README-manual-BACKUP-*.md`
- [x] 3.4 Delete `.devcontainer/docs/` folder
- [x] 3.5 Update `generate-manual.sh` to output to `docs/tools.md` and `docs/tools-details.md`
- [x] 3.6 Update `generate-manual.sh` to also update README.md between markers

---

## Phase 4: Create Missing User Docs — ✅ DONE

- [x] 4.1 Create `docs/troubleshooting.md` with common issues
- [x] 4.2 Review and update `docs/getting-started.md` for completeness
- [x] 4.3 Ensure all dev-* commands are documented in `docs/commands.md`

---

## Phase 5: CI Integration — ✅ DONE

- [x] 5.1 Add documentation check to CI workflow
- [x] 5.2 CI fails if `generate-manual.sh` output differs from committed files
- [x] 5.3 Add dev-setup.png screenshot to README.md

---

## Acceptance Criteria — ✅ ALL MET

- [x] All documentation consolidated under `docs/`
- [x] Clear separation: `docs/` for users, `docs/contributors/` for maintainers
- [x] `.devcontainer/docs/` folder removed
- [x] No broken internal links
- [x] Root README.md links to new locations
- [x] Auto-generated tools docs output to correct location
- [x] CI checks documentation is up-to-date
- [x] README.md tools table is auto-generated

---

## Additional Changes

- Created `CLAUDE.md` for Claude Code workflow instructions
- Simplified `.devcontainer.extend/README-devcontainer-extended.md`
- Deleted unused `update-devcontainer.ps1` and `update-devcontainer.sh`
- Created `docs/contributors/RELEASING.md` for version release process
- Created `docs/contributors/adding-tools.md` for adding new tools
