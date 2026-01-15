# Infrastructure Documentation

Documentation for the built-in infrastructure services in devcontainer-toolbox.

---

## Services

| Service | Description | Documentation |
|---------|-------------|---------------|
| **Nginx** | Reverse proxy for routing to local services | [infrastructure-nginx.md](infrastructure-nginx.md) |
| **OTEL** | OpenTelemetry monitoring and observability | [infrastructure-otel.md](infrastructure-otel.md) |

---

## Nginx Reverse Proxy

The nginx service provides a reverse proxy that routes requests to services running in the devcontainer. It allows accessing multiple services through a single entry point.

**Key features:**
- Automatic configuration generation
- Route multiple services on different paths
- SSL/TLS support
- WebSocket support

See [infrastructure-nginx.md](infrastructure-nginx.md) for full documentation.

---

## OTEL Monitoring

The OpenTelemetry (OTEL) stack provides monitoring, logging, and tracing for the devcontainer.

**Key features:**
- Container metrics collection
- Log aggregation
- Distributed tracing
- Grafana dashboards

See [infrastructure-otel.md](infrastructure-otel.md) for full documentation.

---

## Related Documentation

- [Service Dependencies](service-dependencies.md) - How services depend on each other
- [Creating Service Scripts](creating-service-scripts.md) - How to create new services
- [Architecture](architecture.md) - System architecture overview
