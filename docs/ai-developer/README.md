# AI Developer Documentation

Instructions for AI coding assistants (Claude, Copilot, etc.) working on devcontainer-toolbox.

---

## Documents

| Document | Purpose |
|----------|---------|
| [WORKFLOW.md](WORKFLOW.md) | End-to-end flow from idea to implemented feature (start here) |
| [PLANS.md](PLANS.md) | Plan structure, templates, and how to write plans |
| [CREATING-SCRIPTS.md](CREATING-SCRIPTS.md) | How to create new install/service/config scripts |
| [CI-CD.md](../contributors/CI-CD.md) | GitHub Actions, versioning, and pre-merge checklist |

---

## Plans Folder

Implementation plans are stored in `plans/`:

```
plans/
├── active/      # Currently being worked on (max 1-2 at a time)
├── backlog/     # Approved plans waiting for implementation
└── completed/   # Done - kept for reference
```

### File Types

| Type | When to use |
|------|-------------|
| `PLAN-*.md` | Solution is clear, ready to implement |
| `INVESTIGATE-*.md` | Needs research first, approach unclear |

---

## Quick Reference

### When user says "I want to add X" or "Fix Y":

1. Create `PLAN-*.md` in `plans/backlog/`
2. Ask user to review the plan
3. Wait for approval before implementing

### When user approves a plan:

1. Ask: "Do you want to work on a feature branch? (recommended)"
2. Create branch if yes
3. Move plan to `plans/active/`
4. Implement phase by phase
5. Ask user to confirm after each phase

### When implementation is complete:

1. Move plan to `plans/completed/`
2. Create Pull Request if on feature branch

### When creating new tools or services:

1. Read [CREATING-SCRIPTS.md](CREATING-SCRIPTS.md) for patterns and templates
2. Follow the metadata requirements exactly
3. **Tests must pass** - Run before committing: `.devcontainer/additions/tests/run-all-tests.sh static <script>`
4. CI will reject PRs with failing tests

---

## Related Documentation

- [Contributor docs](../contributors/) - Technical documentation for human developers
- [CLAUDE.md](../../CLAUDE.md) - Project-specific Claude Code instructions
