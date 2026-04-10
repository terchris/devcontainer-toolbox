#!/bin/bash
# File: .devcontainer/manage/uis-exec.sh
# Description: Multi-call passthrough — execute commands inside the
#              uis-provision-host container without installing them in DCT.
#
# Multi-call: behaves differently based on $0:
#   /usr/local/bin/uis-exec kubectl get pods   → docker exec uis-provision-host kubectl get pods
#   /usr/local/bin/kubectl get pods            → same (via symlink)
#   /usr/local/bin/helm list                   → same (via symlink)
#   /usr/local/bin/k9s                         → same (via symlink)
#
# To add a new shim, just symlink another name in image/Dockerfile.
# No code changes needed in this script.
#
# Limitations (inherent to the docker exec model):
#   1. Pipes run on the DCT side, not inside the container.
#      `kubectl get pods | grep mypod` works (kubectl in container, grep in DCT).
#   2. File paths in args are interpreted INSIDE the container.
#      `kubectl apply -f /workspace/foo.yaml` will fail.
#      Workaround: pipe via stdin: `kubectl apply -f - < /workspace/foo.yaml`
#   3. DCT-side environment variables don't propagate.
#      `KUBECONFIG=/foo kubectl get pods` won't change which config is used.
#------------------------------------------------------------------------------

set -e

SCRIPT_REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_REAL_PATH")"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/uis-bridge.sh"

INVOKED_AS="$(basename "$0")"

# Determine the command to run inside the container
case "$INVOKED_AS" in
    uis-exec)
        # Generic mode: first arg is the command
        if [ $# -eq 0 ]; then
            cat <<'EOF'
uis-exec — run any command inside the uis-provision-host container

Usage: uis-exec <command> [args]

Examples:
  uis-exec kubectl get pods
  uis-exec helm list
  uis-exec ls /opt
  uis-exec bash                        (interactive shell inside the container)
  uis-exec env                         (show container env vars)

Common commands also available as direct shims (no need for `uis-exec` prefix):
  kubectl get pods                     → uis-exec kubectl get pods
  helm list                            → uis-exec helm list
  k9s                                  → uis-exec k9s

Limitations (inherent to docker exec):
  • Pipes run on DCT side, not inside the container.
  • File paths in args are interpreted INSIDE the container.
    Workaround: pipe via stdin (e.g. `kubectl apply -f - < manifest.yaml`).
  • DCT-side env vars don't propagate.
EOF
            exit 0
        fi
        CMD=("$@")
        ;;
    *)
        # Named-shim mode: $0 IS the command
        CMD=("$INVOKED_AS" "$@")
        ;;
esac

# Verify uis-provision-host is running
if ! uis_bridge_check 2>/dev/null; then
    echo "❌ uis-provision-host container is not running" >&2
    echo "" >&2
    echo "   This shim ($INVOKED_AS) proxies commands into uis-provision-host" >&2
    echo "   via 'docker exec'. The container must be running." >&2
    echo "" >&2
    echo "   Start it from the urbalurba-infrastructure repo:" >&2
    echo "     cd <uis-directory> && ./uis start" >&2
    exit 1
fi

# Route based on TTY/stdin (matches the uis shim's pattern)
if [ -t 0 ] && [ -t 1 ]; then
    # Interactive: TTY + stdin both
    docker exec -it "$UIS_CONTAINER" "${CMD[@]}"
elif [ ! -t 0 ]; then
    # Stdin is piped (e.g., `cat foo.yaml | kubectl apply -f -`)
    docker exec -i "$UIS_CONTAINER" "${CMD[@]}"
else
    # No TTY, no piped stdin (e.g., output redirected to a file)
    docker exec "$UIS_CONTAINER" "${CMD[@]}"
fi
