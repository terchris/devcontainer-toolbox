# Service Dependency Flow

This document visualizes the service prerequisite validation and dependency chain in the devcontainer toolbox.

## Dependency Chain Overview

```
┌─────────────────────┐
│  install-srv-*.sh   │  Installation Layer
│  (Binary Install)   │  - Installs actual binaries/packages
└──────────┬──────────┘  - CHECK_INSTALLED_COMMAND validates
           │
           ↓ (SERVICE_PREREQUISITE_TOOLS)
┌─────────────────────┐
│   config-*.sh       │  Configuration Layer (Optional)
│  (Configuration)    │  - Sets up configuration files
└──────────┬──────────┘  - CHECK_CONFIGURED_COMMAND validates
           │
           ↓ (SERVICE_PREREQUISITE_CONFIGS)
┌─────────────────────┐
│   service-*.sh      │  Service Layer
│  (Service Control)  │  - Starts/stops/monitors services
└─────────────────────┘  - Uses COMMANDS array for operations
           │
           ↓ (SERVICE_DEPENDS)
┌─────────────────────┐
│  Other Services     │  Runtime Dependencies
│  (Running Services) │  - Service-to-service dependencies
└─────────────────────┘
```

## Validation Flow in dev-setup.sh

When a user selects a service from the "Manage Services" menu:

```
User Selects Service
        │
        ↓
┌───────────────────────────────────────────────┐
│ 1. Check Installation Prerequisites          │
│    check_service_installation_prerequisites() │
│                                                │
│    a) Check if SERVICE_PREREQUISITE_TOOLS set │
│    b) Verify install-srv-*.sh exists          │
│    c) Extract CHECK_INSTALLED_COMMAND         │
│    d) Run check command                       │
│                                                │
│    If NOT installed:                          │
│    ┌─────────────────────────────────┐       │
│    │ Show Dialog:                    │       │
│    │ "Installation Required"         │       │
│    │ [Yes] [No]                      │       │
│    └─────────────────────────────────┘       │
│         │                                     │
│         ├─[Yes]→ Run install-srv-*.sh        │
│         │        Show output                 │
│         │        Wait for completion         │
│         │                                     │
│         └─[No]──→ Return (block service)     │
└────────────────┬──────────────────────────────┘
                 │
                 ↓ (Installation OK)
┌───────────────────────────────────────────────┐
│ 2. Check Configuration Prerequisites         │
│    (existing prerequisite-check.sh)          │
│                                                │
│    a) Check if SERVICE_PREREQUISITE_CONFIGS   │
│    b) Verify config-*.sh exists               │
│    c) Run CHECK_CONFIGURED_COMMAND            │
│                                                │
│    If NOT configured:                         │
│    ┌─────────────────────────────────┐       │
│    │ Show Dialog:                    │       │
│    │ "Prerequisites Not Met"         │       │
│    │ [OK]                            │       │
│    └─────────────────────────────────┘       │
│         │                                     │
│         └──→ Return (block service)          │
└────────────────┬──────────────────────────────┘
                 │
                 ↓ (All prerequisites met)
┌───────────────────────────────────────────────┐
│ 3. Show Service Commands Menu                │
│    show_service_submenu()                     │
│                                                │
│    Display COMMANDS array:                    │
│    - [CONTROL] Start service                  │
│    - [CONTROL] Stop service                   │
│    - [INFO] Show status                       │
│    - etc.                                     │
└───────────────────────────────────────────────┘
```

## Concrete Example: OTEL Monitoring Service

Here's the complete dependency chain for the OTEL monitoring service:

```
┌──────────────────────────────────────────────────┐
│ install-srv-otel-monitoring.sh                   │
│                                                  │
│ SCRIPT_ID="srv-otel-monitoring"                  │
│ CHECK_INSTALLED_COMMAND=                         │
│   "command -v otelcol-lifecycle >/dev/null"      │
│                                                  │
│ Installs:                                        │
│ • otelcol-lifecycle binary                       │
│ • otelcol-metrics binary                         │
│ • otelcol-exporter binary                        │
│ • Configuration templates                        │
└───────────────────┬──────────────────────────────┘
                    │
                    ↓ SERVICE_PREREQUISITE_TOOLS
┌──────────────────────────────────────────────────┐
│ config-devcontainer-identity.sh                  │
│                                                  │
│ SCRIPT_ID="config-devcontainer-identity"         │
│ CHECK_CONFIGURED_COMMAND=                        │
│   "[ -f ~/.devcontainer.secrets/... ]"           │
│                                                  │
│ Creates:                                         │
│ • DEVCONTAINER_SLUG                              │
│ • DEVCONTAINER_OWNER                             │
│ • TEAM_NAME                                      │
└───────────────────┬──────────────────────────────┘
                    │
                    ↓ SERVICE_PREREQUISITE_CONFIGS
┌──────────────────────────────────────────────────┐
│ service-otel-monitoring.sh                       │
│                                                  │
│ SERVICE_ID="otel-monitoring"                     │
│ SERVICE_PRIORITY="30"                            │
│ SERVICE_DEPENDS="service-nginx"                  │
│ SERVICE_PREREQUISITE_CONFIGS=                    │
│   "config-devcontainer-identity.sh"              │
│ SERVICE_PREREQUISITE_TOOLS=                      │
│   "install-srv-otel-monitoring.sh"               │
│                                                  │
│ Provides COMMANDS:                               │
│ • --start-lifecycle                              │
│ • --start-metrics                                │
│ • --start-exporter                               │
│ • --stop                                         │
│ • --status                                       │
│ • --logs                                         │
└───────────────────┬──────────────────────────────┘
                    │
                    ↓ SERVICE_DEPENDS (Runtime)
┌──────────────────────────────────────────────────┐
│ service-nginx.sh (must be running)               │
│                                                  │
│ OTEL sends data through nginx reverse proxy      │
│ • Lifecycle events → nginx:4318                  │
│ • Metrics → nginx:4318                           │
│ • Exporter receives from Grafana via nginx       │
└──────────────────────────────────────────────────┘
```

## Complete System: Both Services

```
┌─────────────────────────────────────────────────┐
│                 NGINX SERVICE                   │
│                                                 │
│  install-srv-nginx.sh                           │
│  ↓ (SERVICE_PREREQUISITE_TOOLS)                 │
│  service-nginx.sh                               │
│    SERVICE_ID="nginx"                           │
│    SERVICE_PRIORITY="20" ← Lower runs first     │
│    SERVICE_DEPENDS=""                           │
│                                                 │
│  Running: nginx reverse proxy                   │
│  • Port 4318 → OTLP backend                     │
│  • Port 3100 → Loki                             │
│  • Port 9090 → Prometheus                       │
└────────┬────────────────────────────────────────┘
         │
         │ Provides backend endpoints
         │
         ↓ (SERVICE_DEPENDS)
┌─────────────────────────────────────────────────┐
│             OTEL MONITORING SERVICE             │
│                                                 │
│  install-srv-otel-monitoring.sh                 │
│  ↓ (SERVICE_PREREQUISITE_TOOLS)                 │
│  config-devcontainer-identity.sh                │
│  ↓ (SERVICE_PREREQUISITE_CONFIGS)               │
│  service-otel-monitoring.sh                     │
│    SERVICE_ID="otel-monitoring"                 │
│    SERVICE_PRIORITY="30" ← Higher runs after    │
│    SERVICE_DEPENDS="service-nginx"              │
│                                                 │
│  Running: OpenTelemetry collectors              │
│  • otelcol-lifecycle (port 55680)              │
│  • otelcol-metrics (port 55681)                 │
│  • otelcol-exporter (port 55682)                │
│                                                 │
│  Sends data TO: nginx:4318                      │
└─────────────────────────────────────────────────┘
```

## Priority-Based Startup Order

The SERVICE_PRIORITY field controls the display order in dev-setup.sh and can be used for automatic startup sequencing:

```
Priority 10: Core infrastructure services (if any)
Priority 20: Nginx reverse proxy (provides endpoints)
Priority 30: OTEL monitoring (consumes nginx endpoints)
Priority 40: Application services (if any)
...
Priority 99: Default/uncategorized services
```

Lower priority numbers start first, ensuring dependencies are available.

## Auto-Enable Configuration

Services marked for auto-start are stored in `.devcontainer.extend/enabled-services.conf`:

```
# Format: SERVICE_ID (one per line)
nginx
otel-monitoring
```

When the container starts, `postStartCommand` in devcontainer.json reads this file and starts services in priority order.

## Summary

The three-layer validation ensures:

1. **Installation Layer**: Binaries/packages must be installed first
2. **Configuration Layer**: Required configurations must be set
3. **Service Layer**: Services can safely start
4. **Runtime Layer**: Dependent services are available

Each layer has its own validation mechanism, and dev-setup.sh enforces the entire chain before allowing service operations.
