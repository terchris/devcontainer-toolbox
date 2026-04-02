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

## Immediate Problem: Templates Don't Install Required Tools

Before tackling backend service dependencies, there's a simpler gap: **templates don't install the devcontainer tools they need**.

### Example: PHP template

The user runs `dev-template` and selects the PHP Basic Webserver template. Files are scaffolded, but PHP is not installed in the devcontainer. The user has to manually figure out they need to run `dev-setup`, find PHP, and install it.

### What exists today

- `TEMPLATE_INFO` describes the template (name, description, category, purpose) but has **no field for tool dependencies**
- `enabled-tools.conf` in `.devcontainer.extend/` controls which tools auto-install on container rebuild
- Install scripts have `SCRIPT_ID` (e.g., `dev-php-laravel`) that matches `enabled-tools.conf` entries
- The `auto_enable_tool` function in install scripts adds the ID to `enabled-tools.conf`

### Proposed solution: `TEMPLATE_TOOLS` field

Add a new field to `TEMPLATE_INFO`:

```bash
TEMPLATE_NAME="PHP Basic Webserver"
TEMPLATE_DESCRIPTION="PHP web server using built-in server"
TEMPLATE_CATEGORY="WEB_SERVER"
TEMPLATE_PURPOSE="Provides a minimal starting point..."
TEMPLATE_TOOLS="dev-php-laravel"
```

Multiple tools:
```bash
TEMPLATE_TOOLS="dev-typescript dev-python"
```

### What the template installer should do

1. Read `TEMPLATE_TOOLS` from `TEMPLATE_INFO`
2. For each tool ID:
   a. Add it to `.devcontainer.extend/enabled-tools.conf` (so it persists across rebuilds)
   b. Run the install script: `bash .devcontainer/additions/install-{id-with-prefix}.sh`
3. Show the user what was installed

### Mapping SCRIPT_ID to install script filename

`SCRIPT_ID` values like `dev-php-laravel` map to `install-dev-php-laravel.sh`. The pattern is:
```
install-{SCRIPT_ID}.sh
```

This mapping already exists in the component scanner and auto-enable system.

### Impact on both template scripts

Both `dev-template.sh` and `dev-template-ai.sh` would need this. It belongs in the shared library `template-common.sh`:

```bash
install_template_tools() {
  local tools="$1"  # space-separated SCRIPT_IDs
  for tool_id in $tools; do
    local script="install-${tool_id}.sh"
    local script_path="$ADDITIONS_DIR/$script"
    if [ -f "$script_path" ]; then
      echo "📦 Installing $tool_id..."
      bash "$script_path"
    else
      echo "⚠️  Tool '$tool_id' not found: $script_path"
    fi
  done
}
```

### This is independent of the backend services problem

`TEMPLATE_TOOLS` handles devcontainer tools (PHP, Python, TypeScript, etc.). Backend services (PostgreSQL, Strapi) are a separate concern covered by the options above. Both can coexist:

```bash
TEMPLATE_TOOLS="dev-php-laravel"           # devcontainer tools
TEMPLATE_SERVICES="postgresql"              # backend services (future)
```

---

## Documentation Templates

Beyond app scaffolding and backend services, templates could also scaffold **project documentation**. This would work similarly to AI templates (`dev-template-ai`) but for documentation artifacts.

### Examples of documentation templates

- Architecture Decision Records (ADRs)
- Runbooks / operational guides
- API documentation scaffolds
- Onboarding guides
- Changelog / release notes templates
- Contributing guides
- Incident report templates

### How this could work

Documentation templates would follow the same pattern as AI templates:
- Stored in a templates repository (or a `docs/` category within existing templates)
- Have `TEMPLATE_INFO` metadata (name, description, category, abstract)
- Scaffolded via a command (e.g., `dev-template-docs` or as a category within `dev-template`)
- Could use variable substitution for project-specific values (project name, repo URL, team name)

### Key questions

- Should documentation templates live alongside app templates or in a separate collection?
- Should there be a dedicated command (`dev-template-docs`) or a category within `dev-template`?
- What variables/placeholders should documentation templates support?
- Should documentation templates integrate with Docusaurus (the project's doc system) or be framework-agnostic?

---

## Infrastructure Templates

Templates that scaffold **UIS infrastructure configurations** — helping users set up and manage services in their local Kubernetes cluster via UIS (https://uis.sovereignsky.no).

### Examples of infrastructure templates

- PostgreSQL database setup (deploy, create database, configure credentials)
- Redis cache configuration
- Message queue setup (RabbitMQ, NATS)
- S3-compatible object storage (MinIO)
- Reverse proxy / ingress configuration
- Multi-service stack compositions (e.g., "web app backend" = PostgreSQL + Redis + S3)
- Monitoring stack (Prometheus, Grafana)

### How this could work

Infrastructure templates would describe UIS deployments and resource creation:
- Declare which UIS services to deploy (`uis deploy postgresql`, `uis deploy redis`, etc.)
- Include post-deploy setup scripts (create databases, configure users, set up buckets)
- Generate connection details as `.env` files or config files for app templates to consume
- Could tie into the backend services work (Options A–D above) — infrastructure templates would be the "producer" side, app templates the "consumer" side

### Key questions

- Should infrastructure templates trigger `uis deploy` automatically or just generate instructions?
- How do infrastructure templates compose with app templates? (e.g., user picks "Next.js + PostgreSQL" and both app + infra templates run)
- Should infrastructure templates be idempotent (safe to re-run)?
- How to handle teardown / cleanup of infrastructure resources?

---

## Coding Rules Templates

Templates that scaffold **coding best practices and rules** — project-level configuration for linters, formatters, coding standards, and AI coding guidelines.

### Examples of coding rules templates

- ESLint / Prettier configurations for different project types
- Python linting rules (ruff, pylint, mypy configurations)
- Git hooks (pre-commit, commit-msg conventions)
- Editor configurations (`.editorconfig`, VS Code settings)
- AI coding rules (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`)
- Language-specific best practices (TypeScript strict mode, Go lint rules)
- Security rules (SAST tool configs, dependency scanning)
- Code review checklists

### How this could work

Coding rules templates would drop configuration files into the project:
- Stored as template sets (e.g., "TypeScript Strict" includes ESLint, Prettier, tsconfig, and editorconfig)
- Have `TEMPLATE_INFO` metadata describing the coding standard
- Could be layered — a base set of rules plus optional stricter additions
- Should be composable — picking "Python" and "Security" rules shouldn't conflict
- Could integrate with `dev-setup` to install required tooling (linters, formatters)

### Key questions

- Should coding rules templates merge with existing config files or replace them?
- How to handle conflicts when multiple rule sets are applied?
- Should there be opinionated defaults per language/framework, or always let the user choose?
- How do coding rules templates interact with `TEMPLATE_TOOLS` (e.g., a linting rules template that requires `dev-eslint`)?

---

## Questions to Answer

### Tool dependencies -- COMPLETED 2026-03-30

1. ~~Should `TEMPLATE_TOOLS` be added to `TEMPLATE_INFO` format?~~ **Yes -- implemented.**
2. ~~Should tools install automatically or ask the user first?~~ **Automatically, shown in dialog before confirmation.**
3. ~~What if a tool install fails?~~ **Warn and continue, don't abort.**

See `PLAN-template-tools-dct.md` (completed) and `PLAN-template-tools-dev-templates.md` (completed in helpers-no/dev-templates).

### Backend service dependencies (future)

4. Does UIS have (or plan to have) a way to query deployed service details? (`uis info`, API, config file?)
5. Should database creation be part of the template installer or a separate step the user runs?
6. Should we support non-UIS backends? (local Docker, cloud databases, etc.)
7. Is Backstage on the roadmap? If so, should we design for Backstage scaffolder compatibility?
8. What UIS services beyond PostgreSQL will templates need? (Redis, message queues, S3-compatible storage?)

---

## Recommendation

*To be determined after answering the questions above.*

The `.env.example` pattern should be the foundation regardless of which option we choose — it's the universal standard and keeps templates portable.

---

## Next Steps

### Immediate (TEMPLATE_TOOLS) -- COMPLETED 2026-03-30

- [x] Add `TEMPLATE_TOOLS` field to TEMPLATE_INFO format spec (in dev-templates repo)
- [x] Add `install_template_tools()` to `template-common.sh`
- [x] Update `dev-template.sh` and `dev-template-ai.sh` to read and process `TEMPLATE_TOOLS`
- [x] Update all 7 app templates with `TEMPLATE_TOOLS` (in dev-templates repo)
- [x] Create and complete PLAN for implementing TEMPLATE_TOOLS

### Future (backend services)

- [ ] Determine what UIS can provide for service discovery
- [ ] Decide on approach (A, B, C, or D) for backend services
- [ ] Create PLAN for implementing the chosen approach

### Future (documentation templates)

- [ ] Investigate documentation templates — similar concept to AI templates but for project documentation (e.g., ADRs, runbooks, API docs, onboarding guides, changelogs)
- [ ] Determine how documentation templates relate to and differ from AI templates
- [ ] Decide if documentation templates should use the same infrastructure (TEMPLATE_INFO, template installer) or a separate system

### Future (infrastructure templates)

- [ ] Investigate infrastructure templates for UIS service setup (PostgreSQL, Redis, message queues, etc.)
- [ ] Determine how infrastructure templates compose with app templates (producer/consumer relationship)
- [ ] Decide on idempotency and teardown strategies

### Future (coding rules templates)

- [ ] Investigate coding rules templates for linters, formatters, AI rules, and best practices
- [ ] Determine how rule sets compose and handle conflicts when layered
- [ ] Decide on merge vs replace strategy for existing config files
