#!/bin/bash
# File: .devcontainer/manage/uis.sh
# Symlinked to: /usr/local/bin/uis (so users can type bare `uis ...`)
#
# Purpose:
#   Thin wrapper around the UIS CLI that lives inside the uis-provision-host
#   container. Routes commands via docker exec with the right TTY/stdin mode.
#
# Why this exists:
#   The UIS CLI is not installed in DCT — it lives inside the
#   uis-provision-host container managed by urbalurba-infrastructure. Without
#   this shim, users would have to type:
#     docker exec uis-provision-host uis configure postgresql --app myapp ...
#   With this shim:
#     uis configure postgresql --app myapp ...
#
# Modes:
#   Interactive TTY (terminal): docker exec -it    (uis_bridge_run_tty)
#   Piped stdin (cat foo | uis): docker exec -i    (uis_bridge_run_stdin)
#   Non-TTY no stdin (script):   docker exec       (uis_bridge_run)
#   help/--help/-h/no args:      bypass container check, show local help
#
# See: helpers-no/dev-templates → INVESTIGATE-improve-template-docs-with-services.md
#      (Phase 1, item 1.8)

set -e

# Resolve script dir from symlink target
SCRIPT_REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_REAL_PATH")"

# Source the bridge library
# shellcheck source=lib/uis-bridge.sh
source "$SCRIPT_DIR/lib/uis-bridge.sh"

# Fast path: help and no-args output is local-only.
# Don't require the UIS container to be running for help.
case "${1:-}" in
    ""|help|--help|-h)
        # If UIS container is up, forward to real `uis help` for accurate info
        if uis_bridge_check 2>/dev/null; then
            uis_bridge_run_tty "$@"
            exit $?
        fi
        # Container is not running — show local help
        cat <<'EOF'
uis — UIS CLI (proxied from DCT via docker-outside-of-docker)

Usage: uis <command> [args]

This is a DCT shim that forwards commands to the uis-provision-host
container. UIS provides commands for managing data services, deployments,
templates, and more.

Common commands (require uis-provision-host running):
  uis status                    Show status of all UIS components
  uis status <service>          Show status of one service
  uis deploy <service>          Deploy a service (postgresql, redis, ...)
  uis configure <service>       Configure a service for an app
  uis connect <service> [db]    Connect to a service (psql, redis-cli, ...)
  uis template list             List available UIS stack templates
  uis template install <id>     Install a UIS stack template
  uis expose <service>          Expose a service via port-forward

⚠️  uis-provision-host container is not running.
    Start it from the urbalurba-infrastructure repo.
EOF
        exit 0
        ;;
    *)
        # All other commands require the UIS container.
        uis_bridge_check || exit 1

        # Pick the right exec mode based on stdin/stdout state.
        if [ -t 0 ] && [ -t 1 ]; then
            # Interactive: terminal in and out — allocate TTY
            uis_bridge_run_tty "$@"
        elif [ ! -t 0 ]; then
            # Stdin is piped (e.g., echo SQL | uis configure --init-file -)
            uis_bridge_run_stdin "$@"
        else
            # Non-TTY no stdin (e.g., uis status > out.txt)
            uis_bridge_run "$@"
        fi
        ;;
esac
