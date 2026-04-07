# Investigate: dev-setup Direct Script Execution

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Allow `dev-setup` to accept a script ID as a parameter to run a script directly without navigating the interactive menu.

**Priority**: Medium — improves UX for documentation, AI assistants, and power users

**Last Updated**: 2026-04-07

**Related**: [INVESTIGATE-simplify-initial-dct-experience.md](INVESTIGATE-simplify-initial-dct-experience.md)

---

## Problem

Currently `dev-setup` is menu-only. To install a tool or run a config, the user must:
1. Run `dev-setup`
2. Navigate to the correct category
3. Find the script
4. Select it

This makes it hard to:
- Give users a copy-paste command in docs or help text (e.g., "run dev-setup config-devcontainer-identity")
- Let AI assistants tell users exactly what to run
- Reference specific scripts in error messages ("to fix this, run ...")
- Let power users skip the menu

## Proposed Interface

```bash
dev-setup                                    # Interactive menu (current behavior)
dev-setup config-devcontainer-identity       # Run specific config script directly
dev-setup install-fwk-docusaurus             # Run specific install script directly
dev-setup install-dev-golang --version 1.26  # Pass flags through to the script
dev-setup --list                             # Human-readable list of all available scripts
```

## Where This Helps

### Startup messages

Current:
```
⚠️  Git identity not configured - run 'dev-setup' to set your name and email
```

Better:
```
⚠️  Git identity not configured - run: dev-setup config-devcontainer-identity
```

### Documentation

Current: "Open dev-setup, navigate to Setup & Configuration, select Git Identity"

Better: "Run `dev-setup config-devcontainer-identity`"

### AI assistants

An AI assistant can tell the user exactly: `dev-setup install-dev-golang` instead of walking them through a menu.

### Error recovery

```
❌ kubectl not found. Install it with: dev-setup install-tool-kubernetes
```

---

## Questions to Answer

1. How does `dev-setup.sh` currently resolve script IDs to file paths? Does it use `SCRIPT_ID` metadata?
2. Should `dev-setup <id>` run the script with default flags, or show the script's own menu (for cmd/service scripts that have subcommands)?
3. Should `--list` output be grouped by category like the menu, or a flat list?
4. Should tab-completion be supported? (bash completion for script IDs)
5. What about scripts with `--version` or other flags — should `dev-setup install-dev-golang --version 1.26` pass `--version 1.26` through?

---

## Next Steps

- [ ] Check how `dev-setup.sh` currently discovers and runs scripts
- [ ] Prototype: add argument parsing to `dev-setup.sh` main function
- [ ] Implement `dev-setup <script-id>` direct execution
- [ ] Implement `dev-setup --list` for human-readable script listing
- [ ] Update startup messages to use direct commands
- [ ] Update documentation with direct command examples
