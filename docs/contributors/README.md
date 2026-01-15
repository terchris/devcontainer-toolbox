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
├── categories.md                  # Tool category reference
├── service-dependencies.md        # Service dependency flow
│
├── infrastructure.md              # Infrastructure services index
├── infrastructure-nginx.md        # Nginx reverse proxy
├── infrastructure-otel.md         # OTEL monitoring
│
├── testing.md                     # Test framework
└── monitoring-requirements.md     # Container monitoring requirements
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
| [categories.md](categories.md) | Tool category definitions |
| [service-dependencies.md](service-dependencies.md) | Service startup order and dependencies |

---

## Infrastructure

| Document | Purpose |
|----------|---------|
| [infrastructure.md](infrastructure.md) | Infrastructure services overview |
| [infrastructure-nginx.md](infrastructure-nginx.md) | Nginx reverse proxy documentation |
| [infrastructure-otel.md](infrastructure-otel.md) | OTEL monitoring documentation |

---

## Testing & Release

| Document | Purpose |
|----------|---------|
| [testing.md](testing.md) | Test framework and how to run tests |
| [RELEASING.md](RELEASING.md) | How to bump versions and create releases |
| [monitoring-requirements.md](monitoring-requirements.md) | Container monitoring requirements |

---

## AI Developer Documentation

For AI coding assistants (Claude, Copilot, etc.), see [docs/ai-developer/](../ai-developer/):

- **WORKFLOW.md** - End-to-end flow from idea to implemented feature
- **PLANS.md** - Plan structure, templates, and how to write plans
- **plans/** - Implementation plans (backlog, active, completed)
