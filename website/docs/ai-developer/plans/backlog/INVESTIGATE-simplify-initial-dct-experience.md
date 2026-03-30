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

Container starts, user is inside devcontainer.

### Step 4: User runs dev-help

*(To be documented — what does the user see?)*

### Step 5: User needs to figure out what to do next

*(This is where the experience breaks down — what should a new user do?)*

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
