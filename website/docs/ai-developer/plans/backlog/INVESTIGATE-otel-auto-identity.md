# Investigate: Auto-Detect OTel Developer Identity

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Auto-detect the developer identity for OTel telemetry instead of requiring manual configuration via `generate-devcontainer-identity.sh`.

**Priority**: Low — revisit when setting up OTel again

**Last Updated**: 2026-04-07

---

## Problem

OTel telemetry needs three identity fields to tag metrics and events in Grafana dashboards:

- **DEVELOPER_ID** — who is this developer
- **DEVELOPER_EMAIL** — their email
- **PROJECT_NAME** — what project are they working on

Currently these are set manually via `generate-devcontainer-identity.sh <id> <email> <project>`, stored as base64 in `.devcontainer.secrets`, and sourced by the OTel scripts.

Most developers never run this — so telemetry shows `unknown` for identity fields.

## Available Auto-Detection Sources

All three fields can be derived from data already available in the container:

| Field | Source | How |
|-------|--------|-----|
| DEVELOPER_ID | `DEV_HOST_USER` or `git config user.name` | Host env var (from remoteEnv) or git identity |
| DEVELOPER_EMAIL | `git config user.email` | Set by `config-git.sh` on startup |
| PROJECT_NAME | `git remote get-url origin` | Extract repo name: `url \| sed 's\|.*/\|\|;s\|\.git$\|\|'` |

The `TS_HOSTNAME` (synthetic telemetry hostname) is derived from these: `dev-<developer_id>-<project>`.

## What Also Needs Review

- `HOST_HOSTNAME` in OTel configs (`otelcol-lifecycle-config.yaml`, `otelcol-metrics-config.yaml`) now reads the real machine hostname via `config-host-info.sh` and the `DEV_HOST_HOSTNAME` variable. Verify this flows correctly to Grafana dashboards.
- `HOST_USER` and `HOST_OS` in OTel configs — now populated from `DEV_HOST_*` variables via `config-host-info.sh`. Verify Grafana filters work with the new values.
- The `host-platform-overview.yaml` Grafana dashboard groups by `host_os`, `host_user`, `host_hostname` — test that these labels are populated correctly with the new detection.

## Next Steps

- [ ] When OTel is set up again: auto-detect DEVELOPER_ID, DEVELOPER_EMAIL, PROJECT_NAME in entrypoint or `config-telemetry-identity.sh`
- [ ] Remove or simplify `generate-devcontainer-identity.sh` (keep for override only)
- [ ] Verify HOST_HOSTNAME, HOST_USER, HOST_OS flow correctly to OTel configs and Grafana dashboards with new `DEV_HOST_*` variables
- [ ] Test Grafana dashboard filters with real data from multiple hosts
