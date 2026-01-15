# Container Monitoring Requirements

This document describes the requirements for Docker containers to be fully monitored by the devcontainer observability stack.

## Overview

The devcontainer uses the OpenTelemetry `docker_stats` receiver to collect metrics from Docker containers. This receiver queries the Docker API via `/var/run/docker.sock` to get container statistics.

## Metrics Available

| Metric Type | Available | Notes |
|-------------|-----------|-------|
| **CPU** | Always | Tracked via cgroups, works with any network mode |
| **Memory** | Always | Tracked via cgroups, works with any network mode |
| **Network I/O** | Conditional | Requires bridge networking (NOT host networking) |

## Network Mode Requirements

### For Full Monitoring (CPU + Memory + Network)

Use **bridge networking** (the default):

```yaml
# docker-compose.yml
services:
  my-app:
    image: my-image
    # network_mode is NOT specified (defaults to bridge)
    # OR explicitly:
    networks:
      - my-network

networks:
  my-network:
```

Or with `docker run`:
```bash
docker run my-image  # defaults to bridge
docker run --network=bridge my-image
docker run --network=my-custom-network my-image
```

### Partial Monitoring Only (CPU + Memory, NO Network)

Containers with `network_mode: "host"` will NOT have network metrics:

```yaml
# docker-compose.yml
services:
  provision-host:
    image: my-image
    network_mode: "host"  # <-- No network metrics available
```

**Why?** Host networking shares the host's network namespace, so Docker cannot track network I/O separately for the container. The container's network traffic is included in the VM-level metrics instead.

## Current Container Status

| Container | Network Mode | CPU | Memory | Network |
|-----------|-------------|-----|--------|---------|
| `devcontainer-toolbox` | bridge | Yes | Yes | Yes |
| `provision-host` | host | Yes | Yes | **No** |

## When to Use Host Networking

Use `network_mode: "host"` only when necessary:
- VPN clients (Tailscale, WireGuard) that need to manage host network interfaces
- Services requiring `NET_ADMIN` capability for tunnel creation
- Containers that need direct access to host network interfaces

## Prometheus Metrics

The following Prometheus metrics are collected by the docker_stats receiver:

**CPU metrics:**
- `container_cpu_utilization_ratio` - CPU utilization (0-1 scale)

**Memory metrics:**
- `container_memory_usage_bytes` - Memory usage in bytes

**Network metrics (bridge only):**
- `container_network_receive_bytes_total` - Network bytes received
- `container_network_transmit_bytes_total` - Network bytes transmitted

## Grafana Dashboard

The "Rancher Desktop VM" dashboard in Grafana shows:
- **VM Resource Usage** - VM-level CPU, memory, network (includes all traffic)
- **Docker Containers (VM)** - Per-container CPU, memory, and network (bridge containers only)

## Troubleshooting

### Container not showing network metrics

1. Check network mode:
   ```bash
   docker inspect <container> --format '{{.HostConfig.NetworkMode}}'
   ```

2. If it returns `host`, network metrics are not available

### Verify metrics in Prometheus

```bash
# Check which containers have network metrics
curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=container_network_receive_bytes_total{service_name="devcontainer-monitor"}' \
  | jq -r '.data.result[] | .metric.container_name'
```

## References

- [Docker Stats Receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/dockerstatsreceiver)
- [Docker Network Modes](https://docs.docker.com/network/)
