# DevContainer Toolbox

A ready-to-use development environment that works the same on Windows, Mac, and Linux. Just open your project in VS Code, and everything is already set up for you.

## First Time Using This?

**What is a DevContainer?**
- A development environment that runs in a container
- Includes all the tools you need pre-installed
- Same setup for everyone on the team
- No need to install anything on your machine

**Learn More:**
- [Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers) - Official documentation
- [Get Started with Dev Containers](https://www.youtube.com/watch?v=b1RavPr_878&t=38s) - 5-minute video tutorial

## Getting Started (3 Steps)

1. **Open your repository in VS Code**
2. **When prompted, click "Reopen in Container"**
3. **Wait for setup to complete** (first time takes a few minutes)

That's it! You're ready to start developing.

## What is in the devcontainer

<TODO: create a table here with the list of the dev and tools that can be installed. 
Table heading: Name, Description   >


## Using the DevContainer

After the container starts, you have access to helpful commands:

### Main Command: `dev-setup`

This is your **one-stop menu** for managing your development environment.

```bash
dev-setup
```

From this menu you can:
- ✅ Install additional development tools (Python, TypeScript, Go, PHP, C-sharp, Rust, PoweShell etc.)
- ✅ Manage background services (nginx, OTEL monitoring, etc.)
- ✅ Configure settings (Git identity, credentials)
- ✅ View environment status

**Use this command for everything!** It's interactive and guides you through all options.

<TODO: dev-setup is a user friendly menu that starts scripts in .devcontainer/additions 
You can also run the scripts directly eg : ´.devcontainer/additions/install-dev-python.sh --help´
to see more info about the script >

### Other Useful Commands

```bash
dev-services status       # Quick check: what services are running?
check-configs             # Setup Git identity and credentials
show-environment          # See what's installed
```

<TODO: the great thing about working in a devcontainer is that you can install and messup the whole system and then just get back to the starting position by rebuilding the container. Use the ´clean-devcontainer´command to delete the devcontainer so that you get back to a fresh container when you start it again>

## Customizing for Your Project

Want to install project-specific packages or run setup scripts?

Edit this file: `.devcontainer.extend/project-installs.sh`

```bash
#!/bin/bash
set -e

printf "🔧 Running custom project-specific installations...\r\n"

# Install your project dependencies
cd /workspace
npm install

# Or any other setup you need
# pip install -r requirements.txt
# bash scripts/setup-database.sh

printf "✅ Custom project installations complete\r\n"
```

This runs automatically when the container is created. Perfect for:
- Installing npm/pip packages
- Setting up databases
- Generating code from schemas
- Any project-specific setup

## Need Help?

**Common issues:**

**Git identity not configured?**
```bash
check-configs
```

**Tool not working?**
```bash
dev-setup
# Select "Install Development Tools"
```

**Service not starting?**
```bash
dev-setup
# Select "Manage Services"
```

**Something went wrong?**
```bash
# Re-run the entire setup
bash /workspace/.devcontainer/manage/postCreateCommand.sh
```

## For Advanced Users

Want to dive deeper into how everything works?

### Technical Documentation

**Configuration:**
- [DevContainer Extensions](./.devcontainer.extend/README-devcontainer-extended.md) - Configure tools and services
- [Additions Framework](../additions/README-additions.md) - How install scripts work

**Services:**
- [Nginx Proxy](../additions/nginx/README-nginx.md) - Reverse proxy configuration
- [OpenTelemetry](../additions/otel/README-otel.md) - Monitoring and telemetry

**Development:**
- [Script Templates](../additions/addition-templates/README-additions-template.md) - Create new install scripts
- [Service Templates](../additions/addition-templates/README-service-template.md) - Create new services
- [Testing](../additions/addition-templates/tests/README-tests.md) - Test your scripts

### Architecture Overview

```
Container Creation
       ↓
Setup everything automatically
       ↓
Call your custom script (.devcontainer.extend/project-installs.sh)
       ↓
Done! Start developing
```

**Two Layers:**
1. **Framework** (.devcontainer/) - Pre-configured tools and scripts (don't modify)
2. **Your Project** (.devcontainer.extend/) - Your customizations (edit these)


### File Structure

```
.devcontainer/
├── docs/               # Documentation (you are here)
├── manage/             # Management commands (dev-setup, dev-services, etc.)
├── additions/          # Install scripts and services
└── devcontainer.json   # Container configuration

.devcontainer.extend/   # Your customizations
├── enabled-tools.conf
├── enabled-services.conf
└── project-installs.sh # Edit this for project setup


<TODO: include the .devcontainer.secrets>
```

## Questions?

- **"How do I install [tool]?"** → Run `dev-setup`
- **"How do I start [service]?"** → Run `dev-setup`
- **"How do I configure [setting]?"** → Run `check-configs`
- **"Where do I put project setup?"** → Edit `.devcontainer.extend/project-installs.sh`
- **"Something's broken!"** → Check the troubleshooting section above

**Everything else?** Check the [technical documentation links](#technical-documentation) above.
