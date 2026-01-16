---
title: Services Overview
sidebar_position: 1
---

# Services Documentation

Documentation for the built-in services in devcontainer-toolbox.

---

## Available Services

| Service | Description |
|---------|-------------|
| **Nginx** | Reverse proxy for routing to local services |
| **OTEL** | OpenTelemetry monitoring and observability |

---

## Nginx Reverse Proxy

The nginx service provides a reverse proxy that routes requests to services running in the devcontainer.

**Key features:**
- Automatic configuration generation
- Route multiple services on different paths
- SSL/TLS support
- WebSocket support

---

## OTEL Monitoring

The OpenTelemetry (OTEL) stack provides monitoring, logging, and tracing for the devcontainer.

**Key features:**
- Container metrics collection
- Log aggregation
- Distributed tracing
- Grafana dashboards

---

## Service Dependency Flow

Services follow a three-layer dependency model:

```
┌─────────────────────┐
│  install-srv-*.sh   │  Installation Layer
│  (Binary Install)   │  - Installs actual binaries/packages
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│   config-*.sh       │  Configuration Layer
│  (Configuration)    │  - Sets up configuration files
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│   service-*.sh      │  Service Layer
│  (Service Control)  │  - Starts/stops/monitors services
└─────────────────────┘
```

### Validation Flow

When a user selects a service from the menu:

1. **Check Installation Prerequisites** - Verify binaries installed
2. **Check Configuration Prerequisites** - Verify configs exist
3. **Show Service Commands** - Display available actions

---

## Creating New Services

To create a new service:

1. Create installation script: `install-srv-myservice.sh`
2. Create service script: `service-myservice.sh`
3. Optionally create config script: `config-myservice.sh`

Service scripts use the unified command pattern:

```bash
service-myservice.sh
    ├── --start       → Start service
    ├── --stop        → Stop service
    ├── --restart     → Restart service
    ├── --status      → Show status
    ├── --logs        → Show logs
    └── --health      → Health check
```

---

## See Also

- [Architecture](../architecture) - System architecture
- [Creating Scripts](../scripts/install-scripts) - Script creation guide
