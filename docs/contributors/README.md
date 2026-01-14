# Contributor Documentation

This folder contains documentation for developers who maintain and extend devcontainer-toolbox.

## Structure

```
docs/contributors/
├── README.md                 # This file
├── PLANS.md                  # How to write and manage plans
├── WORKFLOW.md               # Issue to implementation flow
├── RELEASING.md              # How to create new versions
├── adding-tools.md           # How to add new install scripts
├── architecture.md           # System architecture overview
├── categories.md             # Tool category reference
├── service-dependencies.md   # Service dependency flow
├── monitoring-requirements.md # Container monitoring requirements
└── plans/
    ├── active/               # Currently being worked on
    ├── backlog/              # Planned but not started
    └── completed/            # Implemented plans (historical reference)
```

## Key Documents

### Workflow

| Document | Purpose |
|----------|---------|
| `WORKFLOW.md` | End-to-end flow from idea to implemented feature (start here) |
| `PLANS.md` | Plan structure, templates, and how to write plans |
| `RELEASING.md` | How to bump versions and create releases |

### Technical

| Document | Purpose |
|----------|---------|
| `adding-tools.md` | How to add new install scripts |
| `architecture.md` | System architecture, script types, metadata, libraries |
| `categories.md` | Tool category definitions |
| `service-dependencies.md` | Service startup order and dependencies |
| `monitoring-requirements.md` | Container monitoring requirements |

## Plans

Plans document implementation decisions and approaches. They're kept for historical context so LLMs can understand why things were built a certain way.

- **active/** - Currently being implemented. Check before starting related work.
- **backlog/** - Planned but not started. May become outdated.
- **completed/** - Implemented. Read these to understand architectural decisions.

### File Types

| Type | When to use |
|------|-------------|
| `PLAN-*.md` | Solution is clear, ready to implement |
| `INVESTIGATE-*.md` | Needs research first, approach unclear |

### Quick Start

Tell Claude:
```
"I want to add feature X"
```

or
```
"Fix problem Y"
```

See `WORKFLOW.md` for the full flow.

