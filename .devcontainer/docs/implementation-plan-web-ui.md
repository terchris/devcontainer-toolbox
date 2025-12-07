# Implementation Plan: Web-Based UI for DevContainer Additions System

## Overview

This plan outlines the steps to implement a browser-based management interface that mirrors the terminal `dev-setup` menu, reusing the existing scripts and metadata system.

### Design Principles

- **Zero dependencies** - Use only Node.js built-in modules (no npm install)
- **Minimal footprint** - Target ~100 lines for server, single HTML file for UI
- **Full compatibility** - Call existing scripts without modification
- **Real-time feedback** - Stream script output via Server-Sent Events (SSE)
- **Consistent UX** - Mirror the terminal menu structure and status indicators

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

## Phase 2: Create Web Server

**Goal:** Minimal Node.js server with API endpoints and SSE streaming

### 2.1 Server Structure

**File:** `.devcontainer/manage/web-server.js`

**Dependencies:** Node.js built-in modules only
- `http` - HTTP server
- `fs` - File system (read HTML)
- `path` - Path utilities
- `child_process` - Execute scripts
- `url` - Parse URLs

### 2.2 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Serve the HTML UI |
| `GET` | `/api/scripts` | Get all scripts as JSON |
| `GET` | `/api/scripts/:type` | Get scripts by type (install/config/service/cmd) |
| `GET` | `/api/status/:id` | Check status of specific script |
| `POST` | `/api/execute` | Execute script with streaming output |
| `GET` | `/api/categories` | Get category definitions |

### 2.3 Script Execution with SSE

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

### 2.4 Server Code Outline

```javascript
#!/usr/bin/env node
// File: .devcontainer/manage/web-server.js
// Web UI server for DevContainer Additions System
// Usage: node web-server.js [port]

const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const url = require('url');

const PORT = process.argv[2] || 8888;
const ADDITIONS_DIR = path.join(__dirname, '../additions');
const SCANNER = path.join(ADDITIONS_DIR, 'lib/component-scanner.sh');

// Routes
const routes = {
  'GET /': serveUI,
  'GET /api/scripts': getScripts,
  'GET /api/status': getStatus,
  'POST /api/execute': executeScript,
};

// Server implementation (~100 lines)
// ...
```

### 2.5 Security Considerations

- Only allow execution of scripts in `additions/` directory
- Validate script filenames against allowlist
- Sanitize arguments (no shell injection)
- Bind to localhost only by default
- Optional: Add simple token authentication

### 2.6 Testing

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

**Goal:** Integrate web UI into devcontainer startup and documentation

### 4.1 Add Startup Command

**File:** `.devcontainer/manage/postCreateCommand.sh`

Add optional web server startup:
```bash
# Start web UI server (optional, disabled by default)
if [ "${DEVCONTAINER_WEB_UI:-false}" = "true" ]; then
    echo "Starting web UI server on port 8888..."
    node /workspace/.devcontainer/manage/web-server.js 8888 &
fi
```

### 4.2 Add to devcontainer.json

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

### 4.3 Add CLI Command

**File:** `.devcontainer/manage/dev-web.sh`

```bash
#!/bin/bash
# Start web UI for DevContainer Setup
# Usage: dev-web [port]

PORT="${1:-8888}"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo "Starting DevContainer Setup Web UI..."
echo "Open: http://localhost:$PORT"
echo "Press Ctrl+C to stop"

node "$SCRIPT_DIR/web-server.js" "$PORT"
```

Add to PATH in postCreateCommand or .bashrc:
```bash
alias dev-web='bash /workspace/.devcontainer/manage/dev-web.sh'
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
| `lib/component-scanner.sh` | Modified | +100 | Add JSON output functions |
| `manage/web-server.js` | New | ~100 | Node.js API server |
| `manage/web-ui.html` | New | ~300 | Self-contained HTML/CSS/JS |
| `manage/dev-web.sh` | New | ~15 | CLI launcher script |
| `docs/web-ui-guide.md` | New | ~100 | User documentation |

**Total new code:** ~500 lines
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

## Questions to Resolve

1. **Port selection** - Default 8888? Configurable?
2. **Auto-start** - Start web server automatically or on-demand?
3. **Security** - Localhost only or allow network access?
4. **Interactive scripts** - How to handle stdin prompts in web UI?
5. **Long operations** - Timeout? Cancel button?

---

**Document Version:** 1.0
**Created:** 2024-12-07
**Status:** Draft
