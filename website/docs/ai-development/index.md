---
title: Developing with AI
sidebar_position: 1
---

# Developing with AI

Watch an AI implement a complete feature:

![AI implementing a development tool](/img/ai-implement-plan-teaser.gif)
*30-second teaser at 4x speed. The user mostly just confirms each phase.*

This is Claude Code adding Bash development tools to devcontainer-toolbox. The AI:
- Created the install script
- Added VS Code extensions
- Ran tests to verify everything works
- Updated documentation

**How?** Three things made this possible: a cage, a plan, and tests.

---

## 1. The Cage: Keep AI Contained

AI coding assistants can read files, write code, and run commands. You don't want them doing this on your main machine.

**Run the AI inside a devcontainer.**

```
┌─────────────────────────────────────────────────┐
│  Your Machine                                   │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │  Devcontainer (the cage)                  │  │
│  │                                           │  │
│  │  ┌─────────────────────────────────────┐  │  │
│  │  │  /workspace (your repo)             │  │  │
│  │  │  - AI can only see this folder      │  │  │
│  │  │  - All changes are visible to you   │  │  │
│  │  └─────────────────────────────────────┘  │  │
│  │                                           │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ~/Documents, ~/.ssh, ~/other-projects          │
│  (AI cannot access these)                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

The devcontainer is isolated. It can't see your home directory, SSH keys, or other projects. If something goes wrong, rebuild and start fresh.

---

## 2. The Plan: Stop AI from Hallucinating

Without guidance, AI assistants:
- Jump straight into coding without understanding the scope
- Invent file locations that don't exist
- Create code that doesn't match your patterns
- Forget steps mid-implementation

**Make the AI create a plan first.**

Instead of "implement feature X", say:

```
we need to create a plan for adding a new install script
```

The AI reads your documentation and creates a structured plan:

![AI creating a plan](/img/ai-make-plan.png)

Notice what happens:
1. AI reads your plan templates
2. AI reads your code conventions
3. AI creates a phased plan with specific tasks
4. **You review before any code is written**

The plan is a markdown file. Edit it if something's wrong. Only after you approve does the AI start coding.

:::tip Why Plans Work
**They reduce hallucinations.** The AI follows your documented patterns instead of guessing.

**They enable course correction.** When something goes wrong, point to the plan. There's a shared reference.

**They create documentation.** Completed plans show what was implemented and why.
:::

Learn more: [Creating Plans](creating-plans)

---

## 3. The Tests: AI Self-Correction

Plans reduce errors but don't eliminate them. Tests catch what plans miss.

```bash
# AI runs tests after making changes
dev-test static install-dev-bash.sh

# Test failed: Missing SCRIPT_CATEGORY metadata
# AI: "I see the test failed. Let me add the missing metadata..."
```

When tests exist:
1. The AI runs them after changes
2. Failures tell the AI exactly what's wrong
3. The AI fixes issues before you even see them

Tests turn the AI into a self-correcting system.

---

## The Three Layers

| Layer | What it does |
|-------|--------------|
| **Devcontainer** | Isolates AI to your repo - protects your machine |
| **Plans** | Guides AI behavior - reduces hallucinations |
| **Tests** | Validates AI output - catches mistakes automatically |

1. **Cage it** - Devcontainer limits what the AI can access
2. **Guide it** - Plans keep the AI on track
3. **Verify it** - Tests catch errors before you do

---

## Getting Started

### 1. Install Claude Code

```bash
dev-setup
# Select "Claude Code" from AI & Machine Learning Tools
```

Or install directly:
```bash
.devcontainer/additions/install-dev-ai-claudecode.sh
```

### 2. Configure API Key

Create the environment file:
```bash
mkdir -p .devcontainer.secrets/env-vars
echo "ANTHROPIC_API_KEY=your-api-key" > .devcontainer.secrets/env-vars/anthropic.env
```

### 3. Start Using It

```bash
claude
```

Then tell it what you want to build. It will create a plan for your review.

---

## Next Steps

- [Workflow](workflow) - The full flow from idea to implementation
- [Creating Plans](creating-plans) - Plan templates and best practices
- [Claude Code Tool](../tools/claude-code) - Installation and configuration details
