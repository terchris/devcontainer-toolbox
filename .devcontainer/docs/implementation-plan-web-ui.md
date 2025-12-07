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
| **Port** | 8888 (default, configurable) |
| **Service management** | Use `install-srv-web-ui.sh` + `service-web-ui.sh` pattern with supervisord |
| **Security** | Localhost only - user's own devcontainer, no auth needed |
| **Interactive prompts** | Skip in web UI - show "Use terminal" message with command to run |

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

**JSON Schema for Install Scripts:**
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

**JSON Schema for Service Scripts:**
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

### 1.2 Add Combined JSON Output

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

### 1.3 Testing

- [ ] Test `component-scanner.sh --json install` output
- [ ] Test `component-scanner.sh --json config` output
- [ ] Test `component-scanner.sh --json service` output
- [ ] Test `component-scanner.sh --json all` output
- [ ] Validate JSON with `jq`
- [ ] Verify status checks are accurate

**Estimated effort:** 2-3 hours

---

## Phase 2: Create Web Server Service

**Goal:** Minimal Node.js server following the service-*.sh pattern for supervisord management

### 2.1 File Structure

Following the existing service pattern (like nginx), we create:

```
.devcontainer/additions/
├── install-srv-web-ui.sh      # Installation script
├── service-web-ui.sh          # Service management (start/stop/status/etc.)
└── web-ui/                    # Web UI files
    ├── server.js              # Node.js server (~100 lines)
    └── index.html             # Self-contained UI
```

### 2.2 Install Script

**File:** `.devcontainer/additions/install-srv-web-ui.sh`

```bash
SCRIPT_ID="srv-web-ui"
SCRIPT_NAME="Web UI Service"
SCRIPT_DESCRIPTION="Browser-based management interface for DevContainer Setup"
SCRIPT_CATEGORY="BACKGROUND_SERVICES"
SCRIPT_CHECK_COMMAND="[ -f /workspace/.devcontainer/additions/web-ui/server.js ]"

# No system packages needed - uses Node.js built-in modules
PACKAGES_SYSTEM=()
```

The install script:
- Copies server.js and index.html to correct locations
- Sets correct permissions
- Verifies Node.js is available (pre-installed in base image)

### 2.3 Service Script

**File:** `.devcontainer/additions/service-web-ui.sh`

```bash
SCRIPT_ID="service-web-ui"
SCRIPT_NAME="Web UI Service"
SCRIPT_DESCRIPTION="Browser-based DevContainer Setup interface on port 8888"
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
)
```

Key implementation:
- `service_start()` uses `exec node server.js` for supervisord foreground mode
- Binds to `127.0.0.1:8888` only (localhost)
- Auto-enables for container restart

### 2.4 Server Implementation

**File:** `.devcontainer/additions/web-ui/server.js`

**Dependencies:** Node.js built-in modules only
- `http` - HTTP server
- `fs` - File system (read HTML)
- `path` - Path utilities
- `child_process` - Execute scripts
- `url` - Parse URLs

### 2.5 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Serve the HTML UI |
| `GET` | `/api/scripts` | Get all scripts as JSON |
| `GET` | `/api/scripts/:type` | Get scripts by type (install/config/service/cmd) |
| `GET` | `/api/status/:id` | Check status of specific script |
| `POST` | `/api/execute` | Execute script with streaming output |
| `GET` | `/api/categories` | Get category definitions |

### 2.6 Script Execution with SSE

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

event: stdout
data: {"line": "Downloading from golang.org..."}

event: exit
data: {"code": 0, "duration": 45.2}
```

### 2.7 Server Code Outline

```javascript
#!/usr/bin/env node
// File: .devcontainer/additions/web-ui/server.js
// Web UI server for DevContainer Additions System

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const url = require('url');

const PORT = process.env.WEB_UI_PORT || 8888;
const HOST = '127.0.0.1';  // Localhost only for security
const ADDITIONS_DIR = path.join(__dirname, '..');
const SCANNER = path.join(ADDITIONS_DIR, 'lib/component-scanner.sh');

// Routes
const routes = {
  'GET /': serveUI,
  'GET /api/scripts': getScripts,
  'GET /api/status': getStatus,
  'POST /api/execute': executeScript,
};

// Bind to localhost only
server.listen(PORT, HOST, () => {
  console.log(`Web UI running at http://${HOST}:${PORT}`);
});
```

### 2.8 Security Considerations

- Only allow execution of scripts in `additions/` directory
- Validate script filenames against allowlist
- Sanitize arguments (no shell injection)
- Bind to `127.0.0.1` only (not `0.0.0.0`)
- No authentication needed - localhost access only

### 2.9 Testing

- [ ] Server starts without errors
- [ ] `/api/scripts` returns valid JSON
- [ ] `/api/execute` streams output correctly
- [ ] SSE connection stays open during execution
- [ ] Handles script errors gracefully
- [ ] Concurrent executions work

**Estimated effort:** 3-4 hours

---

## Phase 3: Create Web UI

**Goal:** Single self-contained HTML file with embedded CSS and JavaScript

### 3.1 UI Structure

**File:** `.devcontainer/manage/web-ui.html`

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
│  │ Downloading from golang.org...                            │  │
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
| **Dark Theme** | Matches VS Code dark theme |
| **Responsive Grid** | Cards adapt to screen width |
| **Auto-refresh** | Refresh status after script execution |

### 3.3 CSS Styling

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
```

### 3.4 JavaScript Structure

```javascript
// State
let scripts = { install: [], config: [], service: [], cmd: [] };
let activeTab = 'install';
let eventSource = null;

// API calls
async function fetchScripts() { /* GET /api/scripts */ }
async function executeScript(filename, args) { /* POST /api/execute with SSE */ }
async function refreshStatus(id) { /* GET /api/status/:id */ }

// UI rendering
function renderTabs() { /* Tab buttons */ }
function renderScriptCards() { /* Card grid */ }
function renderOutput(line) { /* Append to output panel */ }

// Event handlers
function onTabClick(tab) { /* Switch tabs */ }
function onActionClick(script, action) { /* Execute action */ }
function onRefresh() { /* Refresh all statuses */ }
```

### 3.5 Testing

- [ ] UI loads correctly
- [ ] Tabs switch properly
- [ ] Scripts grouped by category
- [ ] Status indicators update
- [ ] Action buttons trigger execution
- [ ] Output streams in real-time
- [ ] Works in Chrome, Firefox, Safari
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

**File:** `.devcontainer/devcontainer.json`

```json
{
  "forwardPorts": [8888],
  "portsAttributes": {
    "8888": {
      "label": "DevContainer Setup UI",
      "onAutoForward": "silent"
    }
  }
}
```

### 4.3 CLI Convenience Command

Add alias in postCreateCommand.sh or user's .bashrc:

```bash
alias dev-web='bash /workspace/.devcontainer/additions/service-web-ui.sh --status && echo "Open: http://localhost:8888"'
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
| Run config | Click Configure | Interactive prompts work |
| View logs | Click Logs on service | Logs display in output |
| Concurrent ops | Run 2 scripts simultaneously | Both stream correctly |
| Error handling | Run script that fails | Error shown, status correct |

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

**Estimated effort:** 2-3 hours

---

## File Summary

| File | Type | Lines (est.) | Description |
|------|------|--------------|-------------|
| `additions/lib/component-scanner.sh` | Modified | +100 | Add JSON output functions |
| `additions/install-srv-web-ui.sh` | New | ~80 | Install script for web UI |
| `additions/service-web-ui.sh` | New | ~200 | Service management script |
| `additions/web-ui/server.js` | New | ~100 | Node.js API server |
| `additions/web-ui/index.html` | New | ~300 | Self-contained HTML/CSS/JS |
| `docs/web-ui-guide.md` | New | ~100 | User documentation |

**Total new code:** ~880 lines
**Total effort:** 12-17 hours

---

## Implementation Order

```
Week 1:
├── Phase 1: Enhance Component Scanner (2-3h)
│   ├── Add JSON output functions
│   ├── Parse SCRIPT_COMMANDS for commands
│   └── Test with jq
│
├── Phase 2: Create Web Server (3-4h)
│   ├── Basic HTTP server
│   ├── API endpoints
│   └── SSE streaming
│
└── Phase 3: Create Web UI (4-5h)
    ├── HTML structure
    ├── CSS dark theme
    └── JavaScript logic

Week 2:
├── Phase 4: Integration (1-2h)
│   ├── Startup integration
│   ├── CLI command
│   └── Documentation
│
└── Phase 5: Testing & Polish (2-3h)
    ├── End-to-end tests
    ├── Browser testing
    └── Bug fixes
```

---

## Future Enhancements

After initial implementation, consider:

1. **Authentication** - Simple token or password protection
2. **Multi-user** - Lock scripts during execution
3. **History** - Log of executed scripts
4. **Favorites** - Pin frequently used scripts
5. **Search** - Filter scripts by name/description
6. **Mobile** - Touch-friendly interface
7. **Notifications** - Browser notifications on completion
8. **Themes** - Light theme option

---

## Handling Interactive Config Scripts

Config scripts that require interactive input (stdin prompts) cannot be run directly from the web UI.

### Solution for v1

The web UI will detect interactive config scripts and display a message instead of action buttons:

```
┌─────────────────────────────────────────────────────────────┐
│ ⚙️  Developer Identity                                       │
│ Configure your identity for devcontainer monitoring          │
│                                                              │
│ ⚠️  Interactive configuration required                       │
│                                                              │
│ Run in terminal:                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ bash .devcontainer/additions/config-identity.sh         │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                     [Copy Command]           │
└─────────────────────────────────────────────────────────────┘
```

### What Works in Web UI

| Script Type | Action | Web UI Support |
|-------------|--------|----------------|
| `config-*.sh` | Default (interactive) | ❌ Show terminal command |
| `config-*.sh` | `--show` | ✅ Display output |
| `config-*.sh` | `--verify` | ✅ Run and show result |
| `install-*.sh` | All actions | ✅ Full support |
| `service-*.sh` | All actions | ✅ Full support |
| `cmd-*.sh` | Non-interactive | ✅ Full support |

### Future Enhancement (v2)

For a future version, consider:
- Form-based input that maps to script parameters
- Pre-defined prompts in SCRIPT_COMMANDS metadata
- WebSocket-based pseudo-terminal (complex)

---

## Open Items

| Item | Status | Notes |
|------|--------|-------|
| Long operations timeout | Deferred | No timeout for v1, add cancel button later |
| Multiple concurrent executions | Deferred | Allow for v1, add queue/lock later if needed |

---

**Document Version:** 1.1
**Created:** 2024-12-07
**Updated:** 2024-12-07
**Status:** Ready for Implementation
