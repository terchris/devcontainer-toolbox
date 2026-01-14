# DevContainer Toolbox

A comprehensive development container setup that provides a consistent development environment across Windows, Mac, and Linux. This toolbox includes configurations and tools for working with Azure infrastructure, data platforms, security operations, development, and monitoring.

## About

The DevContainer Toolbox provides:

- A pre-configured development environment using Debian 12 Bookworm
- Essential base tools including Azure CLI, Python, Node.js, and common command-line utilities
- Core VS Code extensions for Azure development, PowerShell, Markdown, and YAML support
- Extensible architecture allowing easy addition of role-specific tools
- Consistent environment across all development machines

## Problem Solved

- Eliminates "it works on my machine" issues by providing a standardized development environment
- Simplifies onboarding of new developers with a ready-to-use development setup
- Allows safe experimentation with new tools without affecting your local machine
- Provides a modular approach to adding role-specific development tools
- Ensures consistent tooling across team members regardless of their operating system

## What are DevContainers, and why is everyone talking about it?

- [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)
- [Youtube: Get Started with Dev Containers in VS Code](https://www.youtube.com/watch?v=b1RavPr_878&t=38s)

## Installation requirements

### Prerequisites

- Install Docker preferably via Rancher Desktop instead of Docker Desktop ([Read more about why here.](https://developer.ibm.com/blogs/awb-rancher-desktop-alternative-to-docker-desktop)). The [installation of Rancher Desktop is defined here](.devcontainer/setup/setup-windows.md).

### How to set it up in your project

For Windows users, the recommended approach is to clone the project inside your WSL distribution. Read more about running containers on Windows inside WSL [here](.devcontainer/wsl-readme.md).

1. Open a terminal in the directory where you want to add devcontainer support.
2. Run the install command for your platform:

**Mac/Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

If you see "running scripts is disabled on this system", use:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex"
```

3. Open the folder in VS Code: `code .`
4. When prompted, click "Reopen in Container"

### Updating

Updates are done from inside the devcontainer. Open your project in VS Code, start the devcontainer, then run:

```bash
dev-update
```

This checks for updates and applies them if available. Use `dev-update --force` to force an update.

### Available Commands

Inside the devcontainer, type `dev-` and press Tab to see all available commands:

- `dev-setup` - Configure which tools to enable
- `dev-services` - Manage development services
- `dev-template` - Create files from templates
- `dev-update` - Update devcontainer-toolbox
- `dev-help` - Show all available commands

(More detailed: [Copy the devcontainer-toolbox](.devcontainer/copy-devcontainer-toolbox.md))

Setting up the devcontainer:

- Windows users: See [setup-windows.md](.devcontainer/setup/setup-windows.md)
- Mac/Linux users: See [setup-mac.md](.devcontainer/setup/setup-mac.md)

- How to use a devcontainer: See [setup-vscode.md](.devcontainer/setup/setup-vscode.md)

## How to use dev container when developing

### Template library

We have a template library with a growing number of examples on how to use the devcontainer toolbox.
Here you will find examples on how to write web applications in C#, Python, Go, Java, PHP and TypeScript. And use frameworks like NextJs, React, Spring Boot, Express and more.

Check out the [Urbalurba Dev template library](https://github.com/terchris/urbalurba-dev-templates) for more information.

To select a template, run the following command inside the devcontainer:

```bash
dev-template
```

This will show you a list of all available templates. Select the one you want and it will be downloaded to your current working directory.

## How to extend the devcontainer

Add project dependencies to the script [project-installs.sh](.devcontainer.extend/project-installs.sh) and the next developer will thank you.
See [readme-devcontainer-extend.md](.devcontainer.extend/readme-devcontainer-extend.md)

## Alternate IDEs

This howto uses vscode. But you can use other IDEs.

| Extension                                                           | Description           |
| ------------------------------------------------------------------- | --------------------- |
| [JetBrains Rider](.devcontainer/howto/howto-ide-jetbrains-rider.md) | JetBrains Rider setup |
| [Visual Studio](.devcontainer/howto/howto-ide-visual-studio.md)     | Visual Studio setup   |

## Contribute

Follow the [instructions](.devcontainer/git-readme.md) here on how to contribute to the project.
