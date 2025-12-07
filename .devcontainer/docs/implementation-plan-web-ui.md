# Implementation Plan: Web-Based UI for DevContainer Additions System

## Overview

This plan outlines the steps to implement a browser-based management interface that mirrors the terminal `dev-setup` menu, reusing the existing scripts and metadata system.

### Design Principles

- **Zero dependencies** - Use only Node.js built-in modules (no npm install)
- **Minimal footprint** - Target ~100 lines for server, single HTML file for UI
- **Full compatibility** - Call existing scripts without modification
- **Real-time feedback** - Stream script output via Server-Sent Events (SSE)
- **Consistent UX** - Mirror the terminal menu structure and status indicators
- **Service pattern** - Follow `service-*.sh` pattern, managed by supervisord
- **Localhost only** - Bound to 127.0.0.1, accessible only to devcontainer user

### Decisions Made

| Decision | Resolution |
|----------|------------|
| **Port** | 8888 (default, configurable via config-web-ui.sh) |
| **Service management** | Use `install-srv-web-ui.sh` + `service-web-ui.sh` pattern with supervisord |
| **Security** | Localhost only - user's own devcontainer, no auth needed |
| **Interactive prompts** | Skip in web UI - show "Use terminal" message with command to run |
| **Port config passing** | Service script passes port as environment variable to Node.js |

---

## Phase 1: Enhance Component Scanner

**Goal:** Add JSON output capability to `component-scanner.sh`

### 1.1 Add `--json` Flag Support

**File:** `.devcontainer/additions/lib/component-scanner.sh`

**Changes:**
- Add new function `output_json_install_scripts()`
- Add new function `output_json_config_scripts()`
- Add new function `output_json_service_scripts()`
- Add new function `output_json_cmd_scripts()`
- Add argument parsing for `--json` flag

### 1.2 JSON Schema for Install Scripts

```json
{
  "type": "install",
  "scripts": [
    {
      "id": "dev-golang",
      "name": "Go Runtime & Development Tools",
      "description": "Installs Go runtime, common tools, and VS Code extensions",
      "category": "LANGUAGE_DEV",
      "filename": "install-dev-golang.sh",
      "path": "/workspace/.devcontainer/additions/install-dev-golang.sh",
      "installed": true,
      "commands": [
        {"flag": "", "description": "Install with default version", "requiresArg": false},
        {"flag": "--version", "description": "Install specific version", "requiresArg": true, "prompt": "Enter Go version"},
        {"flag": "--uninstall", "description": "Uninstall this tool", "requiresArg": false},
        {"flag": "--help", "description": "Show help information", "requiresArg": false}
      ]
    }
  ]
}
```

### 1.3 JSON Schema for Config Scripts

```json
{
  "type": "config",
  "scripts": [
    {
      "id": "config-web-ui",
      "name": "Web UI Configuration",
      "description": "Configure web UI port",
      "category": "BACKGROUND_SERVICES",
      "filename": "config-web-ui.sh",
      "path": "/workspace/.devcontainer/additions/config-web-ui.sh",
      "configured": true,
      "interactive": true,
      "commands": [
        {"flag": "", "description": "Configure interactively", "requiresArg": false, "interactive": true},
        {"flag": "--show", "description": "Display current config", "requiresArg": false, "interactive": false},
        {"flag": "--verify", "description": "Restore from secrets", "requiresArg": false, "interactive": false}
      ]
    }
  ]
}
```

**Note:** The `interactive` field on commands tells the UI which actions can run in the browser vs require terminal.

### 1.4 JSON Schema for Service Scripts

```json
{
  "type": "service",
  "scripts": [
    {
      "id": "service-nginx",
      "name": "Nginx Reverse Proxy",
      "description": "Nginx reverse proxy for LiteLLM",
      "category": "INFRA_CONFIG",
      "filename": "service-nginx.sh",
      "path": "/workspace/.devcontainer/additions/service-nginx.sh",
      "running": true,
      "priority": 20,
      "commands": [
        {"flag": "--start", "description": "Start nginx", "category": "Control"},
        {"flag": "--stop", "description": "Stop nginx", "category": "Control"},
        {"flag": "--status", "description": "Show status", "category": "Status"},
        {"flag": "--logs", "description": "Show logs", "category": "Status"}
      ]
    }
  ]
}
```

### 1.5 Combined JSON Output

**New Function:** `scan_all_json()`

Outputs all script types in a single JSON response:
```json
{
  "version": "1.0.0",
  "generated": "2024-12-07T10:30:00Z",
  "categories": [
    {"id": "LANGUAGE_DEV", "name": "Development Tools", "order": 1},
    {"id": "AI_TOOLS", "name": "AI & Machine Learning Tools", "order": 2}
  ],
  "install": [...],
  "config": [...],
  "service": [...],
  "cmd": [...]
}
```

### 1.6 Error Handling

The scanner should return valid JSON even on errors:
```json
{
  "version": "1.0.0",
  "error": "Failed to scan install scripts: permission denied",
  "install": [],
  "config": [],
  "service": [],
  "cmd": []
}
```

### 1.7 Testing

- [ ] Test `component-scanner.sh --json install` output
- [ ] Test `component-scanner.sh --json config` output
- [ ] Test `component-scanner.sh --json service` output
- [ ] Test `component-scanner.sh --json all` output
- [ ] Validate JSON with `jq`
- [ ] Verify status checks are accurate
- [ ] Test error case (missing permissions, bad script)

**Estimated effort:** 2-3 hours

---

## Phase 2: Create Web Server Service

**Goal:** Minimal Node.js server following the service-*.sh pattern for supervisord management

### 2.1 File Structure

Following the existing service pattern (like nginx), we create:

```
.devcontainer/additions/
├── config-web-ui.sh           # Port configuration (optional)
├── install-srv-web-ui.sh      # Installation script (validates prerequisites)
├── service-web-ui.sh          # Service management (start/stop/status/etc.)
└── web-ui/                    # Web UI files (source)
    ├── server.js              # Node.js server (~100 lines)
    └── index.html             # Self-contained UI
```

### 2.2 Config Script

**File:** `.devcontainer/additions/config-web-ui.sh`

```bash
SCRIPT_ID="config-web-ui"
SCRIPT_NAME="Web UI Configuration"
SCRIPT_DESCRIPTION="Configure web UI port (default: 8888)"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"
SCRIPT_CHECK_COMMAND="[ -f ~/.web-ui-config ]"

SCRIPT_COMMANDS=(
    "Action||Configure web UI port interactively||false|"
    "Action|--show|Display current configuration||false|"
    "Action|--verify|Restore from .devcontainer.secrets||false|"
    "Info|--help|Show help information||false|"
)
```

**Config file location:** `/workspace/.devcontainer.secrets/web-ui-config`
**Symlink:** `~/.web-ui-config`

**Config file format:**
```bash
# Web UI Configuration
WEB_UI_PORT=8888
```

The config script:
- Prompts for port number (default: 8888)
- Validates port is numeric and in valid range (1024-65535)
- Saves to `.devcontainer.secrets/web-ui-config` for persistence
- Creates symlink at `~/.web-ui-config`
- Supports `--verify` for automatic restoration on rebuild

### 2.3 Install Script

**File:** `.devcontainer/additions/install-srv-web-ui.sh`

```bash
SCRIPT_ID="srv-web-ui"
SCRIPT_NAME="Web UI Service"
SCRIPT_DESCRIPTION="Browser-based management interface for DevContainer Setup"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"
SCRIPT_CHECK_COMMAND="[ -f /workspace/.devcontainer/additions/web-ui/server.js ] && command -v node >/dev/null 2>&1"

# No system packages needed - uses Node.js built-in modules
PACKAGES_SYSTEM=()
```

The install script:
- Verifies Node.js is available (pre-installed in base image)
- Verifies server.js and index.html exist in web-ui/ folder
- Sets correct permissions (chmod +x on server.js)
- Creates log directory if needed

**Note:** Files remain in `web-ui/` folder (no copying needed). The install script validates prerequisites.

### 2.4 Service Script

**File:** `.devcontainer/additions/service-web-ui.sh`

```bash
SCRIPT_ID="service-web-ui"
SCRIPT_NAME="Web UI Service"
SCRIPT_DESCRIPTION="Browser-based DevContainer Setup interface"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"
SCRIPT_CHECK_COMMAND="pgrep -f 'node.*web-ui/server.js' >/dev/null 2>&1"
SCRIPT_PREREQUISITE_TOOLS="install-srv-web-ui.sh"

SERVICE_PRIORITY="90"  # Start late, after other services
SERVICE_DEPENDS=""
SERVICE_AUTO_RESTART="true"

SCRIPT_COMMANDS=(
    "Control|--start|Start web UI server (foreground for supervisord)|service_start|false|"
    "Control|--stop|Stop web UI server|service_stop|false|"
    "Control|--restart|Restart web UI server|service_restart|false|"
    "Status|--status|Check if web UI is running|service_status|false|"
    "Status|--is-running|Silent running check|service_is_running|false|"
    "Status|--url|Show web UI URL|service_url|false|"
    "Debug|--logs|Show server logs|service_logs|false|"
    "Debug|--health|Check server health|service_health|false|"
)
```

**Loading and passing config:**
```bash
# Load port configuration
WEB_UI_PORT=8888  # Default
if [ -f "$HOME/.web-ui-config" ]; then
    source "$HOME/.web-ui-config"
fi

service_start() {
    # ... setup ...

    # Pass port as environment variable to Node.js
    export WEB_UI_PORT

    # Start in foreground for supervisord
    exec node /workspace/.devcontainer/additions/web-ui/server.js
}

service_url() {
    echo "Web UI URL: http://localhost:${WEB_UI_PORT}"
}
```

Key implementation:
- Loads port from `~/.web-ui-config` (default: 8888)
- Passes port to Node.js via `WEB_UI_PORT` environment variable
- `service_start()` uses `exec node server.js` for supervisord foreground mode
- Binds to `127.0.0.1:$WEB_UI_PORT` only (localhost)
- Auto-enables for container restart

### 2.5 Server Implementation

**File:** `.devcontainer/additions/web-ui/server.js`

**Dependencies:** Node.js built-in modules only
- `http` - HTTP server
- `fs` - File system (read HTML)
- `path` - Path utilities
- `child_process` - Execute scripts (spawn)
- `url` - Parse URLs

### 2.6 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Serve the HTML UI |
| `GET` | `/api/scripts` | Get all scripts as JSON |
| `GET` | `/api/scripts/:type` | Get scripts by type (install/config/service/cmd) |
| `GET` | `/api/status/:id` | Check status of specific script |
| `POST` | `/api/execute` | Execute script with streaming output |
| `GET` | `/api/categories` | Get category definitions |
| `GET` | `/api/health` | Health check endpoint |

### 2.7 Script Execution with SSE

**Request:**
```json
POST /api/execute
{
  "script": "install-dev-golang.sh",
  "args": ["--version", "1.21.0"]
}
```

**Response:** Server-Sent Events stream
```
event: start
data: {"script": "install-dev-golang.sh", "pid": 12345}

event: stdout
data: {"line": "Installing Go 1.21.0..."}

event: stderr
data: {"line": "Warning: existing installation found"}

event: exit
data: {"code": 0, "duration": 45.2}
```

**Note:** Separate `stdout` and `stderr` events allow UI to style them differently.

### 2.8 Server Code Outline

```javascript
#!/usr/bin/env node
// File: .devcontainer/additions/web-ui/server.js
// Web UI server for DevContainer Additions System

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const url = require('url');

const PORT = parseInt(process.env.WEB_UI_PORT) || 8888;
const HOST = '127.0.0.1';  // Localhost only for security
const ADDITIONS_DIR = path.join(__dirname, '..');
const SCANNER = path.join(ADDITIONS_DIR, 'lib/component-scanner.sh');
const LOG_FILE = '/tmp/devcontainer-install/web-ui-server.log';  // Managed by cmd-logs.sh

// Simple logging
function log(msg) {
  const timestamp = new Date().toISOString();
  const line = `${timestamp} ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
  console.log(line.trim());
}

// Routes
const routes = {
  'GET /': serveUI,
  'GET /api/scripts': getScripts,
  'GET /api/status': getStatus,
  'GET /api/health': getHealth,
  'POST /api/execute': executeScript,
};

// Health check
function getHealth(req, res) {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'ok', port: PORT, uptime: process.uptime() }));
}

// Bind to localhost only
const server = http.createServer(handleRequest);
server.listen(PORT, HOST, () => {
  log(`Web UI running at http://${HOST}:${PORT}`);
});
```

### 2.9 Security Considerations

**Binding & Access:**
- Bind to `127.0.0.1` only (not `0.0.0.0`)
- No authentication needed - localhost access only

**CSRF Protection:**
- Check `Origin` header on all POST requests
- Reject requests where Origin doesn't match configured port
- This prevents malicious websites from making requests to the API

**Script Execution Safety:**
- Validate script filenames with regex: `^(install|config|service|cmd)-[a-z0-9-]+\.sh$`
- Resolve path and verify it's within `additions/` directory (prevent path traversal)
- Use `spawn()` with array arguments, NOT `exec()` with string (prevent shell injection)
- Validate arguments: alphanumeric, dots, dashes, underscores only

**Implementation example:**
```javascript
// CSRF check - dynamically uses configured port
function checkOrigin(req) {
  const origin = req.headers.origin || req.headers.referer || '';
  const allowed = [
    `http://localhost:${PORT}`,
    `http://127.0.0.1:${PORT}`
  ];
  return allowed.some(a => origin.startsWith(a));
}

// Safe script execution
function validateAndExecute(scriptName, args) {
  // Validate script name
  if (!/^(install|config|service|cmd)-[a-z0-9-]+\.sh$/.test(scriptName)) {
    throw new Error('Invalid script name');
  }

  // Validate args (alphanumeric, dots, dashes, underscores, equals)
  for (const arg of args) {
    if (!/^[a-zA-Z0-9._=-]+$/.test(arg)) {
      throw new Error('Invalid argument: ' + arg);
    }
  }

  // Resolve and verify path
  const scriptPath = path.resolve(ADDITIONS_DIR, scriptName);
  if (!scriptPath.startsWith(path.resolve(ADDITIONS_DIR))) {
    throw new Error('Path traversal detected');
  }

  // Verify file exists
  if (!fs.existsSync(scriptPath)) {
    throw new Error('Script not found: ' + scriptName);
  }

  // Use spawn with array (no shell interpretation)
  return spawn('bash', [scriptPath, ...args], {
    cwd: ADDITIONS_DIR,
    env: { ...process.env, TERM: 'dumb' }
  });
}
```

### 2.10 Logging

The server uses the existing log management system (`cmd-logs.sh`) to prevent log growth.

**Log location:** `/tmp/devcontainer-install/web-ui-server.log`

This location is automatically managed by `cmd-logs.sh`:
- Files in `/tmp/devcontainer-install/` older than 7 days are deleted
- The scheduled cleanup runs every 24 hours

**Add to cmd-logs.sh TRUNCATE_LOGS array:**
```bash
TRUNCATE_LOGS=(
    # ... existing entries ...
    "/tmp/devcontainer-install/web-ui-server.log:5"  # Truncate at 5MB
)
```

**Server logging:**
```javascript
const LOG_FILE = '/tmp/devcontainer-install/web-ui-server.log';

function log(msg) {
  const timestamp = new Date().toISOString();
  const line = `${timestamp} ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
  console.log(line.trim());  // Also output to stdout for supervisord
}
```

Service script `--logs` command uses:
```bash
service_logs() {
    local log_file="/tmp/devcontainer-install/web-ui-server.log"
    if [ -f "$log_file" ]; then
        tail -50 "$log_file"
    else
        echo "No logs found"
    fi
}
```

### 2.11 Testing

**Functional tests:**
- [ ] Server starts without errors
- [ ] `/api/scripts` returns valid JSON
- [ ] `/api/health` returns status
- [ ] `/api/execute` streams output correctly
- [ ] SSE connection stays open during execution
- [ ] Handles script errors gracefully
- [ ] Concurrent executions work

**Security tests:**
- [ ] Rejects requests with wrong Origin header
- [ ] Rejects invalid script names
- [ ] Rejects path traversal attempts (`../`)
- [ ] Rejects shell injection in arguments

**Estimated effort:** 4-5 hours

---

## Phase 3: Create Web UI

**Goal:** Single self-contained HTML file with embedded CSS and JavaScript

### 3.1 UI Structure

**File:** `.devcontainer/additions/web-ui/index.html`

**Layout:**
```
┌─────────────────────────────────────────────────────────────────┐
│  DevContainer Setup                                    [Refresh] │
├─────────────────────────────────────────────────────────────────┤
│  [Install Tools] [Services] [Configuration] [Commands]          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │ ✅ Go Runtime       │  │ ❌ Rust Development │               │
│  │ Development Tools   │  │ Rust toolchain      │               │
│  │ [Install] [Help]    │  │ [Install] [Help]    │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │ ✅ Python Dev       │  │ ✅ TypeScript       │               │
│  │ Python 3.12 + pip   │  │ Node.js + TS        │               │
│  │ [Reinstall] [Help]  │  │ [Reinstall] [Help]  │               │
│  └─────────────────────┘  └─────────────────────┘               │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  Output                                               [Clear]    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ $ install-dev-golang.sh                                   │  │
│  │ Installing Go 1.21.0...                                   │  │
│  │ ⚠ Warning: existing installation found                    │  │
│  │ ✅ Installation complete                                  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 UI Features

| Feature | Description |
|---------|-------------|
| **Tab Navigation** | Switch between Install/Services/Config/Commands |
| **Category Grouping** | Scripts grouped by SCRIPT_CATEGORY |
| **Status Indicators** | Green checkmark / Red X based on status |
| **Action Buttons** | Install, Uninstall, Start, Stop, etc. |
| **Real-time Output** | Streaming terminal-like output panel |
| **Stderr Styling** | Stderr lines shown in yellow/orange |
| **Dark Theme** | Matches VS Code dark theme |
| **Responsive Grid** | Cards adapt to screen width |
| **Auto-refresh** | Refresh status after script execution |
| **Copy Command** | For interactive configs, copy terminal command |

### 3.3 Handling Interactive Config Scripts

Config scripts with `interactive: true` on their default action show a special card:

```
┌─────────────────────────────────────────────────────────────┐
│ ⚙️  Developer Identity                          [configured] │
│ Configure your identity for devcontainer monitoring         │
│                                                             │
│ ⚠️  Interactive configuration required                      │
│                                                             │
│ Run in terminal:                                            │
│ ┌─────────────────────────────────────────────────────────┐│
│ │ bash .devcontainer/additions/config-identity.sh        ││
│ └─────────────────────────────────────────────────────────┘│
│                                    [📋 Copy] [--show]       │
└─────────────────────────────────────────────────────────────┘
```

Non-interactive actions (`--show`, `--verify`) still have buttons.

### 3.4 CSS Styling

```css
/* Dark theme matching VS Code */
:root {
  --bg-primary: #1e1e1e;
  --bg-secondary: #252526;
  --bg-card: #2d2d2d;
  --text-primary: #cccccc;
  --text-secondary: #858585;
  --accent: #0078d4;
  --success: #4ec9b0;
  --error: #f14c4c;
  --warning: #cca700;
  --border: #404040;
}

/* Stderr styling */
.output-stderr {
  color: var(--warning);
}
```

### 3.5 JavaScript Structure

```javascript
// State
let scripts = { install: [], config: [], service: [], cmd: [] };
let activeTab = 'install';
let eventSource = null;
let isExecuting = false;

// API calls
async function fetchScripts() { /* GET /api/scripts */ }
async function executeScript(filename, args) { /* POST /api/execute with SSE */ }
async function refreshStatus(id) { /* GET /api/status/:id */ }
async function checkHealth() { /* GET /api/health */ }

// UI rendering
function renderTabs() { /* Tab buttons */ }
function renderScriptCards() { /* Card grid */ }
function renderOutput(line, type) { /* Append to output, style by type */ }
function renderInteractiveConfig(script) { /* Special card for interactive configs */ }

// Event handlers
function onTabClick(tab) { /* Switch tabs */ }
function onActionClick(script, action) { /* Execute action */ }
function onRefresh() { /* Refresh all statuses */ }
function onCopyCommand(command) { /* Copy to clipboard */ }

// Disable buttons during execution
function setExecuting(state) {
  isExecuting = state;
  document.querySelectorAll('.action-btn').forEach(btn => {
    btn.disabled = state;
  });
}
```

### 3.6 Testing

- [ ] UI loads correctly
- [ ] Tabs switch properly
- [ ] Scripts grouped by category
- [ ] Status indicators update
- [ ] Action buttons trigger execution
- [ ] Buttons disabled during execution
- [ ] Output streams in real-time
- [ ] Stderr shown in different color
- [ ] Interactive config shows terminal command
- [ ] Copy command works
- [ ] Works in Chrome, Firefox, Safari, Edge
- [ ] Responsive on different screen sizes

**Estimated effort:** 4-5 hours

---

## Phase 4: Integration

**Goal:** Integrate web UI service into devcontainer using existing patterns

### 4.1 Supervisord Integration

The service follows the standard supervisord pattern used by other services (nginx, otel).

**Auto-start behavior:**
- When user enables the service, it's added to `enabled-services.conf`
- On container restart, supervisord starts the service automatically
- Service runs in foreground mode via `exec node server.js`

**Manual control:**
```bash
# Start/stop via service script
bash .devcontainer/additions/service-web-ui.sh --start
bash .devcontainer/additions/service-web-ui.sh --stop
bash .devcontainer/additions/service-web-ui.sh --status

# Or via dev-services menu
dev-services
```

### 4.2 Port Forwarding

VS Code automatically detects when a process listens on a port inside the container and forwards it to the host. No `devcontainer.json` changes required.

**How it works:**
1. Web UI server starts, listens on `127.0.0.1:8888` (or configured port)
2. VS Code detects the port and auto-forwards it
3. Developer opens `http://localhost:8888` in their browser on the host

**Note:** VS Code may show a notification offering to open the URL. The `onAutoForward` behavior is controlled by VS Code user settings, not devcontainer.json.

### 4.3 CLI Convenience Command

Add alias in postCreateCommand.sh or user's .bashrc:

```bash
alias dev-web='bash /workspace/.devcontainer/additions/service-web-ui.sh --url'
```

### 4.4 Update Documentation

- [ ] Update `.devcontainer/docs/additions-system-architecture.md`
- [ ] Add web UI section to `.devcontainer/additions/README-additions.md`
- [ ] Create `.devcontainer/docs/web-ui-guide.md`

**Estimated effort:** 1-2 hours

---

## Phase 5: Testing & Polish

### 5.1 End-to-End Testing

| Test Case | Steps | Expected |
|-----------|-------|----------|
| Install tool | Click Install on uninstalled tool | Tool installs, status updates to ✅ |
| Uninstall tool | Click Uninstall on installed tool | Tool uninstalls, status updates to ❌ |
| Start service | Click Start on stopped service | Service starts, status updates |
| Stop service | Click Stop on running service | Service stops, status updates |
| View config | Click --show on config script | Config displayed in output |
| Interactive config | View config card | Shows terminal command with copy button |
| View logs | Click Logs on service | Logs display in output |
| Concurrent ops | Run 2 scripts simultaneously | Both stream correctly |
| Error handling | Run script that fails | Error shown in output, status correct |
| Port change | Configure different port, restart | Server runs on new port |

### 5.2 Browser Testing

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)

### 5.3 Performance Testing

- [ ] Initial load time < 500ms
- [ ] Status refresh < 200ms per script
- [ ] SSE connection stable for long operations
- [ ] Memory usage stable over time

### 5.4 Security Testing

- [ ] CSRF: Verify external site cannot POST to API
- [ ] Path traversal: Verify `../` in script name is rejected
- [ ] Injection: Verify shell metacharacters in args are rejected
- [ ] Origin: Verify wrong Origin header is rejected

**Estimated effort:** 2-3 hours

---

## File Summary

| File | Type | Lines (est.) | Description |
|------|------|--------------|-------------|
| `additions/lib/component-scanner.sh` | Modified | +150 | Add JSON output functions |
| `additions/cmd-logs.sh` | Modified | +1 | Add web-ui log to TRUNCATE_LOGS |
| `additions/config-web-ui.sh` | New | ~120 | Port configuration script |
| `additions/install-srv-web-ui.sh` | New | ~60 | Install script (validates prereqs) |
| `additions/service-web-ui.sh` | New | ~250 | Service management script |
| `additions/web-ui/server.js` | New | ~150 | Node.js API server |
| `additions/web-ui/index.html` | New | ~350 | Self-contained HTML/CSS/JS |
| `docs/web-ui-guide.md` | New | ~100 | User documentation |
| `tests/static/test-web-ui-scripts.sh` | New | ~60 | Static metadata tests |
| `tests/unit/test-scanner-json.sh` | New | ~80 | JSON output tests |
| `tests/unit/test-web-ui-service.sh` | New | ~50 | Service script tests |
| `tests/integration/test-web-ui-api.sh` | New | ~180 | API & security tests |

**Total new code:** ~1550 lines
**Total effort:** 16-21 hours

---

## Implementation Order

```
Week 1:
├── Phase 1: Enhance Component Scanner (2-3h)
│   ├── Add JSON output functions
│   ├── Add interactive flag for config commands
│   ├── Parse SCRIPT_COMMANDS for commands
│   └── Test with jq
│
├── Phase 2: Create Web Server (4-5h)
│   ├── Config script
│   ├── Install script
│   ├── Service script
│   ├── Basic HTTP server with logging
│   ├── API endpoints
│   ├── Security (CSRF, validation)
│   └── SSE streaming (stdout/stderr)
│
└── Phase 3: Create Web UI (4-5h)
    ├── HTML structure
    ├── CSS dark theme
    ├── JavaScript logic
    └── Interactive config handling

Week 2:
├── Phase 4: Integration (1-2h)
│   ├── Supervisord setup
│   ├── CLI command
│   └── Documentation
│
├── Phase 5: Testing & Polish (2-3h)
│   ├── End-to-end tests
│   ├── Security tests
│   ├── Browser testing
│   └── Bug fixes
│
└── Phase 6: Automated Tests (2-3h)
    ├── Static tests for web UI scripts
    ├── Unit tests for scanner JSON output
    ├── Unit tests for service-web-ui.sh
    └── Integration tests for API endpoints
```

---

## Phase 6: Automated Tests

**Goal:** Add automated tests following the existing test framework in `additions/tests/`

### 6.1 Test Structure

New test files to create:

```
tests/
├── static/
│   └── test-web-ui-scripts.sh      # Validate web UI script metadata
├── unit/
│   ├── test-scanner-json.sh        # Test component-scanner.sh --json
│   └── test-web-ui-service.sh      # Test service-web-ui.sh commands
└── integration/
    └── test-web-ui-api.sh          # Test API endpoints (requires running server)
```

### 6.2 Static Tests: test-web-ui-scripts.sh

**File:** `.devcontainer/additions/tests/static/test-web-ui-scripts.sh`

Tests for the new scripts (config-web-ui.sh, install-srv-web-ui.sh, service-web-ui.sh):

```bash
#!/bin/bash
# Test web UI scripts have correct metadata

source "$SCRIPT_DIR/../lib/test-framework.sh"

test_web_ui_scripts_have_metadata() {
    local scripts=(
        "config-web-ui.sh"
        "install-srv-web-ui.sh"
        "service-web-ui.sh"
    )
    local required_fields=(
        "SCRIPT_ID"
        "SCRIPT_NAME"
        "SCRIPT_DESCRIPTION"
        "SCRIPT_CATEGORY"
        "SCRIPT_CHECK_COMMAND"
    )

    local has_issues=0
    for script in "${scripts[@]}"; do
        local script_path="$ADDITIONS_DIR/$script"
        [[ ! -f "$script_path" ]] && continue

        for field in "${required_fields[@]}"; do
            if ! grep -q "^${field}=" "$script_path"; then
                echo "  ✗ $script: missing $field"
                has_issues=1
            fi
        done
    done

    return $has_issues
}

test_service_script_has_commands() {
    local script="$ADDITIONS_DIR/service-web-ui.sh"
    [[ ! -f "$script" ]] && skip_test "service-web-ui.sh not found"

    local required_commands=(
        "--start"
        "--stop"
        "--status"
        "--is-running"
    )

    local has_issues=0
    for cmd in "${required_commands[@]}"; do
        if ! grep -q "$cmd" "$script"; then
            echo "  ✗ Missing command: $cmd"
            has_issues=1
        fi
    done

    return $has_issues
}

run_test "Web UI scripts have required metadata" test_web_ui_scripts_have_metadata
run_test "Service script has required commands" test_service_script_has_commands
```

### 6.3 Unit Tests: test-scanner-json.sh

**File:** `.devcontainer/additions/tests/unit/test-scanner-json.sh`

Tests for `component-scanner.sh --json` output:

```bash
#!/bin/bash
# Test component-scanner.sh JSON output

source "$SCRIPT_DIR/../lib/test-framework.sh"
source_libs "component-scanner.sh"

test_json_output_is_valid() {
    local output
    output=$("$ADDITIONS_DIR/lib/component-scanner.sh" --json all 2>/dev/null)

    if ! echo "$output" | jq . >/dev/null 2>&1; then
        echo "  ✗ Invalid JSON output"
        echo "  Output: ${output:0:200}..."
        return 1
    fi
    return 0
}

test_json_has_required_fields() {
    local output
    output=$("$ADDITIONS_DIR/lib/component-scanner.sh" --json all 2>/dev/null)

    local required=("version" "categories" "install" "config" "service")
    local has_issues=0

    for field in "${required[@]}"; do
        if ! echo "$output" | jq -e ".$field" >/dev/null 2>&1; then
            echo "  ✗ Missing field: $field"
            has_issues=1
        fi
    done

    return $has_issues
}

test_json_install_scripts_have_commands() {
    local output
    output=$("$ADDITIONS_DIR/lib/component-scanner.sh" --json install 2>/dev/null)

    # Check first script has commands array
    local has_commands
    has_commands=$(echo "$output" | jq -e '.scripts[0].commands | length > 0' 2>/dev/null)

    if [[ "$has_commands" != "true" ]]; then
        echo "  ✗ Install scripts missing commands array"
        return 1
    fi
    return 0
}

test_json_config_scripts_have_interactive_flag() {
    local output
    output=$("$ADDITIONS_DIR/lib/component-scanner.sh" --json config 2>/dev/null)

    # Check config scripts have interactive flag on commands
    local has_interactive
    has_interactive=$(echo "$output" | jq -e '.scripts[0].commands[0] | has("interactive")' 2>/dev/null)

    if [[ "$has_interactive" != "true" ]]; then
        echo "  ✗ Config scripts missing interactive flag on commands"
        return 1
    fi
    return 0
}

run_test "JSON output is valid" test_json_output_is_valid
run_test "JSON has required fields" test_json_has_required_fields
run_test "Install scripts have commands array" test_json_install_scripts_have_commands
run_test "Config scripts have interactive flag" test_json_config_scripts_have_interactive_flag
```

### 6.4 Unit Tests: test-web-ui-service.sh

**File:** `.devcontainer/additions/tests/unit/test-web-ui-service.sh`

Tests for `service-web-ui.sh`:

```bash
#!/bin/bash
# Test service-web-ui.sh commands

source "$SCRIPT_DIR/../lib/test-framework.sh"

SERVICE_SCRIPT="$ADDITIONS_DIR/service-web-ui.sh"

test_service_help_works() {
    [[ ! -f "$SERVICE_SCRIPT" ]] && skip_test "service-web-ui.sh not found"

    local output
    output=$(bash "$SERVICE_SCRIPT" --help 2>&1)

    if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
        echo "  ✗ --help failed or empty"
        return 1
    fi

    # Check output contains expected sections
    if ! echo "$output" | grep -q "start"; then
        echo "  ✗ --help missing start command"
        return 1
    fi

    return 0
}

test_service_status_works() {
    [[ ! -f "$SERVICE_SCRIPT" ]] && skip_test "service-web-ui.sh not found"

    # --status should work even if service not running
    bash "$SERVICE_SCRIPT" --status >/dev/null 2>&1
    # Exit codes: 0 = running, 1 = stopped, both are valid
    return 0
}

test_service_is_running_returns_code() {
    [[ ! -f "$SERVICE_SCRIPT" ]] && skip_test "service-web-ui.sh not found"

    # --is-running should return exit code only (silent)
    local output
    output=$(bash "$SERVICE_SCRIPT" --is-running 2>&1)

    # Output should be empty or minimal (silent check)
    if [[ ${#output} -gt 50 ]]; then
        echo "  ✗ --is-running should be silent, got: ${output:0:100}"
        return 1
    fi
    return 0
}

run_test "Service --help works" test_service_help_works
run_test "Service --status works" test_service_status_works
run_test "Service --is-running returns exit code" test_service_is_running_returns_code
```

### 6.5 Integration Tests: test-web-ui-api.sh

**File:** `.devcontainer/additions/tests/integration/test-web-ui-api.sh`

Tests for the running web server API:

```bash
#!/bin/bash
# Integration tests for web UI API
# These tests require the web UI server to be running

source "$SCRIPT_DIR/../lib/test-framework.sh"

# Configuration
PORT="${WEB_UI_PORT:-8888}"
BASE_URL="http://127.0.0.1:$PORT"

# Check if server is running before tests
check_server_running() {
    if ! curl -s "$BASE_URL/api/health" >/dev/null 2>&1; then
        echo "Web UI server not running on port $PORT"
        echo "Start it with: bash .devcontainer/additions/service-web-ui.sh --start &"
        exit 77  # Skip all tests
    fi
}

#------------------------------------------------------------------------------
# API Tests
#------------------------------------------------------------------------------

test_health_endpoint() {
    local response
    response=$(curl -s "$BASE_URL/api/health")

    if ! echo "$response" | jq -e '.status == "ok"' >/dev/null 2>&1; then
        echo "  ✗ /api/health should return status: ok"
        echo "  Response: $response"
        return 1
    fi
    return 0
}

test_scripts_endpoint_returns_json() {
    local response
    response=$(curl -s "$BASE_URL/api/scripts")

    if ! echo "$response" | jq . >/dev/null 2>&1; then
        echo "  ✗ /api/scripts should return valid JSON"
        return 1
    fi

    # Check has expected structure
    if ! echo "$response" | jq -e '.install' >/dev/null 2>&1; then
        echo "  ✗ /api/scripts missing install array"
        return 1
    fi

    return 0
}

test_categories_endpoint() {
    local response
    response=$(curl -s "$BASE_URL/api/categories")

    if ! echo "$response" | jq -e '.[0].id' >/dev/null 2>&1; then
        echo "  ✗ /api/categories should return array with id field"
        return 1
    fi
    return 0
}

#------------------------------------------------------------------------------
# Security Tests
#------------------------------------------------------------------------------

test_csrf_blocks_wrong_origin() {
    local response
    local http_code

    # POST with wrong Origin header should be rejected
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$BASE_URL/api/execute" \
        -H "Origin: http://evil.com" \
        -H "Content-Type: application/json" \
        -d '{"script":"install-dev-python.sh","args":["--help"]}')

    if [[ "$http_code" != "403" ]]; then
        echo "  ✗ Wrong Origin should return 403, got: $http_code"
        return 1
    fi
    return 0
}

test_invalid_script_name_rejected() {
    local response
    local http_code

    # Script with path traversal should be rejected
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$BASE_URL/api/execute" \
        -H "Origin: http://127.0.0.1:$PORT" \
        -H "Content-Type: application/json" \
        -d '{"script":"../../../etc/passwd","args":[]}')

    if [[ "$http_code" != "400" ]]; then
        echo "  ✗ Path traversal should return 400, got: $http_code"
        return 1
    fi
    return 0
}

test_shell_injection_in_args_rejected() {
    local response
    local http_code

    # Args with shell metacharacters should be rejected
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$BASE_URL/api/execute" \
        -H "Origin: http://127.0.0.1:$PORT" \
        -H "Content-Type: application/json" \
        -d '{"script":"install-dev-python.sh","args":["--help; rm -rf /"]}')

    if [[ "$http_code" != "400" ]]; then
        echo "  ✗ Shell injection should return 400, got: $http_code"
        return 1
    fi
    return 0
}

#------------------------------------------------------------------------------
# Execution Tests
#------------------------------------------------------------------------------

test_execute_help_returns_sse() {
    local response

    # Execute --help and check SSE format
    response=$(curl -s -N \
        -X POST "$BASE_URL/api/execute" \
        -H "Origin: http://127.0.0.1:$PORT" \
        -H "Content-Type: application/json" \
        -d '{"script":"install-dev-python.sh","args":["--help"]}' \
        --max-time 5 2>/dev/null | head -20)

    # Should have SSE event format
    if ! echo "$response" | grep -q "^event:"; then
        echo "  ✗ Response should be SSE format with 'event:' lines"
        return 1
    fi

    # Should have exit event
    if ! echo "$response" | grep -q "event: exit"; then
        echo "  ✗ Response should include 'event: exit'"
        return 1
    fi

    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

# Check server first
check_server_running

print_header "Web UI API Integration Tests"

run_test "Health endpoint returns ok" test_health_endpoint
run_test "Scripts endpoint returns JSON" test_scripts_endpoint_returns_json
run_test "Categories endpoint works" test_categories_endpoint
run_test "CSRF blocks wrong Origin" test_csrf_blocks_wrong_origin
run_test "Invalid script name rejected" test_invalid_script_name_rejected
run_test "Shell injection in args rejected" test_shell_injection_in_args_rejected
run_test "Execute returns SSE stream" test_execute_help_returns_sse
```

### 6.6 Running the Tests

Add to test orchestrator or run individually:

```bash
# Run static tests for web UI scripts
./run-all-tests.sh static config-web-ui.sh
./run-all-tests.sh static install-srv-web-ui.sh
./run-all-tests.sh static service-web-ui.sh

# Run unit tests for scanner JSON
./run-all-tests.sh unit

# Run integration tests (server must be running)
bash .devcontainer/additions/service-web-ui.sh --start &
sleep 2
bash .devcontainer/additions/tests/integration/test-web-ui-api.sh
bash .devcontainer/additions/service-web-ui.sh --stop
```

### 6.7 Test File Summary

| File | Test Level | Tests | Description |
|------|------------|-------|-------------|
| `static/test-web-ui-scripts.sh` | 1 (static) | 2 | Metadata validation |
| `unit/test-scanner-json.sh` | 2 (unit) | 4 | JSON output validation |
| `unit/test-web-ui-service.sh` | 2 (unit) | 3 | Service script commands |
| `integration/test-web-ui-api.sh` | - | 7 | API endpoints & security |

**Total new tests:** 16 tests
**Estimated effort:** 2-3 hours

---

## Future Enhancements

After initial implementation, consider:

1. **History** - Log of executed scripts with timestamps
2. **Favorites** - Pin frequently used scripts
3. **Search** - Filter scripts by name/description
4. **Mobile** - Touch-friendly interface
5. **Notifications** - Browser notifications on completion
6. **Themes** - Light theme option
7. **Cancel button** - Ability to kill running script
8. **Multi-user lock** - Prevent concurrent modifications

---

## What Works in Web UI

| Script Type | Action | Web UI Support |
|-------------|--------|----------------|
| `config-*.sh` | Default (interactive) | ❌ Show terminal command + copy |
| `config-*.sh` | `--show` | ✅ Display output |
| `config-*.sh` | `--verify` | ✅ Run and show result |
| `install-*.sh` | All actions | ✅ Full support |
| `service-*.sh` | All actions | ✅ Full support |
| `cmd-*.sh` | Non-interactive | ✅ Full support |

---

## Open Items

| Item | Status | Notes |
|------|--------|-------|
| Long operations timeout | Deferred | No timeout for v1, add cancel button later |
| Multiple concurrent executions | Deferred | Allow for v1, add queue/lock later if needed |
| Authentication | Deferred | Not needed for localhost-only access |

---

**Document Version:** 1.4
**Created:** 2024-12-07
**Updated:** 2024-12-07
**Status:** Ready for Implementation
