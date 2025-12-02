#!/bin/bash
# File: /workspace/.devcontainer/additions/otel/scripts/metrics-devcontainer.sh
#
# Purpose: Collect container-specific metrics from cgroups
#          These are ACTUAL container usage metrics, not host metrics
#
# Output: Prometheus exposition format
# Called by: OpenTelemetry Collector exec receiver (every 10 seconds)
#
# Metrics collected:
#   - container_memory_current_bytes: Current memory usage
#   - container_memory_limit_bytes: Memory limit (if set)
#   - container_cpu_usage_seconds_total: Total CPU time used
#   - container_cpu_user_seconds_total: User-mode CPU time
#   - container_cpu_system_seconds_total: System-mode CPU time

set -e

# === MEMORY METRICS ===
if [ -f /sys/fs/cgroup/memory.current ]; then
  MEM_CURRENT=$(cat /sys/fs/cgroup/memory.current)
  echo "# HELP container_memory_current_bytes Current memory usage in bytes"
  echo "# TYPE container_memory_current_bytes gauge"
  echo "container_memory_current_bytes $MEM_CURRENT"
fi

if [ -f /sys/fs/cgroup/memory.max ]; then
  MEM_MAX=$(cat /sys/fs/cgroup/memory.max)
  # Only output if it's not "max" (unlimited)
  if [ "$MEM_MAX" != "max" ]; then
    echo "# HELP container_memory_limit_bytes Memory limit in bytes"
    echo "# TYPE container_memory_limit_bytes gauge"
    echo "container_memory_limit_bytes $MEM_MAX"
  fi
fi

# === CPU METRICS ===
if [ -f /sys/fs/cgroup/cpu.stat ]; then
  # Extract usage_usec (total CPU time in microseconds)
  CPU_USAGE=$(grep "^usage_usec " /sys/fs/cgroup/cpu.stat | awk '{print $2}')
  if [ -n "$CPU_USAGE" ]; then
    # Convert microseconds to seconds using awk (no bc dependency)
    CPU_SECONDS=$(awk "BEGIN {printf \"%.6f\", $CPU_USAGE / 1000000}")
    echo "# HELP container_cpu_usage_seconds_total Total CPU time used by container"
    echo "# TYPE container_cpu_usage_seconds_total counter"
    echo "container_cpu_usage_seconds_total $CPU_SECONDS"
  fi

  # Extract user_usec (user-mode CPU time)
  CPU_USER=$(grep "^user_usec " /sys/fs/cgroup/cpu.stat | awk '{print $2}')
  if [ -n "$CPU_USER" ]; then
    CPU_USER_SECONDS=$(awk "BEGIN {printf \"%.6f\", $CPU_USER / 1000000}")
    echo "# HELP container_cpu_user_seconds_total User-mode CPU time"
    echo "# TYPE container_cpu_user_seconds_total counter"
    echo "container_cpu_user_seconds_total $CPU_USER_SECONDS"
  fi

  # Extract system_usec (system-mode CPU time)
  CPU_SYSTEM=$(grep "^system_usec " /sys/fs/cgroup/cpu.stat | awk '{print $2}')
  if [ -n "$CPU_SYSTEM" ]; then
    CPU_SYSTEM_SECONDS=$(awk "BEGIN {printf \"%.6f\", $CPU_SYSTEM / 1000000}")
    echo "# HELP container_cpu_system_seconds_total System-mode CPU time"
    echo "# TYPE container_cpu_system_seconds_total counter"
    echo "container_cpu_system_seconds_total $CPU_SYSTEM_SECONDS"
  fi
fi

# === CONTAINER UPTIME ===
# Container uptime is the elapsed time since PID 1 (container init) started
if [ -f /proc/1/stat ]; then
  # Get elapsed time in seconds for PID 1
  UPTIME_SECONDS=$(ps -p 1 -o etimes= 2>/dev/null | tr -d ' ')
  if [ -n "$UPTIME_SECONDS" ]; then
    echo "# HELP container_uptime_seconds Container uptime in seconds (time since PID 1 started)"
    echo "# TYPE container_uptime_seconds gauge"
    echo "container_uptime_seconds $UPTIME_SECONDS"
  fi
fi

# === I/O METRICS (optional, if needed later) ===
# Commented out for now - uncomment if you need disk I/O metrics
#
# if [ -f /sys/fs/cgroup/io.stat ]; then
#   # Parse io.stat for read/write bytes
#   # Format: "major:minor rbytes=X wbytes=Y ..."
#   # This would need more complex parsing
#   :
# fi

# === SUCCESS ===
exit 0
