# Investigate: Advanced Templates with Backend Dependencies

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Determine how templates should handle backend service dependencies (databases, APIs, CMS) in a UIS/Kubernetes environment.

**Priority**: Medium

**Last Updated**: 2026-03-30

---

## Context

Current templates are simple file scaffolds with no dependencies. Future templates (e.g., Next.js + Strapi + PostgreSQL) need to:

1. Create resources in already-running backend services (e.g., create a database)
2. Discover connection details (host, port, credentials)
3. Configure the application to connect to those resources

The user environment:
- User creates a repo, clones it, installs DCT, starts devcontainer
- User has a local K8s cluster managed by UIS (https://uis.sovereignsky.no)
- User can deploy services like PostgreSQL via `uis deploy postgresql`
- PostgreSQL is deployed with preset admin/password, no databases created
- Templates need to create a database and wire the connection into the app

---

## Industry Best Practices

### Twelve-Factor App (Factor III: Config)

The established standard: configuration via environment variables. Templates ship `.env.example` with documented variables, developers fill in real values. Used by Next.js, Strapi, Rails, Django, Laravel, and all major frameworks.

The Twelve-Factor methodology was open-sourced in 2024 for community modernization. Google Cloud extended it to 16 factors for AI apps. It remains the foundation of cloud-native development.

**References:**
- https://12factor.net/config
- https://cloud.google.com/transform/from-the-twelve-to-sixteen-factor-app
- https://thenewstack.io/open-source-drives-the-twelve-factor-modernization-project/

### Backstage Software Templates

Backstage handles service connections via:
- `defaultEnvironment` — centralized config injected into all templates
- Custom scaffolder actions — steps like `action: create-database` that call APIs
- `template.yaml` declarative steps — fetch, replace, publish, custom actions

Under the hood, it's still environment variables. The automation layer just fills them in.

**References:**
- https://backstage.io/docs/features/software-templates/configuration/
- https://developers.redhat.com/articles/2025/03/17/10-tips-better-backstage-software-templates

### Helm / Kubernetes patterns

- Init containers or Jobs for one-time database creation
- Kubernetes Secrets for credentials
- Service DNS for discovery (e.g., `postgresql.default.svc.cluster.local`)

---

## The Specific Challenge: UIS + Templates

### What exists

```
User's machine
+-- K8s cluster (UIS)
|   +-- PostgreSQL pod (uis deploy postgresql)
|       +-- admin/pw preset by UIS
|       +-- no databases created
|
+-- Devcontainer (VSCode)
    +-- /workspace (cloned repo)
        +-- dev-template selects a template
            +-- needs database created in PostgreSQL
            +-- needs DATABASE_URL to connect
```

### What a template needs to do

1. **Declare dependencies** — "I need PostgreSQL"
2. **Create resources** — create a database in the running PostgreSQL
3. **Discover connection** — get host, port, credentials
4. **Configure app** — generate `.env` with `DATABASE_URL`

### What UIS needs to provide

Templates need to query UIS for service connection details. Possible mechanisms:
- `uis info postgresql --json` command that returns host/port/credentials
- Config file written by UIS (e.g., `/workspace/.uis/services.json`)
- Environment variables set by UIS (e.g., `UIS_POSTGRES_HOST`)
- Kubernetes secrets readable via `kubectl get secret`

---

## Options

### Option A: Setup scripts in templates

Templates include a `scripts/setup-database.sh` that creates the DB and generates `.env`:

```
template/
+-- .env.example              -- documents what's needed
+-- scripts/
|   +-- setup-database.sh     -- creates DB + generates .env
+-- src/                      -- app code
+-- README.md                 -- "Run: bash scripts/setup-database.sh"
```

The setup script knows UIS conventions (preset host/port/credentials) and creates the database.

**Pros:** Simple, self-contained, no new infrastructure
**Cons:** UIS connection details hardcoded in templates, breaks if UIS changes conventions

### Option B: UIS publishes service catalog

After `uis deploy postgresql`, UIS writes connection details to a known location. Templates read from there.

```json
// .uis/services.json (written by UIS)
{
  "postgresql": {
    "host": "postgresql.default.svc.cluster.local",
    "port": 5432,
    "admin_user": "postgres",
    "admin_password": "preset-password"
  }
}
```

Templates read this file to create databases and generate `.env`.

**Pros:** Decoupled — templates don't hardcode UIS internals
**Cons:** Requires UIS to implement service catalog publishing

### Option C: TEMPLATE_INFO declares UIS dependencies

```bash
TEMPLATE_UIS_SERVICES="postgresql"
```

The template installer queries UIS (`uis info postgresql --json`), gets connection details, and passes them to a template setup script.

**Pros:** Most automated, installer handles discovery
**Cons:** Requires UIS CLI to have an `info` command, tighter coupling between installer and UIS

### Option D: Config scripts as bridge (uses existing DCT infrastructure)

Extend existing `config-*.sh` pattern:

```bash
# TEMPLATE_INFO
TEMPLATE_PREREQUISITES="config-uis-postgresql.sh"
```

The config script (`config-uis-postgresql.sh`) knows how to query UIS for PostgreSQL details and exports env vars. The template's `.env.template` uses those vars.

**Pros:** Uses existing DCT prerequisite system, already works with dev-setup
**Cons:** Need a config script per UIS service, config scripts need UIS knowledge

---

## Questions to Answer

1. Does UIS have (or plan to have) a way to query deployed service details? (`uis info`, API, config file?)
2. Should database creation be part of the template installer or a separate step the user runs?
3. Should we support non-UIS backends? (local Docker, cloud databases, etc.)
4. Is Backstage on the roadmap? If so, should we design for Backstage scaffolder compatibility?
5. What UIS services beyond PostgreSQL will templates need? (Redis, message queues, S3-compatible storage?)

---

## Recommendation

*To be determined after answering the questions above.*

The `.env.example` pattern should be the foundation regardless of which option we choose — it's the universal standard and keeps templates portable.

---

## Next Steps

- [ ] Determine what UIS can provide for service discovery
- [ ] Decide on approach (A, B, C, or D)
- [ ] Create PLAN for implementing the chosen approach
