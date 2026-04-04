# Feature: Service Integration with dev-template configure (Phase B)

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Add `dev-template configure` command that reads `template-info.yaml`, processes `params`, and calls UIS via `uis-bridge` to create databases, expose services, and wire connections into `.env`.

**Last Updated**: 2026-04-04

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

## Phase 1: Docker CLI install script

### Tasks

- [ ] 1.1 Create `install-tool-docker-cli.sh`:
  - Static binary install (like Hugo -- download from Docker releases)
  - Multi-arch (amd64/arm64)
  - `SCRIPT_ID="tool-docker-cli"`, `SCRIPT_CATEGORY="INFRA_CONFIG"`
  - `SCRIPT_CHECK_COMMAND="command -v docker"`
  - No Docker daemon -- CLI only (socket already mounted)
- [ ] 1.2 Test: `docker ps` works inside devcontainer after install
- [ ] 1.3 Test: `docker exec uis-provision-host echo hello` works

### Validation

Docker CLI installed, can communicate with UIS container.

---

## Phase 2: uis-bridge library

### Tasks

- [ ] 2.1 Create `lib/uis-bridge.sh` in DCT manage directory:
  - `UIS_CONTAINER="uis-provision-host"` (fixed name, Decision per 8UIS)
  - `uis_bridge_check()` -- verify UIS container is running, clear error if not
  - `uis_bridge_run()` -- `docker exec "$UIS_CONTAINER" uis "$@"`
  - `uis_bridge_run_stdin()` -- `docker exec -i "$UIS_CONTAINER" uis "$@"` (for init files)
  - `uis_bridge_configure()` -- calls `uis configure`, parses JSON response, handles errors
  - Error handling: parse `{"status": "error", "phase": "...", "detail": "..."}` format
- [ ] 2.2 Check Docker CLI is available before any bridge call (clear error if not installed)

### Validation

`uis_bridge_run uis status --json` returns data from UIS.

---

## Phase 3: dev-template configure command

### Tasks

- [ ] 3.1 Add `dev-template configure` subcommand:
  - Read `template-info.yaml` from current directory
  - Validate all required `params` are filled (non-empty)
  - Clear error if params missing: list the fields and their descriptions
- [ ] 3.2 Substitute `{{ params.* }}` in `requires` entries and init file contents before calling UIS
- [ ] 3.3 For each `requires` entry:
  - Call `uis_bridge_configure <service> --app <params.app_name> --json` with service-specific config args
  - If init file specified: substitute params, pipe via stdin
  - Parse response: success -> collect connection details, error -> show error with context (15MSG)
  - Stop on first failure, show summary of what succeeded/failed
- [ ] 3.4 Write `.env` with connection details:
  - `.env` for local development (uses `local.host` and `local.port` from UIS response)
  - `.env.cluster` for in-cluster deployment (uses `cluster.host` and `cluster.port`)
- [ ] 3.5 Show completion message with what was configured

### Validation

`dev-template configure` creates database in UIS PostgreSQL, writes `.env` with DATABASE_URL.

---

## Phase 4: Params -- two input paths

### Tasks

- [ ] 4.1 Interactive path: developer edits `template-info.yaml` params section, then runs `dev-template configure`
- [ ] 4.2 CLI path: `dev-template configure --param app_name=volunteer-app --param database_name=volunteer_db`
  - CLI args override YAML values
  - Write back to `template-info.yaml` so future re-runs use the same values
- [ ] 4.3 Env var path (CI/CD): `TEMPLATE_PARAM_APP_NAME=volunteer-app dev-template configure`
  - Uppercase param name with `TEMPLATE_PARAM_` prefix
  - Lower priority than CLI args, higher than YAML

### Validation

All three input paths work. Params persisted in `template-info.yaml`.

---

## Phase 5: Idempotent re-runs

### Tasks

- [ ] 5.1 Track configured services in `template-info.yaml` (or `.template-state.json`):
  - After successful configure, mark service as done
  - On re-run, skip already-configured services (UIS returns "already configured" per 2UIS)
- [ ] 5.2 Handle failed retries:
  - Failed services are retried on next run
  - Show summary: which succeeded, which failed, which skipped

### Validation

Running `dev-template configure` twice: first run configures, second run skips with "already configured".

---

## Phase 6: Testing

### Tasks

- [ ] 6.1 Test Docker CLI install and UIS communication
- [ ] 6.2 Test `uis-bridge` with running UIS container
- [ ] 6.3 Test `uis-bridge` with UIS container not running (clear error)
- [ ] 6.4 Test `dev-template configure` with PostgreSQL requires
- [ ] 6.5 Test params validation (missing required params)
- [ ] 6.6 Test params via CLI args
- [ ] 6.7 Test init file with param substitution
- [ ] 6.8 Test init file error handling (bad SQL)
- [ ] 6.9 Test idempotent re-run (skip already configured)
- [ ] 6.10 Test multiple requires (PostgreSQL + Authentik)
- [ ] 6.11 Test partial failure (first succeeds, second fails)
- [ ] 6.12 Test `.env` generation with correct connection details

### Validation

All tests pass. Full flow: template install -> edit params -> configure -> app connects to services.

---

## Acceptance Criteria

- [ ] Docker CLI installable via `install-tool-docker-cli.sh`
- [ ] `uis-bridge.sh` abstracts all UIS communication (Decision per 3UIS)
- [ ] `dev-template configure` reads `template-info.yaml` and processes `requires`
- [ ] Params validated before any UIS calls
- [ ] Three input paths: YAML edit, CLI args, env vars (3MSG)
- [ ] `{{ params.* }}` substituted in requires and init files before UIS (11UIS)
- [ ] Init file errors shown with context (15MSG)
- [ ] Partial failure handling: stop on error, show summary, retry on re-run
- [ ] `.env` generated with local and cluster connection details
- [ ] Idempotent re-runs (skip already configured)
- [ ] Clear error when UIS container not running
- [ ] Clear error when Docker CLI not installed

---

## Files to Create/Modify

**New:**
- `.devcontainer/additions/install-tool-docker-cli.sh` -- Docker CLI install script
- `.devcontainer/manage/lib/uis-bridge.sh` -- UIS communication abstraction
- `.devcontainer/manage/dev-template-configure.sh` -- configure subcommand (or integrated into dev-template.sh)

**Modify:**
- `.devcontainer/manage/dev-template.sh` -- add `configure` subcommand routing
