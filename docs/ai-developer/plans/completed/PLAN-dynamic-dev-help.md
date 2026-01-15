> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices
> - [CREATING-SCRIPTS.md](../../CREATING-SCRIPTS.md) - Script conventions

---

# Plan: Dynamic dev-help Command List

## Status: COMPLETED

**Goal**: Replace static command list in `dev-help` with dynamically generated list using existing `scan_manage_scripts` function.

**Created**: 2026-01-15

---

## Current State

`dev-help.sh` has a hardcoded list of commands:

```bash
cat << 'EOF'
Available dev-* commands:

  dev-setup      Configure which tools to enable
  dev-services   Manage development services
  ...
EOF
```

## Target State

Use `scan_manage_scripts` from `component-scanner.sh` to dynamically list all available commands with their descriptions.

---

## Phase 1: Update dev-help.sh — ✅ DONE

### Tasks

- [x] Source component-scanner.sh library
- [x] Replace static heredoc with dynamic generation using `scan_manage_scripts`
- [x] Format output to match current style (command + description)
- [x] Include dev-setup manually (excluded from scanner to avoid recursion)
- [x] Sort by category (SYSTEM_COMMANDS first, then CONTRIBUTOR_TOOLS)
- [x] Test output matches expected format

### Implementation

```bash
# Source component scanner
ADDITIONS_DIR="${SCRIPT_DIR}/../additions"
source "${ADDITIONS_DIR}/lib/component-scanner.sh"

# Generate command list
echo "Available dev-* commands:"
echo ""

# Build command list from scanner
while IFS=$'\t' read -r basename script_id name desc category check; do
    printf "  %-14s %s\n" "$script_id" "$desc"
done < <(scan_manage_scripts "$SCRIPT_DIR" | sort -t$'\t' -k5,5)

# Add dev-setup (excluded from scanner)
printf "  %-14s %s\n" "dev-setup" "Interactive menu for installing tools and managing services"

echo ""
echo "Run any command with --help for more details."
```

---

## Phase 2: Test and Verify — ✅ DONE

### Tasks

- [x] Run `dev-help` and verify output
- [x] Compare with old static output - should show same commands
- [x] Verify new commands (dev-test, dev-docs) now appear automatically
- [x] Test that --help still works

---

## Files to Modify

| File | Change |
|------|--------|
| `.devcontainer/manage/dev-help.sh` | Replace static list with dynamic generation |

## Benefits

1. **Auto-discovery**: New dev-* commands automatically appear in help
2. **Single source of truth**: Command descriptions come from script metadata
3. **Consistency**: Same data used in `dev-help` and `docs/commands.md`
4. **No maintenance**: No need to update help when adding new commands

---

## Notes

- `scan_manage_scripts` excludes `dev-welcome.sh` and `dev-setup.sh` by design
- Need to add `dev-setup` manually after the loop
- Category sorting ensures user-facing commands appear first
