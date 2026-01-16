---
title: Contributing
sidebar_position: 1
---

# Contributing to DevContainer Toolbox

Thank you for your interest in contributing! This guide will help you get started.

## Ways to Contribute

| Contribution | Description |
|--------------|-------------|
| **Add a tool** | Create install scripts for new languages, frameworks, or tools |
| **Fix bugs** | Fix issues in existing scripts |
| **Improve docs** | Enhance documentation or add examples |
| **Report issues** | File bug reports or feature requests on GitHub |

## Quick Start

### 1. Fork and Clone

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/devcontainer-toolbox.git
cd devcontainer-toolbox
```

### 2. Open in Devcontainer

```bash
code .
# Click "Reopen in Container" when prompted
```

### 3. Create a Branch

```bash
git checkout -b feature/my-contribution
```

### 4. Make Your Changes

- Add scripts to `.devcontainer/additions/`
- Run tests: `dev-test`
- Preview docs: `dev-docs`

### 5. Submit a Pull Request

```bash
git add .
git commit -m "feat: add my contribution"
git push -u origin feature/my-contribution
```

Then create a Pull Request on GitHub.

---

## Documentation

### Getting Started

| Guide | Description |
|-------|-------------|
| [Adding Tools](adding-tools) | Overview of adding new tools |
| [Testing](testing) | Running and writing tests |
| [CI/CD](ci-cd) | GitHub Actions and automated checks |
| [Releasing](releasing) | Version bumping and releases |
| [Documentation Website](website) | Working with this Docusaurus site |

### Creating Scripts

| Guide | Description |
|-------|-------------|
| [Creating Install Scripts](scripts/install-scripts) | Complete guide to `install-*.sh` scripts |

### Architecture & Reference

| Guide | Description |
|-------|-------------|
| [System Architecture](architecture) | Design patterns and data flow |
| [Categories Reference](architecture/categories) | Valid tool categories |
| [Libraries Reference](architecture/libraries) | Shared library functions |
| [Menu System](architecture/menu-system) | Dialog TUI reference |

### Services

| Guide | Description |
|-------|-------------|
| [Services Overview](services) | Built-in services documentation |

---

## Contribution Guidelines

### Code Style

- Use `shellcheck` for all bash scripts
- Follow existing patterns in the codebase
- Include proper metadata in all scripts

### Commit Messages

Use conventional commit format:

```
feat: add Elixir development environment
fix: correct Python path in install script
docs: update getting started guide
chore: bump version to 1.2.0
```

### Pull Request Process

1. **Tests must pass** - CI runs automatically on your PR
2. **One feature per PR** - Keep PRs focused
3. **Update docs if needed** - CI auto-updates generated docs after merge
4. **Version bump** - If your change should reach users, bump `version.txt`

---

## Getting Help

- **Questions?** Open a [GitHub Discussion](https://github.com/terchris/devcontainer-toolbox/discussions)
- **Found a bug?** Open an [Issue](https://github.com/terchris/devcontainer-toolbox/issues)
- **Want to chat?** Comment on an existing issue or discussion

---

## Recognition

All contributors are appreciated! Your contributions help make development environments better for everyone.
