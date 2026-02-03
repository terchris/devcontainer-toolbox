---
sidebar_position: 8
---

# Troubleshooting

Common issues and solutions when using devcontainer-toolbox.

## Container Won't Start

### "Reopen in Container" not appearing

**Solution:** Make sure you have the Dev Containers extension installed in VS Code.

```
Extension ID: ms-vscode-remote.remote-containers
```

### Container build fails

**Solution:** Try rebuilding from scratch:

1. In VS Code: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
2. Or run: `dev-clean` and reopen

### Docker not running

**Solution:** Start Docker/Rancher Desktop and try again.

### Windows: "A mount config is invalid"

**Symptom:** Container fails to start with "A mount config is invalid. Make sure it has the right format and a secure folder that exists on the machine where Docker daemon is running."

**Cause:** This happens when `devcontainer.json` includes a Docker socket mount (`/var/run/docker.sock`) that doesn't exist on the Windows host. On Windows, the Docker daemon runs inside WSL2.

**Solution:** Re-run the Windows install command in your project folder to get an updated `devcontainer.json`:
```powershell
irm https://raw.githubusercontent.com/terchris/devcontainer-toolbox/main/install.ps1 | iex
```

---

## Git Issues

### Git identity not configured

**Symptom:** Commits fail with "Please tell me who you are"

**Solution:**
```bash
dev-check
```

Follow the prompts to set your name and email.

### Git credentials not working

**Solution:** Re-run configuration:
```bash
dev-check
```

Credentials are stored in `.devcontainer.secrets/` and restored on rebuild.

---

## Tool Installation Issues

### Tool not found after install

**Symptom:** Installed a tool but `command not found`

**Solution:** Open a new terminal. The PATH updates in new sessions.

Or source the profile:
```bash
source ~/.bashrc
```

### Install script fails

**Solution:** Check the logs:
```bash
ls /tmp/devcontainer-install/
cat /tmp/devcontainer-install/<script>-*.log
```

### Tool not auto-installing on rebuild

**Solution:** Make sure it's in `enabled-tools.conf`:
```bash
cat .devcontainer.extend/enabled-tools.conf
```

Add the tool ID if missing.

---

## Service Issues

### Service won't start

**Solution:** Check status and logs:
```bash
dev-services status
dev-services logs <service-name>
```

### Service not auto-starting

**Solution:** Check if enabled:
```bash
cat .devcontainer.extend/enabled-services.conf
```

Enable it:
```bash
dev-services enable <service-name>
```

---

## VS Code Issues

### Extensions not loading

**Solution:** Rebuild the container:
- `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Terminal not working

**Solution:** Try opening a new terminal:
- `Ctrl+Shift+`` (backtick)

---

## Update Issues

### dev-update permission denied

**Solution:** Run with sudo if needed, or check file permissions.

### Windows: dev-update says "Docker is not available"

**This is expected on Windows.** The Docker socket isn't mounted inside the container on Windows. `dev-update` will show you the exact command to run in your host terminal:

```powershell
docker pull ghcr.io/terchris/devcontainer-toolbox:latest
```

Then rebuild the container: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

### Update not applying

**Solution:** After `dev-update`, VS Code should prompt to rebuild. If not:
1. Check if version changed: `dev-help`
2. Manually rebuild: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"

---

## Reset Everything

If nothing else works, start fresh:

```bash
dev-clean
```

Then:
1. Close VS Code
2. Reopen the project
3. Click "Reopen in Container"

This rebuilds the container from scratch while preserving your:
- `.devcontainer.extend/` settings
- `.devcontainer.secrets/` credentials

---

## Getting Help

```bash
dev-help              # Show all commands
dev-setup             # Interactive menu
```

Still stuck? Check the [GitHub issues](https://github.com/terchris/devcontainer-toolbox/issues).
