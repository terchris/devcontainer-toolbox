# Contributor Documentation

Technical documentation for developers who maintain and extend devcontainer-toolbox.

---

## Structure

```
docs/contributors/
├── README.md                      # This file
├── RELEASING.md                   # How to create new versions
│
├── adding-tools.md                # Overview + quick start
├── creating-install-scripts.md   # Complete install script guide
├── creating-service-scripts.md   # Complete service script guide
├── libraries.md                   # Library functions reference
│
├── architecture.md                # System architecture
├── menu-system.md                 # Dialog tool usage
├── categories.md                  # Tool category reference
├── services-dependencies.md       # Service dependency flow
│
├── services.md                    # Services documentation index
├── services-nginx.md              # Nginx reverse proxy service
├── services-otel.md               # OTEL monitoring service
│
├── testing.md                     # Running tests, adding tests
├── testing-maintenance.md         # Maintaining the test framework
├── CI-CD.md                       # GitHub Actions and release automation
└── services-monitoring-requirements.md  # Container monitoring requirements
```

---

## Getting Started

| Document | Purpose |
|----------|---------|
| [adding-tools.md](adding-tools.md) | Quick start for adding new scripts |
| [creating-install-scripts.md](creating-install-scripts.md) | Complete guide to install-*.sh scripts |
| [creating-service-scripts.md](creating-service-scripts.md) | Complete guide to service-*.sh scripts |
| [libraries.md](libraries.md) | Shared library functions reference |

---

## Architecture & Reference

| Document | Purpose |
|----------|---------|
| [architecture.md](architecture.md) | System architecture, script types, metadata |
| [menu-system.md](menu-system.md) | Dialog tool usage and widgets |
| [categories.md](categories.md) | Tool category definitions |
| [services-dependencies.md](services-dependencies.md) | Service startup order and dependencies |

---

## Services

| Document | Purpose |
|----------|---------|
| [services.md](services.md) | Services overview |
| [services-nginx.md](services-nginx.md) | Nginx reverse proxy service |
| [services-otel.md](services-otel.md) | OTEL monitoring service |

---

## Testing & Release

| Document | Purpose |
|----------|---------|
| [testing.md](testing.md) | Running tests and adding tests for scripts |
| [testing-maintenance.md](testing-maintenance.md) | Maintaining the test framework |
| [CI-CD.md](CI-CD.md) | GitHub Actions and pre-merge checklist |
| [RELEASING.md](RELEASING.md) | How to bump versions and create releases |
| [services-monitoring-requirements.md](services-monitoring-requirements.md) | Container monitoring requirements |

---

## AI Developer Documentation

For AI coding assistants (Claude, Copilot, etc.), see [docs/ai-developer/](../ai-developer/):

- **WORKFLOW.md** - End-to-end flow from idea to implemented feature
- **PLANS.md** - Plan structure, templates, and how to write plans
- **plans/** - Implementation plans (backlog, active, completed)
