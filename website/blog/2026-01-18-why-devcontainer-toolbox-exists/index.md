---
slug: why-devcontainer-toolbox-exists
title: "Why DevContainer Toolbox Exists: Sovereign Development for Norway"
authors: [terchris]
tags: [sovereignty, announcement]
image: ./featured.jpg
---

![DevContainer Toolbox](./featured.jpg)

What happens to your development workflow when the cloud services you depend on become unavailable?

This question drives everything we do with DevContainer Toolbox.

<!-- truncate -->

## The Problem: Cloud Dependency

Modern software development has become deeply dependent on cloud services. We use cloud IDEs, hosted CI/CD pipelines, remote development environments, and SaaS tools for everything from version control to deployment.

This works great - until it doesn't.

**Consider these scenarios:**
- Your cloud provider has a major outage
- Geopolitical events restrict access to services
- Sanctions affect software providers
- Your internet connection fails during a critical deadline
- Subscription costs become unsustainable

For Norwegian organizations, there's an additional concern: many of these services are subject to foreign laws like the US CLOUD Act, which can compel providers to hand over data regardless of where it's stored.

## The Solution: Local-First Development

DevContainer Toolbox provides complete, pre-configured development environments that run entirely on your machine. One command gives you:

- **Programming languages**: Python, Go, TypeScript, Rust, Java, .NET
- **Infrastructure tools**: Azure CLI, Kubernetes, Terraform, Docker
- **AI capabilities**: Ollama for local LLMs, AI coding assistants
- **Everything configured**: Linters, debuggers, formatters ready to use

No cloud accounts required. No subscriptions. No data leaving your computer.

## Part of SovereignSky

DevContainer Toolbox is part of [SovereignSky](https://sovereignsky.no), an initiative by [helpers.no](https://helpers.no) promoting digital sovereignty for Norway.

Digital sovereignty means having control over your digital infrastructure and data. For developers, this means:

| Principle | What It Means |
|-----------|---------------|
| **Local-first** | Your tools work without internet |
| **Open source** | You can inspect and modify everything |
| **No vendor lock-in** | Switch tools without losing your work |
| **Data privacy** | Your code stays on your machine |

## Totalforsvarsaret 2026

2026 is [Totalforsvarsaret](https://www.regjeringen.no/no/tema/forsvar/totalforsvaret/id2827649/) (Total Defense Year) in Norway - a nationwide focus on civil preparedness and resilience.

Part of civil preparedness is ensuring critical infrastructure can function independently. For software teams, this means having development environments that work without external dependencies.

DevContainer Toolbox contributes to this goal by providing development tools that:
- Work completely offline
- Run on standard hardware
- Require no external services
- Can be shared and replicated easily

## Get Started

Adding DevContainer Toolbox to your project takes one command:

```bash
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
```

Then open your project in VS Code and click "Reopen in Container."

Your development environment is now local, reproducible, and sovereign.

---

*DevContainer Toolbox is open source and welcomes contributions. Visit our [GitHub repository](https://github.com/terchris/devcontainer-toolbox) to get involved.*
