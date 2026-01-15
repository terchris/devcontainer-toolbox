# Services Documentation

Documentation for the built-in services in devcontainer-toolbox.

---

## Available Services

| Service | Description | Documentation |
|---------|-------------|---------------|
| **Nginx** | Reverse proxy for routing to local services | [services-nginx.md](services-nginx.md) |
| **OTEL** | OpenTelemetry monitoring and observability | [services-otel.md](services-otel.md) |

---

## Nginx Reverse Proxy

The nginx service provides a reverse proxy that routes requests to services running in the devcontainer. It allows accessing multiple services through a single entry point.

**Key features:**
- Automatic configuration generation
- Route multiple services on different paths
- SSL/TLS support
- WebSocket support

See [services-nginx.md](services-nginx.md) for full documentation.

---

## OTEL Monitoring

The OpenTelemetry (OTEL) stack provides monitoring, logging, and tracing for the devcontainer.

**Key features:**
- Container metrics collection
- Log aggregation
- Distributed tracing
- Grafana dashboards

See [services-otel.md](services-otel.md) for full documentation.

---

## Related Documentation

- [Services Dependencies](services-dependencies.md) - How services depend on each other
- [Services Monitoring Requirements](services-monitoring-requirements.md) - Container monitoring requirements
- [Creating Service Scripts](creating-service-scripts.md) - How to create new services
- [Architecture](architecture.md) - System architecture overview
