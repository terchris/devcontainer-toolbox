# Investigate: AI Workflow Installer Tool

## Status: Backlog

**Goal**: Determine the best approach for creating a tool that helps developers set up AI coding assistant workflows in their projects.

**Priority**: Medium

**Last Updated**: 2026-01-15

---

## Questions to Answer

1. What existing AI workflow systems/methodologies exist beyond our simple PLANS.md/WORKFLOW.md approach?
2. How should the tool be implemented (install script, dev-template, config-script)?
3. How do we package multiple workflow options for user selection?
4. What files and folder structure should each workflow option include?
5. Should workflows be bundled in the toolbox or fetched from external sources?

---

## Current State

We have a simple AI workflow system:
- `docs/ai-developer/PLANS.md` - Plan structure and templates
- `docs/ai-developer/WORKFLOW.md` - End-to-end implementation flow
- `docs/ai-developer/plans/` - backlog/, active/, completed/ folders
- `CLAUDE.md` - Project-specific Claude Code instructions

This works well but:
- Only available in devcontainer-toolbox itself
- Other projects don't have this structure
- More advanced workflows may exist that some developers prefer

---

## Research: Existing AI Workflow Systems

### 1. Our Simple System (devcontainer-toolbox)
**Type:** Plan-based workflow

**Files:**
- PLANS.md - Templates and structure
- WORKFLOW.md - Process documentation
- CLAUDE.md - AI-specific instructions
- plans/ folder with backlog/active/completed

**Pros:**
- Simple and lightweight
- Clear phase-based implementation
- User confirmation at each step
- Feature branch workflow

**Cons:**
- Manual process
- No automated validation
- Single AI assistant focus (Claude)

### 2. Cursor Rules (.cursorrules)
**Type:** AI behavior configuration

**Description:** Single file that configures Cursor AI behavior for the project.

**Research needed:**
- [ ] What does a typical .cursorrules file contain?
- [ ] Can it be combined with our workflow?

### 3. Aider Conventions
**Type:** AI pair programming conventions

**Description:** Aider uses conventions files and specific patterns.

**Research needed:**
- [ ] What files/conventions does Aider use?
- [ ] How does their workflow differ?

### 4. GitHub Copilot Workspace
**Type:** Task-based planning

**Description:** Uses issue-to-PR workflow with AI planning.

**Research needed:**
- [ ] Can we replicate parts of this workflow locally?
- [ ] What structure do they use?

### 5. Other Systems to Research
- [ ] Cline (VS Code extension) - any specific conventions?
- [ ] Continue.dev - configuration patterns?
- [ ] Custom GPT instructions patterns
- [ ] Anthropic's recommended Claude project setup

---

## Options for Implementation

### Option A: Install Script (install-ai-workflow.sh)

Create an install script in `.devcontainer/additions/` that:
- Shows menu of available workflow options
- Copies selected workflow files to user's project
- Creates CLAUDE.md or equivalent

**Pros:**
- Consistent with existing toolbox patterns
- Uses familiar install/uninstall model
- Can be selected via dev-setup menu

**Cons:**
- Installs to devcontainer, not user's project root
- May need special handling for project-level files

### Option B: Template via dev-template

Add AI workflow as a template option:
- User runs `dev-template`
- Selects "AI Workflow" category
- Chooses specific workflow system
- Files copied to project root

**Pros:**
- Templates already support project-level files
- User explicitly chooses where files go
- Can include multiple workflow variations

**Cons:**
- Templates are typically for project scaffolding
- May not fit the "add to existing project" use case

### Option C: Config Script (config-ai-workflow.sh)

Create a config script that:
- Detects existing AI config files
- Offers to set up or enhance workflow
- Works at project level, not devcontainer level

**Pros:**
- Config scripts are for project configuration
- Can detect and merge with existing setups
- Non-destructive approach

**Cons:**
- Config scripts are less common in our toolbox
- Need to define clear scope

### Option D: Dedicated dev-ai-workflow command

Create new `dev-ai-workflow` command that:
- Lists available workflow systems
- Lets user select and configure
- Manages workflow files separately from tools/services

**Pros:**
- Clear dedicated purpose
- Can include update/migrate functionality
- Separate from install scripts complexity

**Cons:**
- New command to maintain
- Adds complexity to dev-* command set

---

## Workflow Package Structure

Each workflow option could be packaged as:

```
.devcontainer/additions/ai-workflows/
├── simple/                    # Our current system
│   ├── manifest.json          # Name, description, files list
│   ├── PLANS.md
│   ├── WORKFLOW.md
│   ├── CLAUDE.md.template
│   └── README.md
├── cursor/                    # Cursor-focused
│   ├── manifest.json
│   ├── .cursorrules.template
│   └── README.md
├── advanced/                  # More comprehensive
│   ├── manifest.json
│   ├── PLANS.md
│   ├── WORKFLOW.md
│   ├── CLAUDE.md.template
│   ├── .cursorrules.template
│   └── plans/
│       └── .gitkeep
└── minimal/                   # Just the essentials
    ├── manifest.json
    └── CLAUDE.md.template
```

---

## Questions for User

1. Should this tool support multiple AI assistants (Claude, Cursor, Copilot) or focus on one?
2. Should workflows be mutually exclusive or combinable?
3. Where should the files be installed - project root or docs/?
4. Should there be an "update" mechanism when we improve workflows?

---

## Recommendation

*To be determined after research and user input*

---

## Next Steps

- [ ] Research Cursor rules format and best practices
- [ ] Research Aider conventions
- [ ] Research other AI coding assistant configurations
- [ ] Decide on implementation approach (Option A, B, C, or D)
- [ ] Create PLAN-ai-workflow-installer.md with chosen approach
