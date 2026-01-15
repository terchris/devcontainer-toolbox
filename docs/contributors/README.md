# Contributor Documentation

This folder contains technical documentation for developers who maintain and extend devcontainer-toolbox.

## Structure

```
docs/contributors/
├── README.md                 # This file
├── RELEASING.md              # How to create new versions
├── adding-tools.md           # How to add new install scripts
├── architecture.md           # System architecture overview
├── categories.md             # Tool category reference
├── service-dependencies.md   # Service dependency flow
└── monitoring-requirements.md # Container monitoring requirements
```

## Key Documents

| Document | Purpose |
|----------|---------|
| `RELEASING.md` | How to bump versions and create releases |
| `adding-tools.md` | How to add new install scripts |
| `architecture.md` | System architecture, script types, metadata, libraries |
| `categories.md` | Tool category definitions |
| `service-dependencies.md` | Service startup order and dependencies |
| `monitoring-requirements.md` | Container monitoring requirements |

## AI Developer Documentation

For AI coding assistants (Claude, Copilot, etc.), see [docs/ai-developer/](../ai-developer/):

- **WORKFLOW.md** - End-to-end flow from idea to implemented feature
- **PLANS.md** - Plan structure, templates, and how to write plans
- **plans/** - Implementation plans (backlog, active, completed)
