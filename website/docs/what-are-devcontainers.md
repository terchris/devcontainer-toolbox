---
sidebar_position: 4
---

# What Are DevContainers?

New to containers? This guide explains the concepts in plain language.

## The Problem: "Works on My Machine"

Every developer has heard it: *"It works on my machine!"*

Setting up a development environment is painful:
- Installing the right versions of Python, Node, Go, etc.
- Configuring tools differently on Windows vs Mac vs Linux
- New team members spending days getting set up
- "It worked yesterday" bugs caused by system updates

## The Solution: Containers

A **container** is like a lightweight virtual machine that packages everything needed to run an application:
- Operating system libraries
- Programming languages
- Tools and utilities
- Configuration files

Unlike virtual machines, containers:
- Start in seconds (not minutes)
- Share your computer's resources efficiently
- Are defined by simple text files (easy to version control)

## What is a DevContainer?

A **DevContainer** (Development Container) is VS Code's way of using containers for development.

Instead of running your code on your laptop directly, you run it inside a container. But VS Code makes it seamless - it feels like you're working locally.

```
┌─────────────────────────────────────────────────┐
│  Your Computer (Windows/Mac/Linux)              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Container                               │   │
│  │                                          │   │
│  │  • Linux environment                     │   │
│  │  • Python, Node, Go, etc.               │   │
│  │  • Your project files (mounted)          │   │
│  │  • VS Code Server                        │   │
│  │                                          │   │
│  └─────────────────────────────────────────┘   │
│                     ↑                           │
│                     │                           │
│  ┌─────────────────────────────────────────┐   │
│  │  VS Code (on your desktop)              │   │
│  │  Connects to container transparently    │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Why Use DevContainers?

### 1. Consistent Environments

Everyone on your team gets the exact same setup. No more "works on my machine" problems.

### 2. Instant Onboarding

New team member? They just need VS Code and Docker. Open the project, click "Reopen in Container", and they're ready to code.

### 3. Experiment Freely

Messed something up? Delete the container and start fresh. Your code is safe (it lives on your computer, not in the container).

### 4. Keep Your Laptop Clean

Don't pollute your system with dozens of different language versions and tools. Everything stays in containers.

### 5. Production Parity

Develop in an environment similar to production. Catch issues before deployment.

## How It Works

1. **Configuration files** (`.devcontainer/`) define what goes in the container
2. **VS Code** reads these files and creates the container
3. **Your project folder** is mounted into the container (changes sync both ways)
4. **VS Code** connects to the container and you start coding

When you open a project with devcontainer config:

```
You open project in VS Code
         ↓
VS Code sees .devcontainer/ folder
         ↓
"Reopen in Container?" → Yes
         ↓
Docker builds/starts container
         ↓
VS Code connects to container
         ↓
You code normally (but inside container)
```

## Common Misconceptions

### "Containers are complicated"

With devcontainer-toolbox, you don't need to understand Docker. Just run the install command and VS Code handles the rest.

### "It will be slow"

Containers run at near-native speed. You won't notice a difference for most development work.

### "My files will be trapped in the container"

Nope! Your project files stay on your computer. They're just mounted into the container. Edit files in VS Code, and they update on your disk.

### "I need Linux to use containers"

Docker runs containers on Windows and Mac too. The container runs Linux internally, but you can use any host OS.

## What You Need

1. **Docker** - The container runtime
   - We recommend [Rancher Desktop](https://rancherdesktop.io/) (free, open source)
   - Docker Desktop also works (but requires paid license for companies)

2. **VS Code** - The editor
   - With [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

That's it! devcontainer-toolbox handles the rest.

## Learn More

- [Getting Started](getting-started) - Install and start using devcontainer-toolbox
- [VS Code DevContainers Docs](https://code.visualstudio.com/docs/devcontainers/containers) - Official documentation
- [5-minute Video Tutorial](https://www.youtube.com/watch?v=b1RavPr_878&t=38s) - See it in action
