---
title: Adding Tools
sidebar_position: 2
---

# Adding New Tools

How to extend devcontainer-toolbox with new tools, configurations, and services.

## Script Types

| Type | Pattern | Purpose |
|------|---------|---------|
| Install | `install-*.sh` | Install tools, runtimes, CLIs |
| Config | `config-*.sh` | Configure settings, credentials |
| Service | `service-*.sh` | Manage background services |
| Command | `cmd-*.sh` | Multi-command utilities |

---

## Quick Start: Install Script

```bash
# 1. Copy template
cp .devcontainer/additions/addition-templates/_template-install-script.sh \
   .devcontainer/additions/install-mytool.sh

# 2. Edit metadata
SCRIPT_ID="mytool"
SCRIPT_NAME="My Tool"
SCRIPT_DESCRIPTION="Install My Tool"
SCRIPT_CATEGORY="LANGUAGE_DEV"
SCRIPT_CHECK_COMMAND="command -v mytool >/dev/null 2>&1"

# 3. Test
.devcontainer/additions/install-mytool.sh --help
.devcontainer/additions/install-mytool.sh

# 4. Run automated tests
dev-test static install-mytool.sh
```

---

## Categories

Scripts are grouped by category in the `dev-setup` menu:

| Category | Use for |
|----------|---------|
| `LANGUAGE_DEV` | Programming languages (Python, Go, etc.) |
| `AI_TOOLS` | AI/ML tools |
| `CLOUD_TOOLS` | Cloud platform tools (Azure, AWS) |
| `DATA_ANALYTICS` | Data tools (Jupyter, pandas) |
| `BACKGROUND_SERVICES` | Background services (nginx, monitoring) |
| `INFRA_CONFIG` | Infrastructure tools (Kubernetes, Terraform) |

---

## Script Discovery

Scripts are automatically discovered by `dev-setup` based on:
- Filename pattern: `install-*.sh`, `config-*.sh`, `service-*.sh`, `cmd-*.sh`
- Presence of `SCRIPT_ID` or `SCRIPT_NAME` metadata

No registration needed - just create the file with correct metadata.

---

## Required Metadata

Every script must have these fields at the top:

```bash
# SCRIPT_ID: unique-identifier
# SCRIPT_NAME: Human Readable Name
# SCRIPT_DESCRIPTION: What this script does
# SCRIPT_CATEGORY: LANGUAGE_DEV|CLOUD_TOOLS|AI_ML_TOOLS|DATA_ANALYTICS|INFRASTRUCTURE
# SCRIPT_CHECK_COMMAND: command --version  # How to verify installation
```

---

## Templates

Available in `.devcontainer/additions/addition-templates/`:

| Template | Purpose |
|----------|---------|
| `_template-install-script.sh` | Install tools/languages |
| `_template-config-script.sh` | Configuration scripts |
| `_template-service-script.sh` | Background services |
| `_template-cmd-script.sh` | Utility commands |

---

## Testing Your Script

Run these inside the devcontainer:

```bash
# Test help
.devcontainer/additions/install-mytool.sh --help

# Test install
.devcontainer/additions/install-mytool.sh

# Verify in menu
dev-setup
# Navigate to your category

# Test uninstall
.devcontainer/additions/install-mytool.sh --uninstall

# Run automated tests
dev-test static install-mytool.sh
dev-test unit install-mytool.sh
```

---

## Documentation

Documentation is **auto-updated by CI** after you merge your PR. No manual step needed.

To preview docs locally before merging:

```bash
dev-docs
```

---

## Submitting Your Contribution

1. **Fork the repository** on GitHub

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/add-elixir-support
   ```

3. **Make your changes:**
   - Add your script
   - Run tests: `dev-test static`
   - (Optional) Preview docs: `dev-docs`

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "feat: add Elixir development environment"
   git push -u origin feature/add-elixir-support
   ```

5. **Create a Pull Request** on GitHub

---

## Advanced Documentation

For complete details, see the repository docs:

- `docs/contributors/creating-install-scripts.md` - Full install script guide
- `docs/contributors/creating-service-scripts.md` - Full service script guide
- `docs/contributors/libraries.md` - Library functions reference
- `docs/contributors/architecture.md` - System architecture
