# Service Script Template - Developer Guide

**Location:** `/workspace/.devcontainer/additions/addition-templates/_template-service-script.sh`

This template helps you create **service-*.sh** scripts that manage long-running background services with supervisord integration and extensible operations.

---

## Table of Contents

1. [Overview](#overview)
2. [Why service-*.sh Pattern?](#why-service-sh-pattern)
3. [Quick Start](#quick-start)
4. [Template Structure](#template-structure)
5. [Metadata Fields](#metadata-fields)
6. [COMMANDS Array](#commands-array)
7. [Core Functions](#core-functions)
8. [Supervisord Integration](#supervisord-integration)
9. [Helper Functions](#helper-functions)
10. [Best Practices](#best-practices)
11. [Testing](#testing)
12. [Examples](#examples)
13. [Migration from start-*/stop-* Pattern](#migration-from-start-stop-pattern)

---

## Overview

**service-*.sh** scripts are the modern pattern for managing long-running background services in the devcontainer. They consolidate start/stop functionality and provide extensible operations for service management.

### What They Replace

**Old pattern (2 files):**
```
start-nginx.sh     ← Start service
stop-nginx.sh      ← Stop service
```

**New pattern (1 file):**
```
service-nginx.sh   ← All operations: start, stop, restart, status, logs, validate, reload, etc.
```

### Key Features

- **Single file** consolidates all service operations
- **Extensible** - easy to add new operations (--logs, --health, --validate)
- **Framework integration** - reuses cmd-framework.sh for parsing and help
- **Supervisord compatible** - works with automatic service management
- **Discoverable** - automatic integration with config-supervisor.sh and dev-setup.sh
- **4 operations → 18+ operations** - from basic start/stop to comprehensive management

---

## Why service-*.sh Pattern?

### Advantages Over start-*/stop-* Pattern

| Aspect | Old Pattern (start-*/stop-*) | New Pattern (service-*) |
|--------|------------------------------|-------------------------|
| **Files** | 2 files per service | 1 file per service |
| **Operations** | 2 ops (start, stop) | 10+ ops (start, stop, restart, status, logs, validate, reload, etc.) |
| **Help text** | Manual duplication | Auto-generated from COMMANDS array |
| **Extensibility** | Add new script for each op | Add 1 line to COMMANDS array |
| **Discovery** | Only start-*.sh discovered | Full service-*.sh discovery |
| **Naming clarity** | Ambiguous (install vs start?) | Clear (cmd vs service) |
| **Framework reuse** | Custom parsing | Uses cmd-framework.sh |
| **Dev menu** | Start/Stop buttons only | Shows all available operations |

### Real-World Example

**Before (nginx with start-*/stop-*):**
```bash
# 4 total operations across 2 files
bash start-nginx.sh              # Start
bash stop-nginx.sh               # Stop
# No restart, status, logs, validate, reload, etc.
```

**After (nginx with service-*):**
```bash
# 18+ operations in 1 file
bash service-nginx.sh --start         # Start
bash service-nginx.sh --stop          # Stop
bash service-nginx.sh --restart       # Restart
bash service-nginx.sh --status        # Status
bash service-nginx.sh --logs          # Logs
bash service-nginx.sh --logs-follow   # Follow logs
bash service-nginx.sh --validate      # Validate config
bash service-nginx.sh --reload        # Reload config
bash service-nginx.sh --show-config   # Show config
bash service-nginx.sh --test          # Test connectivity
bash service-nginx.sh --health        # Health check
# Easy to add more!
```

---

## Quick Start

### 1. Copy the Template

```bash
cp /workspace/.devcontainer/additions/addition-templates/_template-service-script.sh \
   /workspace/.devcontainer/additions/service-myservice.sh
```

### 2. Edit Metadata Section

```bash
# Update these fields
SERVICE_SCRIPT_NAME="My Service"
SERVICE_SCRIPT_DESCRIPTION="My awesome background service"
SERVICE_SCRIPT_CATEGORY="INFRA_CONFIG"
SERVICE_PREREQUISITE_CONFIGS=""  # Or "config-myservice.sh"
```

### 3. Define COMMANDS Array

```bash
COMMANDS=(
    "Control|--start|Start service in foreground|service_start|false|"
    "Control|--stop|Stop service gracefully|service_stop|false|"
    "Control|--restart|Restart service|service_restart|false|"
    "Status|--status|Check if service is running|service_status|false|"
    "Status|--logs|Show recent logs|service_logs|false|"
    "Config|--validate|Validate service configuration|service_validate|false|"
)
```

### 4. Implement Service Functions

```bash
service_start() {
    echo "🚀 Starting $SERVICE_SCRIPT_NAME"
    check_prerequisites || exit 1
    load_configuration

    # CRITICAL: Use 'exec' for supervisord integration
    exec "$SERVICE_BINARY" --foreground --config "$SERVICE_CONFIG_FILE"
}

service_stop() {
    echo "🛑 Stopping $SERVICE_SCRIPT_NAME"
    # Your stop logic here
}

service_status() {
    if is_service_running; then
        echo "✅ $SERVICE_SCRIPT_NAME is running"
    else
        echo "❌ $SERVICE_SCRIPT_NAME is not running"
    fi
}
```

### 5. Test the Service

```bash
# Test all operations
bash /workspace/.devcontainer/additions/service-myservice.sh --help
bash /workspace/.devcontainer/additions/service-myservice.sh --validate
bash /workspace/.devcontainer/additions/service-myservice.sh --status

# Enable for auto-start
echo "my-service" >> /workspace/.devcontainer.extend/enabled-services.conf
bash /workspace/.devcontainer/additions/config-supervisor.sh
```

---

## Template Structure

The `_template-service-script.sh` file is organized into these sections:

### 1. Metadata Section (Lines 1-20)

```bash
SERVICE_SCRIPT_NAME="Example Service"
SERVICE_SCRIPT_DESCRIPTION="Example background service for demonstration"
SERVICE_SCRIPT_CATEGORY="INFRA_CONFIG"
SERVICE_PREREQUISITE_CONFIGS=""
```

### 2. COMMANDS Array (Lines 22-40)

```bash
COMMANDS=(
    "Control|--start|Start service|service_start|false|"
    "Control|--stop|Stop service|service_stop|false|"
    # ... 11 total commands
)
```

### 3. Configuration Variables (Lines 42-60)

```bash
SERVICE_BINARY="/usr/sbin/myservice"
SERVICE_CONFIG_FILE="/etc/myservice/config.conf"
SERVICE_PID_FILE="/var/run/myservice.pid"
SERVICE_LOG_FILE="/var/log/myservice/service.log"
```

### 4. Helper Functions (Lines 62-200)

```bash
check_prerequisites()
load_configuration()
is_service_running()
get_service_pid()
wait_for_service_ready()
```

### 5. Service Operations (Lines 202-500)

```bash
service_start()      # Control operations
service_stop()
service_restart()
service_status()     # Status operations
service_logs()
service_validate()   # Config operations
# ... etc
```

### 6. Framework Integration (Lines 502-550)

```bash
show_help()          # Uses cmd-framework.sh
parse_args()         # Uses cmd-framework.sh
main()               # Entry point
```

---

## Metadata Fields

### SERVICE_SCRIPT_NAME

**Required:** Yes
**Type:** String (2-4 words)
**Description:** Human-readable service name

**Examples:**
```bash
SERVICE_SCRIPT_NAME="Nginx Reverse Proxy"
SERVICE_SCRIPT_NAME="OTel Monitoring"
SERVICE_SCRIPT_NAME="PostgreSQL Database"
```

**Used for:**
- Display in dev-setup menu
- Service identification in logs
- Supervisord program name (converted to lowercase-with-dashes)

### SERVICE_SCRIPT_DESCRIPTION

**Required:** Yes
**Type:** String (one sentence)
**Description:** Brief service description

**Examples:**
```bash
SERVICE_SCRIPT_DESCRIPTION="Reverse proxy for all devcontainer services"
SERVICE_SCRIPT_DESCRIPTION="OpenTelemetry collector and Grafana dashboards"
```

**Used for:**
- Dev-setup menu display
- Help text header

### SERVICE_SCRIPT_CATEGORY

**Required:** Yes
**Type:** String (category identifier)
**Description:** Service category for menu organization

**Valid Categories:**
- `INFRA_CONFIG` - Infrastructure services (nginx, databases, message queues)
- `MONITORING` - Monitoring and observability (OTel, Prometheus, Grafana)
- `DEV_TOOLS` - Development services (hot reload, file watchers)
- `AI_TOOLS` - AI services (model servers, GPU services)
- `DATABASE` - Database services
- `UNCATEGORIZED` - Other services

**Example:**
```bash
SERVICE_SCRIPT_CATEGORY="INFRA_CONFIG"
```

### SERVICE_PREREQUISITE_CONFIGS

**Required:** No
**Type:** String (space-separated config script filenames) or empty string
**Description:** Configuration scripts required before service starts

**Examples:**
```bash
# No prerequisites
SERVICE_PREREQUISITE_CONFIGS=""

# Single prerequisite
SERVICE_PREREQUISITE_CONFIGS="config-nginx.sh"

# Multiple prerequisites
SERVICE_PREREQUISITE_CONFIGS="config-database.sh config-redis.sh"
```

**How it works:**
- config-supervisor.sh checks prerequisites before adding to supervisord
- If missing, service won't auto-start
- User prompted to run config scripts first

### SERVICE_PRIORITY

**Optional:** Priority for supervisord startup order
**Default:** 50
**Range:** 1-99 (lower = starts earlier)

**Example:**
```bash
SERVICE_PRIORITY="30"  # Start before services with priority 50
```

### SERVICE_DEPENDS

**Optional:** Supervisord dependencies
**Format:** Space-separated program names

**Example:**
```bash
SERVICE_DEPENDS="postgresql redis"  # Wait for these services first
```

### SERVICE_AUTO_RESTART

**Optional:** Supervisord auto-restart policy
**Default:** true

**Example:**
```bash
SERVICE_AUTO_RESTART="true"   # Restart on crash
SERVICE_AUTO_RESTART="false"  # Don't restart
```

---

## COMMANDS Array

The COMMANDS array is the **single source of truth** for all service operations. Each line defines one command.

### Format (6 fields, pipe-separated)

```
"category|flag|description|function|requires_arg|param_prompt"
```

### Field Definitions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| **category** | string | Command grouping | `"Control"`, `"Status"`, `"Config"`, `"Debug"` |
| **flag** | string | Command line flag (--prefix) | `"--start"`, `"--logs"`, `"--reload"` |
| **description** | string | User-friendly description | `"Start service in foreground"` |
| **function** | string | Function name to call | `"service_start"`, `"service_logs"` |
| **requires_arg** | boolean | Needs parameter? | `"true"`, `"false"` |
| **param_prompt** | string | Parameter prompt (empty if no param) | `"Enter port number"`, `""` |

### Standard Categories

**Control:** Service lifecycle operations
```bash
"Control|--start|Start service in foreground (for supervisord)|service_start|false|"
"Control|--stop|Stop service gracefully|service_stop|false|"
"Control|--restart|Restart service|service_restart|false|"
```

**Status:** Service monitoring operations
```bash
"Status|--status|Check if service is running|service_status|false|"
"Status|--logs|Show recent logs|service_logs|false|"
"Status|--logs-follow|Follow logs in real-time|service_logs_follow|false|"
```

**Config:** Configuration operations
```bash
"Config|--validate|Validate service configuration|service_validate|false|"
"Config|--reload|Reload configuration without restart|service_reload|false|"
"Config|--show-config|Display current configuration|service_show_config|false|"
```

**Debug:** Troubleshooting operations
```bash
"Debug|--test|Test service connectivity|service_test|false|"
"Debug|--health|Check service health|service_health|false|"
```

### Example with Parameter

```bash
COMMANDS=(
    "Config|--set-port|Change service port|service_set_port|true|Enter port number (1-65535)"
)

service_set_port() {
    local port="$1"
    # Validate port
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "Invalid port: $port"
        exit 1
    fi
    # Update config with new port
    update_service_config "PORT" "$port"
}
```

---

## Core Functions

### service_start()

**Purpose:** Start the service in foreground mode (for supervisord)

**Critical requirement:** Must use `exec` to replace shell process

```bash
service_start() {
    echo "🚀 Starting $SERVICE_SCRIPT_NAME"

    # 1. Check prerequisites
    check_prerequisites || exit 1

    # 2. Load configuration
    load_configuration

    # 3. Check if already running
    if is_service_running; then
        log_warning "Service is already running"
        exit 0
    fi

    # 4. Clean up old process
    service_stop 2>/dev/null || true
    sleep 1

    # 5. Start with exec (CRITICAL for supervisord)
    log_info "Starting $SERVICE_BINARY..."
    exec "$SERVICE_BINARY" --foreground --config "$SERVICE_CONFIG_FILE"

    # IMPORTANT: Code after exec will NEVER run
    # The shell process is replaced by the service
}
```

**Why exec is critical:**
- Supervisord expects to manage the actual service process
- Without exec, supervisord manages the shell wrapper
- Service crashes won't be detected properly
- Service won't stop correctly

### service_stop()

**Purpose:** Stop the service gracefully with fallback to force kill

```bash
service_stop() {
    echo "🛑 Stopping $SERVICE_SCRIPT_NAME"

    # Get PID
    local pid=$(get_service_pid)

    if [ -z "$pid" ]; then
        log_info "Service is not running"
        return 0
    fi

    # Try graceful shutdown
    log_info "Sending SIGTERM to process $pid..."
    kill -TERM "$pid" 2>/dev/null || true

    # Wait for graceful shutdown (10 seconds)
    for i in {1..10}; do
        if ! ps -p "$pid" > /dev/null 2>&1; then
            log_success "Service stopped gracefully"
            rm -f "$SERVICE_PID_FILE"
            return 0
        fi
        sleep 1
    done

    # Force kill if still running
    log_warning "Graceful shutdown failed, forcing..."
    kill -KILL "$pid" 2>/dev/null || true
    sleep 1
    rm -f "$SERVICE_PID_FILE"

    log_success "Service stopped (forced)"
}
```

### service_restart()

**Purpose:** Restart the service (for manual use, not supervisord)

**Critical requirement:** Does NOT use `exec` (different from service_start)

```bash
service_restart() {
    echo "🔄 Restarting $SERVICE_SCRIPT_NAME"

    # Stop the service
    service_stop
    sleep 2

    # Check prerequisites
    check_prerequisites || exit 1
    load_configuration

    # Start in background (NO EXEC!)
    log_info "Starting $SERVICE_BINARY..."
    "$SERVICE_BINARY" --daemon --config "$SERVICE_CONFIG_FILE" &

    # Wait for service to be ready
    wait_for_service_ready

    log_success "Service restarted successfully"
}
```

**Why no exec:**
- restart must complete and return to user
- exec would replace shell and prevent return
- Only service_start (for supervisord) uses exec

### service_status()

**Purpose:** Check and display service status

```bash
service_status() {
    echo "📊 $SERVICE_SCRIPT_NAME Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if is_service_running; then
        local pid=$(get_service_pid)
        echo "✅ Status: Running"
        echo "   PID: $pid"
        echo "   Uptime: $(ps -p "$pid" -o etime= | tr -d ' ')"
        echo "   Config: $SERVICE_CONFIG_FILE"
        return 0
    else
        echo "❌ Status: Not running"
        return 1
    fi
}
```

### service_logs()

**Purpose:** Show recent service logs

```bash
service_logs() {
    echo "📋 Recent logs for $SERVICE_SCRIPT_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -f "$SERVICE_LOG_FILE" ]; then
        tail -n 50 "$SERVICE_LOG_FILE"
    else
        log_error "Log file not found: $SERVICE_LOG_FILE"
        exit 1
    fi
}
```

### service_validate()

**Purpose:** Validate service configuration without starting

```bash
service_validate() {
    echo "🔍 Validating $SERVICE_SCRIPT_NAME configuration"

    # Check config file exists
    if [ ! -f "$SERVICE_CONFIG_FILE" ]; then
        log_error "Configuration file not found: $SERVICE_CONFIG_FILE"
        exit 1
    fi

    # Validate config syntax
    if "$SERVICE_BINARY" --test-config "$SERVICE_CONFIG_FILE" 2>/dev/null; then
        log_success "Configuration is valid"
        return 0
    else
        log_error "Configuration validation failed"
        exit 1
    fi
}
```

---

## Supervisord Integration

### How It Works

1. **Discovery:** `config-supervisor.sh` discovers service-*.sh files
2. **Metadata extraction:** Reads SERVICE_SCRIPT_NAME, SERVICE_PRIORITY, etc.
3. **Config generation:** Creates supervisord .conf file
4. **Command construction:** Uses `bash /path/to/service-name.sh --start`
5. **Service management:** Supervisord runs --start in foreground

### Generated Supervisord Config

For `service-nginx.sh`, config-supervisor.sh generates:

```ini
[program:nginx-reverse-proxy]
command=bash /workspace/.devcontainer/additions/service-nginx.sh --start
autostart=true
autorestart=true
priority=30
user=vscode
stdout_logfile=/var/log/supervisor/nginx-reverse-proxy.log
stderr_logfile=/var/log/supervisor/nginx-reverse-proxy-error.log
startsecs=5
stopwaitsecs=10
```

### Enabling Auto-Start

```bash
# 1. Add to enabled services
echo "nginx-reverse-proxy" >> /workspace/.devcontainer.extend/enabled-services.conf

# 2. Regenerate supervisord config
bash /workspace/.devcontainer/additions/config-supervisor.sh

# 3. Service starts automatically
```

### Manual vs Supervisord Start

**Supervisord start:**
```bash
# Uses --start with exec
sudo supervisorctl start nginx-reverse-proxy
# Runs: bash service-nginx.sh --start
# service_start() uses exec
```

**Manual start for testing:**
```bash
# Use --restart or run service manually
bash service-nginx.sh --restart
# service_restart() does NOT use exec, returns to shell
```

---

## Helper Functions

### check_prerequisites()

**Purpose:** Validate binary and configuration exist

```bash
check_prerequisites() {
    local missing=0

    # Check if service binary exists
    if [ ! -f "$SERVICE_BINARY" ]; then
        log_error "Service binary not found: $SERVICE_BINARY"
        ((missing++))
    fi

    # Check if config file exists
    if [ ! -f "$SERVICE_CONFIG_FILE" ]; then
        log_error "Configuration file not found: $SERVICE_CONFIG_FILE"
        ((missing++))
    fi

    if [ $missing -gt 0 ]; then
        log_error "Prerequisites not met. Run installation first."
        return 1
    fi

    return 0
}
```

### load_configuration()

**Purpose:** Load service configuration from file

```bash
load_configuration() {
    if [ -f "$SERVICE_CONFIG_FILE" ]; then
        # Source config file or parse it
        source "$SERVICE_CONFIG_FILE"
        log_info "Configuration loaded from $SERVICE_CONFIG_FILE"
    fi
}
```

### is_service_running()

**Purpose:** Check if service process is running

```bash
is_service_running() {
    local pid=$(get_service_pid)

    if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
        return 0  # Running
    else
        return 1  # Not running
    fi
}
```

### get_service_pid()

**Purpose:** Get service PID from file or process name

```bash
get_service_pid() {
    # Try PID file first
    if [ -f "$SERVICE_PID_FILE" ]; then
        cat "$SERVICE_PID_FILE" 2>/dev/null
        return 0
    fi

    # Fallback: search by process name
    pgrep -f "$SERVICE_BINARY" 2>/dev/null | head -1
}
```

### wait_for_service_ready()

**Purpose:** Wait for service to be ready with timeout

```bash
wait_for_service_ready() {
    local max_wait=30
    local waited=0

    log_info "Waiting for service to be ready..."

    while [ $waited -lt $max_wait ]; do
        if is_service_running; then
            log_success "Service is ready"
            return 0
        fi
        sleep 1
        ((waited++))
    done

    log_error "Service failed to start within ${max_wait}s"
    return 1
}
```

---

## Best Practices

### 1. Always Use exec in service_start()

```bash
# CORRECT - for supervisord
service_start() {
    check_prerequisites || exit 1
    exec "$SERVICE_BINARY" --foreground  # Replaces shell process
}

# WRONG - supervisord will manage shell, not service
service_start() {
    check_prerequisites || exit 1
    "$SERVICE_BINARY" --foreground  # Shell stays alive
}
```

### 2. Never Use exec in service_restart()

```bash
# CORRECT - for manual restart
service_restart() {
    service_stop
    "$SERVICE_BINARY" --daemon &  # NO exec, function returns
    wait_for_service_ready
}

# WRONG - will not return, stuck forever
service_restart() {
    service_stop
    exec "$SERVICE_BINARY" --daemon  # Never returns!
}
```

### 3. Graceful Shutdown with Fallback

```bash
service_stop() {
    local pid=$(get_service_pid)

    # Try graceful (SIGTERM)
    kill -TERM "$pid" 2>/dev/null || true
    sleep 5

    # Fallback to force (SIGKILL)
    if ps -p "$pid" > /dev/null 2>&1; then
        kill -KILL "$pid" 2>/dev/null || true
    fi
}
```

### 4. Validate Before Starting

```bash
service_start() {
    # Always check prerequisites first
    check_prerequisites || exit 1

    # Validate config if possible
    service_validate 2>/dev/null || log_warning "Could not validate config"

    # Then start
    exec "$SERVICE_BINARY" --foreground
}
```

### 5. Provide Rich Status Information

```bash
service_status() {
    if is_service_running; then
        echo "✅ Running"
        echo "   PID: $(get_service_pid)"
        echo "   Port: $(netstat -tlnp | grep myservice | awk '{print $4}')"
        echo "   Uptime: $(ps -p $pid -o etime=)"
    else
        echo "❌ Not running"
        # Show why it might have failed
        if [ -f "$SERVICE_LOG_FILE" ]; then
            echo "   Last error:"
            tail -5 "$SERVICE_LOG_FILE" | grep -i error
        fi
    fi
}
```

### 6. Make Operations Idempotent

```bash
service_start() {
    # Check if already running
    if is_service_running; then
        log_warning "Service is already running"
        exit 0  # Not an error
    fi

    # Start service
    exec "$SERVICE_BINARY" --foreground
}

service_stop() {
    # Check if not running
    if ! is_service_running; then
        log_info "Service is not running"
        return 0  # Not an error
    fi

    # Stop service
    kill_service_process
}
```

---

## Testing

### 1. Test All Operations

```bash
# Test help
bash service-myservice.sh --help

# Test safe operations (don't start/stop)
bash service-myservice.sh --validate
bash service-myservice.sh --show-config

# Test status when not running
bash service-myservice.sh --status

# Test start (manual, no supervisord)
bash service-myservice.sh --restart  # Use restart, not start

# Test status when running
bash service-myservice.sh --status

# Test logs
bash service-myservice.sh --logs

# Test stop
bash service-myservice.sh --stop
```

### 2. Test Supervisord Integration

```bash
# Enable service
echo "my-service" >> /workspace/.devcontainer.extend/enabled-services.conf

# Regenerate supervisor config
bash /workspace/.devcontainer/additions/config-supervisor.sh

# Check if discovered
sudo supervisorctl status | grep my-service

# Start via supervisord
sudo supervisorctl start my-service

# Check logs
sudo supervisorctl tail my-service

# Stop via supervisord
sudo supervisorctl stop my-service
```

### 3. Test Discovery

```bash
# Test metadata extraction
source /workspace/.devcontainer/additions/lib/component-scanner.sh

# Scan for service scripts
while IFS=$'\t' read -r basename name desc cat path prereqs; do
    echo "Found: $name (category: $cat)"
done < <(scan_service_scripts_new /workspace/.devcontainer/additions)

# Extract commands
extract_service_commands /workspace/.devcontainer/additions/service-myservice.sh
```

### 4. Test exec Behavior

```bash
# This should REPLACE the shell process (for supervisord)
bash -c 'echo "Before exec"; exec sleep 10; echo "After exec (never prints)"' &
ps aux | grep sleep  # Should see sleep, not bash

# This should NOT replace (for restart)
bash -c 'echo "Before start"; sleep 10 &; echo "After start (prints)"'
```

---

## Examples

### Example 1: Simple HTTP Service

```bash
#!/bin/bash
# File: service-webserver.sh

SERVICE_SCRIPT_NAME="Web Server"
SERVICE_SCRIPT_DESCRIPTION="Simple HTTP server for development"
SERVICE_SCRIPT_CATEGORY="INFRA_CONFIG"
SERVICE_PREREQUISITE_CONFIGS=""

COMMANDS=(
    "Control|--start|Start web server in foreground|service_start|false|"
    "Control|--stop|Stop web server|service_stop|false|"
    "Control|--restart|Restart web server|service_restart|false|"
    "Status|--status|Check server status|service_status|false|"
    "Status|--logs|Show recent logs|service_logs|false|"
    "Config|--validate|Validate configuration|service_validate|false|"
)

SERVICE_BINARY="/usr/bin/python3"
SERVICE_PORT="8080"
SERVICE_LOG_FILE="/var/log/webserver.log"

service_start() {
    echo "🚀 Starting $SERVICE_SCRIPT_NAME on port $SERVICE_PORT"

    # Start Python HTTP server (foreground with exec)
    exec python3 -m http.server "$SERVICE_PORT" 2>&1 | tee -a "$SERVICE_LOG_FILE"
}

service_stop() {
    echo "🛑 Stopping $SERVICE_SCRIPT_NAME"
    pkill -f "http.server $SERVICE_PORT" || true
}

service_status() {
    if pgrep -f "http.server $SERVICE_PORT" > /dev/null; then
        echo "✅ Web server is running on port $SERVICE_PORT"
        echo "   URL: http://localhost:$SERVICE_PORT"
    else
        echo "❌ Web server is not running"
    fi
}

# ... (include framework integration from template)
```

### Example 2: Database Service with Health Check

```bash
#!/bin/bash
# File: service-database.sh

SERVICE_SCRIPT_NAME="PostgreSQL Database"
SERVICE_SCRIPT_DESCRIPTION="PostgreSQL database server"
SERVICE_SCRIPT_CATEGORY="DATABASE"
SERVICE_PREREQUISITE_CONFIGS="config-database.sh"

COMMANDS=(
    "Control|--start|Start database|service_start|false|"
    "Control|--stop|Stop database|service_stop|false|"
    "Control|--restart|Restart database|service_restart|false|"
    "Status|--status|Check database status|service_status|false|"
    "Status|--logs|Show database logs|service_logs|false|"
    "Debug|--health|Check database health|service_health|false|"
    "Debug|--connections|Show active connections|service_connections|false|"
)

SERVICE_BINARY="/usr/lib/postgresql/15/bin/postgres"
SERVICE_CONFIG_FILE="/etc/postgresql/15/main/postgresql.conf"
SERVICE_DATA_DIR="/var/lib/postgresql/15/main"
SERVICE_LOG_FILE="/var/log/postgresql/postgresql-15-main.log"

service_start() {
    echo "🚀 Starting PostgreSQL"

    check_prerequisites || exit 1

    # Start PostgreSQL (foreground with exec)
    exec su - postgres -c "$SERVICE_BINARY -D $SERVICE_DATA_DIR -c config_file=$SERVICE_CONFIG_FILE"
}

service_health() {
    echo "🏥 Checking PostgreSQL health"

    # Try to connect
    if su - postgres -c "psql -c 'SELECT 1;'" > /dev/null 2>&1; then
        echo "✅ Database is healthy and accepting connections"

        # Show stats
        su - postgres -c "psql -c 'SELECT version();'"
        su - postgres -c "psql -c 'SELECT pg_database_size(current_database());'"
    else
        echo "❌ Database health check failed"
        exit 1
    fi
}

service_connections() {
    echo "📊 Active database connections"
    su - postgres -c "psql -c 'SELECT * FROM pg_stat_activity;'"
}

# ... (include framework integration from template)
```

---

## Migration from start-*/stop-* Pattern

### Migration Checklist

If you have existing start-*.sh and stop-*.sh scripts, follow this process:

#### 1. Create service-*.sh from Template

```bash
cp _template-service-script.sh service-myservice.sh
```

#### 2. Copy Metadata from start-*.sh

```bash
# From start-myservice.sh, copy:
SERVICE_NAME="My Service"              → SERVICE_SCRIPT_NAME="My Service"
SERVICE_DESCRIPTION="Description"      → SERVICE_SCRIPT_DESCRIPTION="Description"
SERVICE_CATEGORY="INFRA_CONFIG"        → SERVICE_SCRIPT_CATEGORY="INFRA_CONFIG"
```

#### 3. Migrate service_start() Logic

```bash
# From start-myservice.sh main() function, extract start logic
# Add check_prerequisites() call
# Change final command to use exec

# Before (start-myservice.sh):
main() {
    echo "Starting service..."
    /usr/bin/myservice --foreground
}

# After (service-myservice.sh):
service_start() {
    echo "🚀 Starting $SERVICE_SCRIPT_NAME"
    check_prerequisites || exit 1
    exec /usr/bin/myservice --foreground  # Added exec!
}
```

#### 4. Migrate service_stop() Logic

```bash
# From stop-myservice.sh, copy stop logic

# Before (stop-myservice.sh):
main() {
    pkill myservice
}

# After (service-myservice.sh):
service_stop() {
    echo "🛑 Stopping $SERVICE_SCRIPT_NAME"
    local pid=$(get_service_pid)
    kill -TERM "$pid" 2>/dev/null || true
    # Add graceful shutdown wait + force kill
}
```

#### 5. Add New Operations

This is where the extensibility shines! Add operations that weren't possible before:

```bash
COMMANDS=(
    # Migrated from start/stop
    "Control|--start|Start service|service_start|false|"
    "Control|--stop|Stop service|service_stop|false|"

    # NEW operations (easy to add!)
    "Control|--restart|Restart service|service_restart|false|"
    "Status|--status|Check status|service_status|false|"
    "Status|--logs|Show logs|service_logs|false|"
    "Status|--logs-follow|Follow logs|service_logs_follow|false|"
    "Config|--validate|Validate config|service_validate|false|"
    "Config|--reload|Reload config|service_reload|false|"
    "Debug|--health|Health check|service_health|false|"
)
```

#### 6. Test Both Patterns Coexist

During migration, both patterns work simultaneously:

```bash
# Old pattern still works
bash start-myservice.sh
bash stop-myservice.sh

# New pattern also works
bash service-myservice.sh --start
bash service-myservice.sh --stop
bash service-myservice.sh --status  # NEW!
```

#### 7. Update enabled-services.conf

```bash
# Service name stays the same
echo "my-service" >> /workspace/.devcontainer.extend/enabled-services.conf
bash /workspace/.devcontainer/additions/config-supervisor.sh
# config-supervisor.sh now discovers BOTH patterns
```

#### 8. Test Supervisord Integration

```bash
# Regenerate config (discovers service-*.sh)
bash /workspace/.devcontainer/additions/config-supervisor.sh

# Should show: Found: My Service [service-*.sh]
# (not [start-*.sh])

# Test supervisord
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start my-service
```

#### 9. Remove Old Scripts (After Verification)

```bash
# After confirming service-*.sh works:
rm /workspace/.devcontainer/additions/start-myservice.sh
rm /workspace/.devcontainer/additions/stop-myservice.sh

# Update any documentation references
grep -r "start-myservice" /workspace/.devcontainer
```

### Migration Example: Nginx

**Before (2 files, 100 lines total):**
```
start-nginx.sh    ← 50 lines, only starts nginx
stop-nginx.sh     ← 50 lines, only stops nginx
```

**After (1 file, 300 lines total):**
```
service-nginx.sh  ← 300 lines, 9 operations:
  --start         (migrated from start-nginx.sh)
  --stop          (migrated from stop-nginx.sh)
  --restart       (NEW)
  --status        (NEW)
  --logs          (NEW)
  --logs-follow   (NEW)
  --validate      (NEW)
  --reload        (NEW)
  --test          (NEW)
```

**Result:** 50% fewer files, 450% more functionality

---

## Troubleshooting

### Service Won't Start via Supervisord

**Problem:** `supervisorctl start myservice` fails

**Check:**
```bash
# 1. Check supervisord discovered the service
sudo supervisorctl reread
sudo supervisorctl status | grep myservice

# 2. Check supervisord config was generated
ls -la /etc/supervisor/conf.d/auto-myservice.conf
cat /etc/supervisor/conf.d/auto-myservice.conf

# 3. Check command path is correct
grep "^command=" /etc/supervisor/conf.d/auto-myservice.conf

# 4. Test --start manually
bash /workspace/.devcontainer/additions/service-myservice.sh --start
# (Will hang if working - Ctrl+C to stop)

# 5. Check logs
sudo tail /var/log/supervisor/myservice-error.log
```

### Service Stops Immediately After Start

**Problem:** Service starts then stops right away

**Cause:** Probably not using `exec` in service_start()

**Fix:**
```bash
# WRONG - shell exits, service killed
service_start() {
    $SERVICE_BINARY --foreground
}

# CORRECT - shell replaced by service
service_start() {
    exec $SERVICE_BINARY --foreground
}
```

### Service Not Discovered by config-supervisor.sh

**Problem:** Service doesn't appear in supervisor config

**Check:**
```bash
# 1. Check filename pattern
ls -la /workspace/.devcontainer/additions/service-*.sh

# 2. Check metadata exists
grep "^SERVICE_SCRIPT_NAME=" service-myservice.sh

# 3. Check if enabled
cat /workspace/.devcontainer.extend/enabled-services.conf | grep myservice

# 4. Test discovery manually
source /workspace/.devcontainer/additions/lib/component-scanner.sh
scan_service_scripts_new /workspace/.devcontainer/additions | grep myservice

# 5. Check config-supervisor.sh logs
bash /workspace/.devcontainer/additions/config-supervisor.sh
# Should show: Found: My Service (priority: 50) ✅ ENABLED [service-*.sh]
```

---

## Summary

The **service-*.sh** pattern provides:

✅ **Consolidation** - 1 file instead of 2
✅ **Extensibility** - Add operations by adding 1 line to COMMANDS array
✅ **Framework reuse** - Uses cmd-framework.sh for parsing and help
✅ **Rich operations** - From 2 ops to 10+ ops per service
✅ **Supervisord compatibility** - Works with auto-start via exec
✅ **Backward compatibility** - Coexists with start-*/stop-* during migration
✅ **Better UX** - Auto-generated help, status, logs, health checks

**Next steps:**
1. Copy `_template-service-script.sh`
2. Update metadata
3. Define COMMANDS array
4. Implement operations
5. Test thoroughly
6. Enable auto-start

---

**Happy service management! 🚀**
