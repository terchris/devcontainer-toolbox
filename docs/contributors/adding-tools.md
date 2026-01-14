# Adding New Tools

How to add new install scripts to devcontainer-toolbox.

**Related:** [architecture.md](architecture.md) - Full technical details on script types and metadata

---

## Quick Start

1. Copy the template
2. Update metadata
3. Add installation logic
4. Test it
5. Regenerate documentation

---

## Step 1: Copy the Template

```bash
cp .devcontainer/additions/addition-templates/_template-install-script.sh \
   .devcontainer/additions/install-mytool.sh
```

Naming convention: `install-<category>-<name>.sh`
- `install-dev-python.sh` - Development tool
- `install-tool-kubernetes.sh` - Infrastructure tool
- `install-srv-nginx.sh` - Service/server

---

## Step 2: Update Metadata

Edit the metadata section at the top of the script:

```bash
SCRIPT_ID="mytool"                           # Unique identifier
SCRIPT_VER="0.0.1"                           # Script version
SCRIPT_NAME="My Tool"                        # Display name (2-4 words)
SCRIPT_DESCRIPTION="Install My Tool"         # One-line description
SCRIPT_CATEGORY="LANGUAGE_DEV"               # Category for menu grouping
SCRIPT_CHECK_COMMAND="command -v mytool"     # How to check if installed
```

### Categories

| Category | Use for |
|----------|---------|
| `LANGUAGE_DEV` | Programming languages (Python, Go, etc.) |
| `AI_TOOLS` | AI/ML tools |
| `CLOUD_TOOLS` | Cloud platform tools (Azure, AWS) |
| `DATA_ANALYTICS` | Data tools (Jupyter, pandas) |
| `INFRA_CONFIG` | Infrastructure tools (Kubernetes, Terraform) |

See [categories.md](categories.md) for the full list.

### Check Command

The `SCRIPT_CHECK_COMMAND` determines if the tool shows as installed:

```bash
# Good: Fast, silent, returns 0 or 1
SCRIPT_CHECK_COMMAND="command -v go >/dev/null 2>&1"
SCRIPT_CHECK_COMMAND="[ -f /usr/local/bin/mytool ]"

# Check install location OR PATH (works before PATH refresh)
SCRIPT_CHECK_COMMAND="[ -f /usr/local/go/bin/go ] || command -v go >/dev/null 2>&1"
```

---

## Step 3: Add Installation Logic

Define what packages to install:

```bash
# System packages (apt-get)
PACKAGES_SYSTEM=("curl" "git")

# Node packages (npm)
PACKAGES_NODE=("typescript" "ts-node")

# Python packages (pip)
PACKAGES_PYTHON=("requests" "pandas")

# VS Code extensions
EXTENSIONS=("ms-python.python" "ms-toolsai.jupyter")
```

For custom installation logic, add it in the main section after sourcing the libraries.

---

## Step 4: Test It

```bash
# Show help
.devcontainer/additions/install-mytool.sh --help

# Install
.devcontainer/additions/install-mytool.sh

# Verify it appears in menu
dev-setup
# Navigate to your category

# Uninstall
.devcontainer/additions/install-mytool.sh --uninstall
```

---

## Step 5: Regenerate Documentation

After adding or modifying scripts, update the tools documentation:

```bash
.devcontainer/manage/generate-manual.sh
```

This updates `docs/tools.md` so users can see the new tool.

---

## Script Discovery

Scripts are automatically discovered by `dev-setup` based on:
- Filename pattern: `install-*.sh`
- Presence of `SCRIPT_ID` metadata

No registration needed - just create the file with correct metadata.

---

## Templates

Available templates in `.devcontainer/additions/addition-templates/`:

| Template | Purpose |
|----------|---------|
| `_template-install-script.sh` | Install tools/languages |
| `_template-config-script.sh` | Configuration scripts |
| `_template-service-script.sh` | Background services |
| `_template-cmd-script.sh` | Utility commands |

---

## Testing Tips

- Test install and uninstall
- Test with `--help` flag
- Verify check command works (shows ✅ in menu after install)
- Run `shellcheck` on your script
- Test in fresh container (rebuild)

---

## More Information

- [architecture.md](architecture.md) - Full system architecture
- [categories.md](categories.md) - Category definitions
- Template READMEs in `.devcontainer/additions/addition-templates/`
