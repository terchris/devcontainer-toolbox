# Feature: Service Integration with dev-template configure (Phase B)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: ✅ Completed (2026-04-05, shipped in v1.7.16)

**Goal**: Add `dev-template configure` command that reads `template-info.yaml`, processes `params`, and calls UIS via `uis-bridge` to create databases, expose services, and wire connections into `.env`.

**Last Updated**: 2026-04-05

**Investigation**: `helpers-no/dev-templates` -> `INVESTIGATE-unified-template-system.md` (all three contributors confirmed)

**Depends on**:
- DCT Phase A completed (unified `dev-template`, registry browsing, `install_type`)
- UIS `uis configure` command ready (at least PostgreSQL)
- UIS `uis expose` command ready

---

## Overview

After Phase A, `dev-template` installs template files and tools. But templates with `requires` (e.g., Next.js + PostgreSQL) need a second step: `dev-template configure`.

**Flow:**
1. User ran `dev-template` (Phase A) -- files and tools installed
2. User edits `template-info.yaml` params (app_name, database_name, etc.)
3. User runs `dev-template configure`
4. DCT reads `template-info.yaml`, validates params
5. For each `requires` entry: calls `uis-bridge configure <service> --json`
6. UIS creates database/user, exposes port, returns connection JSON
7. DCT writes `.env` with connection details
8. App is scaffolded and pre-wired to running infrastructure

---

## Phase 1: Docker CLI install script — ✅ SUPERSEDED

Replaced by `docker-outside-of-docker` devcontainer feature (see
`completed/INVESTIGATE-docker-socket-cross-platform.md`). The feature
provides Docker CLI + socket on all platforms with zero configuration.
`install-tool-docker-cli.sh` was deleted.

---

## Phase 2: uis-bridge library — ✅ DONE (code only, untested)

### Tasks

- [x] 2.1 Create `lib/uis-bridge.sh` in DCT manage directory:
  - `UIS_CONTAINER="uis-provision-host"` (fixed name, Decision per 8UIS)
  - `uis_bridge_check()` -- verify UIS container is running, clear error if not
  - `uis_bridge_run()` -- `docker exec "$UIS_CONTAINER" uis "$@"`
  - `uis_bridge_run_stdin()` -- `docker exec -i "$UIS_CONTAINER" uis "$@"` (for init files)
  - `uis_bridge_configure()` -- calls `uis configure`, parses JSON response, handles errors
  - Error handling: parse `{"status": "error", "phase": "...", "detail": "..."}` format
- [x] 2.2 Check Docker CLI is available before any bridge call (clear error if not installed)

### Validation

`uis_bridge_run uis status --json` returns data from UIS.

---

## Phase 3: dev-template configure command — ✅ DONE (code only, untested)

### Tasks

- [x] 3.1 Add `dev-template configure` subcommand
- [x] 3.2 Substitute `{{ params.* }}` in `requires` entries and init file contents
- [x] 3.3 For each `requires` entry: call `uis_bridge_configure`, handle stdin init files, collect connection details
- [x] 3.4 Write `.env` / `.env.cluster` with connection details
- [x] 3.5 Show completion summary (succeeded/failed/skipped)

### Validation

`dev-template configure` creates database in UIS PostgreSQL, writes `.env` with DATABASE_URL.

---

## Phase 4: Params -- three input paths — ✅ DONE

### Tasks

- [x] 4.1 Interactive path: developer edits `template-info.yaml` params section
- [x] 4.2 CLI path: `dev-template configure --param app_name=volunteer-app`
  - [x] CLI args override YAML values
  - [x] Write back to `template-info.yaml` so future re-runs use the same values
- [x] 4.3 Env var path (CI/CD): `TEMPLATE_PARAM_APP_NAME=volunteer-app dev-template configure`

### Validation

All three input paths work. Params persisted in `template-info.yaml`.

---

## Phase 5: Idempotent re-runs — ✅ DONE (via UIS `already_configured`)

### Tasks

- [x] 5.1 Rely on UIS's `already_configured` response rather than local state tracking (simpler, no state sync issues). UIS rotates password on `already_configured` and returns fresh credentials — DCT writes updated `.env` automatically.
- [x] 5.2 Handle failed retries: failed services fail with structured JSON error, summary shows succeeded/failed/skipped per service.

### Validation

Verified in Round 2 integration testing (talk.md): `dev-template configure` run twice shows `⏭️ already configured` on second run, `.env` password rotates on each re-run.

---

## Phase 6: Testing — ✅ DONE

Integration tested against uis1 tester's live `uis-provision-host` container (see `testing/uis1/talk/talk.md`):

**Round 1 — uis-bridge contract verification** (7 tests, 5 PASS + 2 UIS contract gaps, fixed by UIS):
- [x] 6.2 `uis-bridge` with running UIS container
- [x] 6.3 `uis-bridge` with UIS container not running (clear error)
- [x] 6.8 Init file error handling (bad SQL) — found+fixed UIS rollback bug
- [x] 6.12 `.env` generation with correct connection details

**Round 2 — full end-to-end flow** (10 tests, all PASS after 3 DCT fixes in v1.7.15 + env_var in v1.7.16):
- [x] 6.4 `dev-template configure` with PostgreSQL requires
- [x] 6.6 Params via CLI args (with write-back to YAML)
- [x] 6.7 Init file with param substitution
- [x] 6.9 Idempotent re-run (`already_configured` with password rotation)
- [x] 6.11 Partial failure (first succeeds, second fails) — structured errors surfaced

Skipped / not blocking ship:
- 6.1 Docker CLI install — superseded by `docker-outside-of-docker` feature
- 6.5 Params validation (missing required) — unit-level, covered by code path
- 6.10 Multiple requires (PostgreSQL + Authentik) — Authentik configure not yet in UIS, deferred

### Validation

Full flow verified: `dev-template python-basic-webserver-database` → `dev-template configure --param app_name=X --param database_name=Y` → UIS creates DB → init file applied → `.env` written with `DATABASE_URL` → idempotent re-runs rotate passwords cleanly → structured errors for failures.

---

## Acceptance Criteria

- [x] Docker CLI installable — superseded: `docker-outside-of-docker` feature provides CLI + socket
- [x] `uis-bridge.sh` abstracts all UIS communication (Decision per 3UIS)
- [x] `dev-template configure` reads `template-info.yaml` and processes `requires`
- [x] Params validated before any UIS calls
- [x] Three input paths: YAML edit, CLI args (with write-back), env vars (3MSG)
- [x] `{{ params.* }}` substituted in requires and init files before UIS (11UIS)
- [x] Init file errors shown with context (15MSG)
- [x] Partial failure handling: show summary, retry on re-run
- [x] `.env` generated with local and cluster connection details (`env_var` field support)
- [x] Idempotent re-runs (UIS `already_configured` + password rotation)
- [x] Clear error when UIS container not running
- [x] Clear error when Docker CLI not installed (via docker-outside-of-docker feature prereq)

---

## Files to Create/Modify

**New:**
- `.devcontainer/additions/install-tool-docker-cli.sh` -- Docker CLI install script
- `.devcontainer/manage/lib/uis-bridge.sh` -- UIS communication abstraction
- `.devcontainer/manage/dev-template-configure.sh` -- configure subcommand (or integrated into dev-template.sh)

**Modify:**
- `.devcontainer/manage/dev-template.sh` -- add `configure` subcommand routing
