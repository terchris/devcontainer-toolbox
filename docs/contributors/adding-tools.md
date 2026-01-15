# Adding New Tools

How to extend devcontainer-toolbox with new tools, configurations, and services.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Creating Install Scripts](creating-install-scripts.md) | Complete guide to `install-*.sh` scripts |
| [Creating Service Scripts](creating-service-scripts.md) | Complete guide to `service-*.sh` scripts |
| [Libraries Reference](libraries.md) | Shared library functions |
| [Architecture](architecture.md) | System architecture overview |
| [Categories](categories.md) | Tool category definitions |

---

## Quick Start

### Install Script (install-*.sh)

Install tools, runtimes, or development environments.

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

# 4. Update docs
.devcontainer/manage/generate-manual.sh
```

See [Creating Install Scripts](creating-install-scripts.md) for full details.

### Config Script (config-*.sh)

Configure user settings, credentials, or identities.

```bash
# 1. Copy template
cp .devcontainer/additions/addition-templates/_template-config-script.sh \
   .devcontainer/additions/config-mytool.sh

# 2. Edit metadata
SCRIPT_NAME="My Tool Configuration"
SCRIPT_DESCRIPTION="Configure My Tool settings"
SCRIPT_CATEGORY="INFRA_CONFIG"
SCRIPT_CHECK_COMMAND="[ -f ~/.mytool-config ]"

# 3. Implement --verify for restoration
# 4. Implement interactive configuration
```

See [Creating Install Scripts](creating-install-scripts.md) (config section) for full details.

### Service Script (service-*.sh)

Manage long-running background services.

```bash
# 1. Copy template
cp .devcontainer/additions/addition-templates/_template-service-script.sh \
   .devcontainer/additions/service-myservice.sh

# 2. Edit metadata
SCRIPT_NAME="My Service"
SCRIPT_DESCRIPTION="My background service"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"

# 3. Define SCRIPT_COMMANDS array
# 4. Implement service functions
```

See [Creating Service Scripts](creating-service-scripts.md) for full details.

---

## Categories

Scripts are grouped by category in the dev-setup menu:

| Category | Use for |
|----------|---------|
| `LANGUAGE_DEV` | Programming languages (Python, Go, etc.) |
| `AI_TOOLS` | AI/ML tools |
| `CLOUD_TOOLS` | Cloud platform tools (Azure, AWS) |
| `DATA_ANALYTICS` | Data tools (Jupyter, pandas) |
| `BACKGROUND_SERVICES` | Background services (nginx, monitoring) |
| `INFRA_CONFIG` | Infrastructure tools (Kubernetes, Terraform) |

See [categories.md](categories.md) for the full list and descriptions.

---

## Script Discovery

Scripts are automatically discovered by `dev-setup` based on:
- Filename pattern: `install-*.sh`, `config-*.sh`, `service-*.sh`, `cmd-*.sh`
- Presence of `SCRIPT_ID` or `SCRIPT_NAME` metadata

No registration needed - just create the file with correct metadata.

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

## Testing

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
.devcontainer/additions/tests/run-all-tests.sh static install-mytool.sh

# Run shellcheck
shellcheck .devcontainer/additions/install-mytool.sh
```

See [testing.md](testing.md) for more details on the test framework.

---

## User-Facing Documentation

Some documentation files live alongside code (not in `docs/`) because they're meant for end users:

| File | Purpose | When to Update |
|------|---------|----------------|
| `.devcontainer.secrets/README-secrets.md` | Explains secrets folder to users | When adding new secret types or changing storage patterns |

---

## After Adding a Script

Regenerate documentation (run inside the devcontainer):

```bash
.devcontainer/manage/generate-manual.sh
```

This updates `docs/tools.md` so users can see the new tool.

---

## Submitting Your Contribution

1. **Fork the repository** on GitHub

2. **Create a feature branch:**
   ```bash
   git checkout -b feature/add-elixir-support
   ```

3. **Make your changes:**
   - Add your script
   - Run tests: `.devcontainer/additions/tests/run-all-tests.sh static`
   - Regenerate docs: `.devcontainer/manage/generate-manual.sh`

4. **Commit and push:**
   ```bash
   git add .
   git commit -m "feat: add Elixir development environment"
   git push -u origin feature/add-elixir-support
   ```

5. **Create a Pull Request** on GitHub

See [CI-CD.md](CI-CD.md) for what checks run on your PR.
