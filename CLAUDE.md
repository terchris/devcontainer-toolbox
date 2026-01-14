# Claude Code Instructions

Project-specific instructions for Claude Code when working on devcontainer-toolbox.

## Plan Workflow

**IMPORTANT:** Read `docs/contributors/PLANS.md` for full plan structure, templates, and best practices.

When implementing a plan from `docs/contributors/plans/`:

1. **Read the full plan first** - understand all phases before starting
2. **Work phase by phase** - never skip ahead
3. **Update the plan file as you go:**
   - Mark current phase: `## Phase N: Name — IN PROGRESS`
   - Check off completed tasks: `- [x] Task description`
   - Mark finished phases: `## Phase N: Name — ✅ DONE`
4. **Stop after each phase** - ask user: "Phase N complete. Does this look good to continue?"
5. **Wait for user confirmation** before starting the next phase

## Creating Plans

When user requests a new feature or fix:

1. Read `docs/contributors/PLANS.md` for templates and structure
2. Create plan file in `docs/contributors/plans/backlog/`
3. Ask user to review the plan before implementing
4. Only move to `active/` after user approves

## Git Commits

- Ask for confirmation before running git commands (add, commit, push)
- Use feature branches for multi-phase work
- Commit after each phase (with user approval)

## Documentation

- User docs: `docs/`
- Contributor docs: `docs/contributors/`
- Plans: `docs/contributors/plans/`

## Key Files

- `version.txt` - Version number (update to trigger release)
- `.devcontainer.extend/` - User configuration
- `.devcontainer/manage/` - Dev commands (dev-setup, dev-help, etc.)
- `.devcontainer/additions/` - Install scripts
