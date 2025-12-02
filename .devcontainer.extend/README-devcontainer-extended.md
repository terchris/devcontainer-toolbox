# Devcontainer Extensions

This directory contains **project-specific** customizations and configurations that extend the base devcontainer setup. These files are **committed to git** and shared with your team, allowing each project to define its own set of tools and services.

## Directory Purpose

`.devcontainer.extend/` serves as the **customization layer** where you specify:
- Which development tools to auto-install on container creation
- Which services to auto-start when the container starts
- Project-specific setup scripts and configurations

## Architecture Overview

The devcontainer setup uses a **two-layer architecture**:

**1. Framework Layer (`.devcontainer/manage/postCreateCommand.sh`)**
- Main orchestration script called by `devcontainer.json`
- Handles standard setup: PATH, configurations, tool installation, service startup
- Framework-level code - should not be modified by developers
- Calls project-installs.sh after completing standard setup

**2. Project Layer (`.devcontainer.extend/project-installs.sh`)**
- Empty template by default
- Developers add project-specific customizations here
- Runs AFTER all standard tools and services are set up
- Use for: npm/pip packages, database setup, API generation, custom config

**Execution Flow:**
```
devcontainer.json
    ↓
.devcontainer/manage/postCreateCommand.sh (framework orchestration)
    ↓
    ├─ Setup PATH
    ├─ Restore configurations
    ├─ Install enabled tools (from enabled-tools.conf)
    ├─ Configure supervisor (from enabled-services.conf)
    └─ Call .devcontainer.extend/project-installs.sh (your customizations)
```

## Key Files

### `project-installs.sh`

**Project-specific custom installation script** that runs after all standard tools are installed.

**Location:** `.devcontainer.extend/project-installs.sh`

**Purpose:**
- Add project-specific dependencies not covered by standard tools
- Run database setup scripts
- Generate API clients
- Configure project-specific settings

**Example Usage:**
```bash
#!/bin/bash
set -e

printf "🔧 Running custom project-specific installations...\r\n"

# Install project dependencies
cd /workspace
npm install

# Setup database
bash /workspace/scripts/db-setup.sh

# Install specific Python packages
pip install pandas numpy matplotlib

printf "✅ Custom project installations complete\r\n"
```

**When to Use:**
- Installing project-specific npm/pip/cargo packages
- Running database migrations or setup
- Generating code from schemas
- Any custom setup not covered by enabled-tools.conf

**When NOT to Use:**
- Installing standard development tools → Use `enabled-tools.conf` instead
- Starting background services → Use `enabled-services.conf` instead

---

### `enabled-tools.conf`

Controls which development tools are **automatically installed** when the devcontainer is created or rebuilt.

**Format:** One SCRIPT_ID per line (matches the `SCRIPT_ID` metadata in install scripts)

```bash
# Example enabled-tools.conf
dev-ai-claudecode      # AI coding assistant (Claude Code)
dev-python             # Python development environment
tool-kubernetes        # kubectl, k9s, helm
srv-nginx              # Nginx reverse proxy
```

**Available Tool Categories:**
- `dev-*` - Development tools and language environments
  - `dev-python`, `dev-typescript`, `dev-golang`, `dev-java`, `dev-csharp`, `dev-rust`, `dev-php-laravel`, `dev-powershell`
  - `dev-ai-claudecode` - Claude Code AI assistant
- `tool-*` - CLI tools and utilities
  - `tool-azure` - Azure CLI and tools
  - `tool-kubernetes` - kubectl, k9s, helm
  - `tool-dataanalytics` - Jupyter, pandas, data science tools
  - `tool-iac` - Ansible, configuration management
- `srv-*` - Infrastructure services
  - `srv-nginx` - Nginx reverse proxy
  - `srv-otel` - OpenTelemetry collector

**How It Works:**
1. During container creation, `project-installs.sh` reads this file
2. Discovers available tools from `.devcontainer/additions/install-*.sh` scripts
3. For each enabled SCRIPT_ID, runs the corresponding install script
4. Skips tools already installed (using `CHECK_INSTALLED_COMMAND`)

**Management:**
```bash
# Manually edit the file
nano .devcontainer.extend/enabled-tools.conf

# Or use symbolic links (if provided)
# Tools auto-enable themselves when first installed successfully
```

**Auto-Enable Behavior:**
When you manually run an install script:
```bash
bash .devcontainer/additions/install-dev-python.sh
```
The script automatically adds `dev-python` to `enabled-tools.conf`, ensuring it's installed on future container rebuilds.

**Auto-Disable on Uninstall:**
```bash
bash .devcontainer/additions/install-dev-python.sh --uninstall
```
Automatically removes `dev-python` from `enabled-tools.conf`.

---

### `enabled-services.conf`

Controls which services are **automatically started** when the container starts (managed by supervisord).

**Format:** One SCRIPT_ID per line (matches the `SCRIPT_ID` metadata in service scripts)

```bash
# Example enabled-services.conf
service-nginx          # Nginx reverse proxy (for LiteLLM, OTLP routing)
service-otel           # OpenTelemetry monitoring stack
```

**Available Services:**
- `service-nginx` - Nginx reverse proxy
  - Routes Claude Code → LiteLLM (localhost:8080)
  - Routes OTLP → Kubernetes backend (localhost:8081)
  - Managed by: `service-nginx.sh`
- `service-otel` - OpenTelemetry monitoring
  - Lifecycle collector (devcontainer events)
  - Metrics collector (CPU, memory, disk, network)
  - Script exporter (container-specific metrics)
  - Managed by: `service-otel-monitoring.sh`

**How It Works:**
1. During container startup, `config-supervisor.sh` reads this file
2. Discovers services from `.devcontainer/additions/service-*.sh` scripts
3. Generates supervisord configs in `/etc/supervisor/conf.d/`
4. Supervisord starts enabled services automatically

**Management:**
```bash
# Using dev-services CLI
dev-services status              # Show running services
dev-services start               # Start all enabled services
dev-services stop                # Stop all services
dev-services restart             # Restart all services

# Or manage directly
bash /workspace/.devcontainer/additions/service-nginx.sh --start
bash /workspace/.devcontainer/additions/service-nginx.sh --stop
bash /workspace/.devcontainer/additions/service-nginx.sh --status
bash /workspace/.devcontainer/additions/service-nginx.sh --logs
```

**Auto-Enable Behavior:**
When a service starts successfully:
```bash
bash /workspace/.devcontainer/additions/service-nginx.sh --start
```
The service automatically adds `service-nginx` to `enabled-services.conf` and regenerates supervisord configuration.

**Auto-Disable on Stop:**
```bash
bash /workspace/.devcontainer/additions/service-nginx.sh --stop
```
Automatically removes `service-nginx` from `enabled-services.conf` and updates supervisord.

---


---

## SCRIPT_ID System

Every install script and service script defines a **SCRIPT_ID** metadata field that serves as its unique identifier.

### Format Rules

**SCRIPT_ID format:** `[category-]descriptive-name`
- Only lowercase letters (a-z), numbers (0-9), and dashes (-)
- Must start with a letter
- No consecutive dashes
- Max length: 50 characters

**Examples:**
```bash
# Install script metadata (.devcontainer/additions/install-dev-python.sh)
SCRIPT_ID="dev-python"
SCRIPT_NAME="Python Development Tools"
SCRIPT_DESCRIPTION="Installs Python, pip, and development tools"

# Service script metadata (.devcontainer/additions/service-nginx.sh)
SCRIPT_ID="service-nginx"
SERVICE_SCRIPT_NAME="Nginx Reverse Proxy"
SERVICE_SCRIPT_DESCRIPTION="Nginx reverse proxy for LiteLLM with Host header injection"
```

### Why SCRIPT_ID?

**Before (problematic):**
- Converted display names: "Data & Analytics Tools" → "data-&-analytics-tools" ❌
- Special characters broke matching: "C# Development Tools" → "c#-development-tools" ❌
- Fragile and unpredictable

**After (explicit):**
- Defined explicitly: `SCRIPT_ID="tool-dataanalytics"` ✓
- Only safe characters: `tool-dataanalytics` ✓
- Predictable and maintainable ✓

---

## How to Add a New Tool

1. **Create install script** in `.devcontainer/additions/`:
   ```bash
   cp .devcontainer/additions/addition-templates/_template-install-script.sh \
      .devcontainer/additions/install-dev-mynewlang.sh
   ```

2. **Define metadata** at the top:
   ```bash
   SCRIPT_ID="dev-mynewlang"              # Unique identifier
   SCRIPT_NAME="My New Language"          # Display name
   SCRIPT_DESCRIPTION="Installs my new programming language"
   SCRIPT_CATEGORY="DEV_TOOLS"
   CHECK_INSTALLED_COMMAND="command -v mynewlang >/dev/null 2>&1"
   ```

3. **Implement installation logic**:
   - Define `PACKAGES_SYSTEM`, `PACKAGES_NODE`, `PACKAGES_PYTHON` arrays
   - Or implement custom `process_installations()` function
   - Library handles standard packages automatically

4. **Enable for your project**:
   ```bash
   echo "dev-mynewlang" >> .devcontainer.extend/enabled-tools.conf
   ```

5. **Rebuild container** or run manually:
   ```bash
   bash .devcontainer/additions/install-dev-mynewlang.sh
   ```

---

## How to Add a New Service

1. **Create service script** in `.devcontainer/additions/`:
   ```bash
   cp .devcontainer/additions/addition-templates/_template-service-script.sh \
      .devcontainer/additions/service-myapp.sh
   ```

2. **Define metadata**:
   ```bash
   SCRIPT_ID="service-myapp"                    # Unique identifier
   SERVICE_SCRIPT_NAME="My Application"         # Display name
   SERVICE_SCRIPT_DESCRIPTION="My custom service"
   SERVICE_PRIORITY="40"                        # Start order (lower = earlier)
   SERVICE_DEPENDS=""                           # Dependencies (e.g., "nginx")
   SERVICE_AUTO_RESTART="true"                  # Auto-restart on crash
   ```

3. **Implement service functions**:
   - `service_start()` - Start logic (must use `exec` for supervisord)
   - `service_stop()` - Stop logic
   - `service_status()` - Status check
   - Call `auto_enable_service` before `exec` in start function
   - Call `auto_disable_service` in stop function

4. **Enable for your project**:
   ```bash
   echo "service-myapp" >> .devcontainer.extend/enabled-services.conf
   ```

5. **Regenerate supervisord config**:
   ```bash
   bash .devcontainer/additions/config-supervisor.sh
   sudo supervisorctl reread
   sudo supervisorctl update
   ```

---

## File Ownership

**Committed to Git (.devcontainer.extend/):**
- `enabled-tools.conf` - Tool installation preferences (shared with team)
- `enabled-services.conf` - Service startup preferences (shared with team)
- `project-installs.sh` - Project-specific custom installations (empty template by default)
- `README-devcontainer-extended.md` - This documentation

**Committed to Git (.devcontainer/manage/):**
- `postCreateCommand.sh` - Main orchestration script (framework, don't modify)

**NOT in Git:**
- `.devcontainer.secrets/` - Credentials, API keys, environment variables
- Personal configurations and sensitive data

---

## Troubleshooting

### Tool not installing
```bash
# Check if enabled
cat .devcontainer.extend/enabled-tools.conf | grep "dev-python"

# Check available tools
bash .devcontainer.extend/project-installs.sh
# Look for "⏸️ disabled" vs "✅ ENABLED"

# Run manually with debug
bash .devcontainer/additions/install-dev-python.sh --debug
```

### Service not starting
```bash
# Check if enabled
cat .devcontainer.extend/enabled-services.conf | grep "service-nginx"

# Check supervisord status
sudo supervisorctl status

# Regenerate supervisord config
bash .devcontainer/additions/config-supervisor.sh
sudo supervisorctl reread
sudo supervisorctl update

# Check service logs
bash /workspace/.devcontainer/additions/service-nginx.sh --logs
```

### SCRIPT_ID mismatch
```bash
# Verify SCRIPT_ID in script
grep "^SCRIPT_ID=" .devcontainer/additions/install-dev-python.sh
# Should output: SCRIPT_ID="dev-python"

# Verify enabled-tools.conf uses same ID
cat .devcontainer.extend/enabled-tools.conf
# Should contain line: dev-python
```

---

## Best Practices

1. **Keep it minimal** - Only enable tools/services your project actually needs
2. **Document choices** - Add comments in enabled-*.conf explaining why each tool is needed
3. **Test before committing** - Rebuild container to ensure changes work
4. **Use SCRIPT_ID consistently** - Never manually convert names, always use the defined SCRIPT_ID
5. **Leverage auto-enable** - Let scripts manage enabled-*.conf automatically when possible

---

## Detailed Architecture Diagram

```
Container Creation
       ↓
.devcontainer/devcontainer.json
       ↓
postCreateCommand → .devcontainer/manage/postCreateCommand.sh
       ↓
├─ Setup PATH
│  └─ Add /workspace/.devcontainer to PATH
│
├─ Mark Git folder as safe
│  └─ Configure git for mounted volumes
│
├─ Restore configurations
│  └─ Load from .devcontainer.secrets/ (if exists)
│
├─ Load enabled-tools.conf
│  └─ Install: dev-python, dev-ai-claudecode, tool-kubernetes, etc.
│     └─ Each tool auto-adds itself to enabled-tools.conf
│
├─ Load enabled-services.conf
│  └─ Generate supervisord configs
│     └─ config-supervisor.sh → /etc/supervisor/conf.d/
│
├─ Supervisord Auto-Start
│  └─ service-nginx, service-otel (based on enabled-services.conf)
│     └─ Each service auto-adds itself on start
│     └─ Each service auto-removes itself on stop
│
└─ Call .devcontainer.extend/project-installs.sh
   └─ Your custom project-specific installations
      └─ npm install, database setup, API generation, etc.
```

---

## See Also

- **Tool Scripts:** `.devcontainer/additions/install-*.sh`
- **Service Scripts:** `.devcontainer/additions/service-*.sh`
- **Configuration Scripts:** `.devcontainer/additions/config-*.sh`
- **Template Scripts:** `.devcontainer/additions/addition-templates/`
- **Main Documentation:** `.devcontainer/additions/README-additions.md`
