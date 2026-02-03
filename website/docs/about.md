---
title: About
sidebar_position: 99
description: DevContainer Toolbox - Sovereign development tools for Norwegian digital resilience
---

# About DevContainer Toolbox

**DevContainer Toolbox** provides developers with complete, pre-configured development environments that run locally on your machine. One command gives you everything you need - no cloud accounts, no subscriptions, no data leaving your computer.

---

## Why Local-First Development Matters

Modern development often depends on cloud services: cloud IDEs, hosted CI/CD, remote development environments. This creates dependencies that can become vulnerabilities.

**What happens when:**
- A cloud provider has an outage?
- Sanctions or policy changes restrict access?
- Your internet connection fails?
- Subscription costs become unsustainable?

DevContainer Toolbox ensures you can always work. Your tools run on your hardware, your data stays on your machine, and you remain productive regardless of external factors.

---

## Part of the SovereignSky Initiative

DevContainer Toolbox is part of [SovereignSky](https://sovereignsky.no), an initiative promoting digital sovereignty for Norway. Created by [helpers.no](https://helpers.no), SovereignSky addresses Norway's critical dependency on foreign cloud infrastructure.

### The Challenge

Norwegian organizations increasingly rely on cloud services subject to foreign laws (like the US CLOUD Act). This creates risks for:
- **Data privacy** - Foreign governments may compel access to data
- **Service continuity** - Geopolitical events could disrupt access
- **Digital resilience** - No local alternatives when cloud services fail

### Our Contribution

DevContainer Toolbox contributes to digital sovereignty by providing:

| Principle | How We Deliver |
|-----------|----------------|
| **Local-first** | All tools run on your machine |
| **Open source** | Full transparency, no vendor lock-in |
| **Offline capable** | Work without internet when needed |
| **Privacy respecting** | Your code and data never leave your computer |

---

## What DevContainer Toolbox Provides

### Development Languages
Python, Go, TypeScript, Rust, Java, .NET, and more - each with proper tooling, linters, and debuggers pre-configured.

### Cloud & Infrastructure Tools
Azure CLI, Kubernetes tools, Terraform, Docker - everything needed for modern infrastructure work, running locally.

### AI Development Tools
Ollama for local LLMs, AI coding assistants that work offline - bringing AI capabilities without sending your code to external services.

### Consistent Environments
Every developer on your team gets the exact same environment. No more "works on my machine" problems.

---

## Get Started

DevContainer Toolbox works with VS Code and GitHub Codespaces. Add it to any project:

```bash
# Mac/Linux
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash

# Windows PowerShell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

Then open in VS Code and click "Reopen in Container."

[Read the Getting Started guide](./getting-started.md) to learn more.

---

## Connect With Us

- **GitHub**: [devcontainer-toolbox](https://github.com/terchris/devcontainer-toolbox)
- **SovereignSky**: [sovereignsky.no](https://sovereignsky.no)
- **helpers.no**: [helpers.no](https://helpers.no)
