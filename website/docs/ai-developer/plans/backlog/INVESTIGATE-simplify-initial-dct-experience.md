# Investigate: Simplify Initial DCT Experience

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Make the first-time experience of using devcontainer-toolbox simpler and more guided.

**Priority**: High

**Last Updated**: 2026-03-30

---

## Current First-Time Flow

### Step 1: User creates a repo and clones it

```
terje.christensen@MBP delete-test % ls -la
total 0
drwxr-xr-x@  3 terje.christensen  staff   96 Mar 30 12:52 .
drwxr-xr-x   6 terje.christensen  staff  192 Mar 30 12:52 ..
drwxr-xr-x@ 10 terje.christensen  staff  320 Mar 30 12:52 .git
```

Empty repo, only `.git/`.

### Step 2: User runs install script

```
terje.christensen@MBP delete-test % curl -fsSL https://raw.githubusercontent.com/helpers-no/devcontainer-toolbox/main/install.sh | bash
Installing devcontainer-toolbox from helpers-no/devcontainer-toolbox...

Downloading devcontainer.json from https://raw.githubusercontent.com/helpers-no/devcontainer-toolbox/main/devcontainer-user-template.json...
Created .devcontainer/devcontainer.json
Created .vscode/extensions.json with Dev Containers extension recommendation

Pulling container image: ghcr.io/helpers-no/devcontainer-toolbox:latest
(This may take a few minutes on first install...)
latest: Pulling from helpers-no/devcontainer-toolbox
Digest: sha256:8109c30665ae27b74475d40fc4e77845e996d650a461cd4f521da6eeee8e350c
Status: Image is up to date for ghcr.io/helpers-no/devcontainer-toolbox:latest
ghcr.io/helpers-no/devcontainer-toolbox:latest

✅ devcontainer-toolbox installed!

Next steps:
  1. Open this folder in VS Code
  2. When prompted, click 'Reopen in Container'
     (or run: Cmd/Ctrl+Shift+P > 'Dev Containers: Reopen in Container')
  3. Inside the container, run: dev-help
```

### Step 3: User opens VS Code and reopens in container

Container starts. When the terminal opens, the user sees this startup output:

```
  DevContainer Toolbox v1.7.10 - Type 'dev-help' for commands

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 DevContainer Toolbox — Starting up
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 Configuring git identity...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Logging to: /tmp/devcontainer-install/config-git-20260330-105429.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Git identity detected:
   Email:    vscode@localhost
   Provider: github
   Repo:     terchris/delete-test
   Branch:   HEAD
unknown
   Hostname: dev-vscode-localhost-devcontainer

🔐 Restoring Azure DevOps configuration...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Logging to: /tmp/devcontainer-install/config-azure-devops-20260330-105430.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Logging to: /tmp/devcontainer-install/config-host-info-20260330-105430.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🖥️  Host Information Detection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ℹ️  Detecting host information for telemetry...


🔧 Starting services...


🔄 Checking for script updates...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 First start — setting up container...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔐 Restoring saved configurations...

📦 Installing tools from enabled-tools.conf...
🛠️ Installing project-specific tools...

📋 Loading enabled tools from enabled-tools.conf...
   Found 0 enabled tools

ℹ️  No tools enabled for installation

🔧 Running project-installs.sh...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Startup complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Quick Start:
   dev-setup       Main menu - install tools, manage services
   dev-help        Show all available commands
   dev-check       Configure required settings (Git identity, etc.)

⚠️  Git identity not configured - run 'dev-setup' to set your name and email

💡 GitHub repository detected but not authenticated.
   To create pull requests and manage issues, run:
   gh auth login

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vscode ➜ /workspace (main) $
```

**Observations:**
- Lots of log output — startup is noisy for a first-time user
- "Restoring Azure DevOps configuration" — irrelevant for most new users
- "Host Information Detection" / "telemetry" — may concern privacy-aware users
- Git identity shows `vscode@localhost` — not the user's real identity
- "Found 0 enabled tools" / "No tools enabled" — feels like something is wrong
- The Quick Start section at the bottom is helpful but easy to miss in the wall of text
- Two warnings at the end (git identity, gh auth) — good, but user may not know what to do

### Git identity problem

The startup detects `Email: vscode@localhost` — this is the devcontainer default, not the user's real email. This is why it later warns "Git identity not configured". But the message says "run dev-setup to set your name and email" which forces the user through the full interactive menu just to set their name and email.

**Improvement idea:** Tell the user to run the config script directly:
```
⚠️  Git identity not configured. Run:
    dev-setup config-devcontainer-identity
```

This leads to a broader idea: **`dev-setup` should accept a script ID as a parameter** to run a script directly without the menu. This would make all these possible:

```bash
dev-setup                              # Interactive menu (current behavior)
dev-setup config-devcontainer-identity  # Run specific script directly
dev-setup install-fwk-docusaurus        # Run specific install directly
dev-setup --list                        # Human-readable list of all available scripts
```

**Why this matters:**
- New users get direct commands they can copy-paste, not "navigate the menu"
- Documentation and help text can reference specific commands
- AI assistants can tell users exactly what to run
- Power users skip the menu entirely
- `dev-setup --list` gives a human-readable overview (unlike `dev-tools` which outputs JSON for machines)

### Step 4: User runs dev-help

*(To be documented — what does the user see?)*

### Step 5: User needs to figure out what to do next

*(This is where the experience may break down — what should a new user do?)*

---

## Questions to Answer

1. What does a new user see when they first open the devcontainer? Is it overwhelming?
2. What does `dev-help` show? Is it enough to guide a beginner?
3. Should the install script do more? (e.g., ask what kind of project, run `dev-template` automatically)
4. Should there be a "first run" wizard inside the devcontainer?
5. Should `dev-template` or `dev-template-ai` be offered automatically on first start?
6. What's the minimum a user needs to do to get a "hello world" running?
7. How do other devcontainer-based systems handle onboarding? (GitHub Codespaces, Gitpod, etc.)

---

## Observations

*(To be filled in as we test and document the flow)*

---

## Options

*(To be determined after investigation)*

---

## Recommendation

*(To be determined after investigation)*

---

## Next Steps

- [ ] Document the full first-time flow from install to "hello world"
- [ ] Identify pain points and confusion in each step
- [ ] Research how Codespaces/Gitpod handle first-time onboarding
- [ ] Propose improvements
