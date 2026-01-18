# Feature: Infrastructure Documentation Integration

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Draft (Definition Incomplete)

**Goal**: Integrate documentation from urbalurba-infrastructure repo into the DevContainer Toolbox website, creating a unified portal for tools, templates, and infrastructure packages.

**Last Updated**: 2026-01-17

**Prerequisites**:
- PLAN-007 complete (templates integration)

**Priority**: Future (larger scope - cross-repo integration)

---

## Overview

The [urbalurba-infrastructure](https://github.com/terchris/urbalurba-infrastructure) repo contains deployment packages for various infrastructure services. This plan integrates that documentation into the DevContainer Toolbox website.

### Website Structure After Implementation

```
DevContainer Toolbox (dct.sovereignsky.no)
├── /docs/tools/          → Development tools (current)
├── /docs/templates/      → Project templates (PLAN-007)
└── /docs/infrastructure/ → Infrastructure packages (this plan)
    ├── /ai/              → LiteLLM, OpenWebUI
    ├── /databases/       → PostgreSQL, MySQL, MongoDB, Qdrant
    ├── /monitoring/      → Grafana, Prometheus, Loki
    ├── /queues/          → RabbitMQ, Redis
    └── /...
```

### Infrastructure Packages in urbalurba-infrastructure

**AI & ML:**
- LiteLLM (AI gateway)
- OpenWebUI
- Environment management

**Authentication:**
- Authentik (SSO/Identity)

**Databases:**
- PostgreSQL, MySQL, MongoDB
- Qdrant (vector database)

**Data Science:**
- JupyterHub
- Apache Spark
- Unity Catalog

**Development:**
- ArgoCD (GitOps)

**Monitoring:**
- Grafana, Prometheus
- Loki (logs), Tempo (traces)
- OpenTelemetry

**Queues & Messaging:**
- RabbitMQ, Redis

**Search:**
- Elasticsearch

**Networking:**
- Cloudflare, Tailscale

**Hosts:**
- Azure AKS
- MicroK8s (Azure, Multipass, Raspberry Pi)
- Rancher Kubernetes

---

## Definition Tasks (To Complete Before Implementation)

- [ ] Review urbalurba-infrastructure repo structure
- [ ] Inventory all documentation files (~80+ docs)
- [ ] Decide on sync approach (submodule, build-time fetch, or remote content plugin)
- [ ] Define PACKAGE_* metadata format
- [ ] Design infrastructure cards for homepage
- [ ] Plan navigation structure

---

## Cross-Repo Integration Options

### Option A: Git Submodule

```bash
git submodule add https://github.com/terchris/urbalurba-infrastructure.git external/infrastructure
```

**Pros:** Full docs available, version controlled
**Cons:** Must update submodule manually

### Option B: Build-Time Sync Script

```yaml
# .github/workflows/deploy-docs.yml
- name: Fetch infrastructure docs
  run: |
    git clone --depth 1 https://github.com/terchris/urbalurba-infrastructure.git /tmp/infra
    cp -r /tmp/infra/docs website/docs/infrastructure
```

**Pros:** Simple, full control, always latest
**Cons:** Docs not in git (generated at build time)

### Option C: Remote Content Plugin

```js
plugins: [
  ['docusaurus-plugin-remote-content', {
    name: 'infrastructure-docs',
    sourceBaseUrl: 'https://raw.githubusercontent.com/.../docs/',
    outDir: 'docs/infrastructure',
  }],
],
```

**Pros:** Always fetches latest
**Cons:** Need to maintain document list

### Option D: Manifest-Based Sync (Recommended)

Infrastructure repo publishes `docs-manifest.json`:
```json
{
  "version": "1.0.0",
  "baseUrl": "https://raw.githubusercontent.com/.../docs/",
  "documents": [
    {"path": "index.md", "category": "overview"},
    {"path": "databases/postgresql.md", "category": "databases"}
  ]
}
```

**Pros:** Controlled list, versioned, flexible
**Cons:** Requires manifest maintenance in infra repo

---

## Proposed Package Metadata Format

```bash
# --- Core metadata ---
PACKAGE_ID="postgresql"
PACKAGE_VER="15.0"
PACKAGE_NAME="PostgreSQL Database"
PACKAGE_DESCRIPTION="Production-ready PostgreSQL with backups and monitoring"
PACKAGE_CATEGORY="DATABASES"

# --- Extended metadata ---
PACKAGE_LOGO="postgresql-logo.svg"
PACKAGE_WEBSITE="https://postgresql.org"
PACKAGE_TAGS="database sql postgres relational"
PACKAGE_ABSTRACT="PostgreSQL deployed on Kubernetes with automated backups..."
PACKAGE_RELATED="pgadmin mysql mongodb"

# --- Infrastructure-specific ---
PACKAGE_REQUIRES="kubernetes helm"
PACKAGE_NAMESPACE="databases"
PACKAGE_HELM_CHART="bitnami/postgresql"
```

---

## Three Content Types (Unified Metadata)

| Type | Prefix | Source Repo |
|------|--------|-------------|
| Tools | `SCRIPT_*` | devcontainer-toolbox |
| Templates | `TEMPLATE_*` | devcontainer-toolbox (merged) |
| Infrastructure | `PACKAGE_*` | urbalurba-infrastructure (fetched) |

---

## Proposed Phases (Draft)

### Phase 1: Planning & Coordination
- Review urbalurba-infrastructure docs
- Choose sync approach
- Create manifest in infrastructure repo (if using Option D)
- Coordinate with infrastructure repo maintainer

### Phase 2: Docusaurus Multi-Instance Docs
- Configure second docs instance for infrastructure
- Create `sidebarsInfrastructure.ts`
- Set up build-time sync

### Phase 3: Website Integration
- Create PackageCard component (or reuse existing)
- Add infrastructure section to homepage
- Create `packages.json` for navigation cards

### Phase 4: Testing & Polish
- Test full build with infrastructure docs
- Verify search includes infrastructure content
- Test navigation between all sections

---

## Acceptance Criteria (Draft)

- [ ] Infrastructure docs available at /docs/infrastructure/
- [ ] Docs sync automatically at build time
- [ ] Infrastructure section on homepage
- [ ] Search includes infrastructure content
- [ ] Navigation works across all doc sections
- [ ] Repos remain independent (no tight coupling)

---

## Files to Create (Estimated)

- `website/sidebarsInfrastructure.ts` - Infrastructure sidebar
- `website/src/data/packages.json` - Package data for cards
- `website/src/components/PackageCard/` - Or reuse existing

## Files to Modify (Estimated)

- `website/docusaurus.config.ts` - Multi-instance docs config
- `.github/workflows/deploy-docs.yml` - Build-time sync
- `website/src/pages/index.tsx` - Add infrastructure section

## Changes to Infrastructure Repo

- Add `docs-manifest.json` (if using manifest approach)
- Add `packages.json` with metadata
- Ensure docs follow consistent structure

---

## Open Questions

1. Which sync approach is best? (Submodule vs build-time vs remote plugin)
2. Should infrastructure have its own navigation, or integrate with main docs?
3. How do we handle version mismatches between repos?
4. Should package cards link to external docs or embedded docs?
5. How do we coordinate updates between repos?

---

## Data Flow Diagram

```
urbalurba-infrastructure/
├── docs/
│   ├── index.md
│   ├── databases/postgresql.md
│   ├── monitoring/grafana.md
│   └── ... (80+ docs)
├── docs-manifest.json
└── packages.json
        │
        ▼ (fetch at build time)

devcontainer-toolbox/website/
├── docs/
│   ├── tools/           # Local
│   ├── templates/       # Local (after PLAN-007)
│   └── infrastructure/  # Fetched from infra repo
└── src/data/
    └── packages.json    # For cards/navigation
```

---

## Reference

- [urbalurba-infrastructure](https://github.com/terchris/urbalurba-infrastructure)
- INVESTIGATE-docusaurus-enhancements.md - "Future Scope: Infrastructure Services" section
- INVESTIGATE-docusaurus-enhancements.md - "Cross-Repo Data Sharing" section
