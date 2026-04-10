# Investigate: Kubeconfig Access Inside Devcontainer

> **IMPLEMENTATION RULES:** Before implementing this plan, read and follow:
> - [WORKFLOW.md](../../WORKFLOW.md) - The implementation process
> - [PLANS.md](../../PLANS.md) - Plan structure and best practices

## Status: Backlog

**Goal**: Give developers seamless access to their host's Kubernetes clusters from inside the devcontainer, without manual file copying.

**Priority**: Medium — currently requires manual steps that most developers don't understand

**Last Updated**: 2026-04-07

---

## Problem

Developers need `kubectl` to work inside the devcontainer with their host's Kubernetes clusters (Rancher Desktop, Docker Desktop K8s, remote clusters). The kubeconfig file lives on the host at `~/.kube/config`, but the container can't access it because:

1. The container only mounts the workspace directory (`/workspace`), not the user's home directory
2. `${localEnv:KUBECONFIG}` in `remoteEnv` gives the host PATH (e.g., `/Users/terje/.kube/config`), but that path doesn't exist inside the container
3. The kubeconfig contains `server:` URLs like `https://127.0.0.1:6443` that need rewriting to `https://host.docker.internal:6443` for the container to reach the host's K8s API

## Current Solution

`install-tool-kubernetes.sh` (in `.devcontainer/additions/`) takes a manual approach:

1. Creates `.devcontainer.secrets/.kube/` directory
2. Symlinks `~/.kube` → `.devcontainer.secrets/.kube/` inside the container
3. Generates helper scripts the user must run **on the host**:
   - `copy-kubeconfig-mac.sh` — copies `~/.kube/config`, rewrites `server:` URLs
   - `copy-kubeconfig-win.ps1` — same for Windows/PowerShell
4. User runs the helper script from the host terminal
5. Kubeconfig lands in `.devcontainer.secrets/.kube/config` (persists across rebuilds)

**User experience:** Bad. The developer must:
- Know that kubeconfig needs copying
- Open a separate host terminal
- Run the correct script for their OS
- Re-run it when their kubeconfig changes (new cluster, rotated certs)

---

## What We Now Have That Changes Things

Since v1.7.14, the devcontainer has:
- **`docker-outside-of-docker` feature** — Docker CLI + host socket access
- **`initializeCommand`** — runs on the host before container starts
- **`DEV_HOST_HOME`** — the host user's home directory path

These open new approaches that weren't possible before.

---

## Options

### Option A: initializeCommand copies kubeconfig

```json
"initializeCommand": "mkdir -p .devcontainer.secrets/.kube && cp ~/.kube/config .devcontainer.secrets/.kube/config 2>/dev/null && sed -i.bak 's|127.0.0.1|host.docker.internal|g' .devcontainer.secrets/.kube/config 2>/dev/null || true"
```

Pro: Automatic, runs before every container start, no user action needed.
Con: `initializeCommand` is a single line in the JSON — complex commands get ugly. Also `sed -i` behaves differently on Mac vs Linux (Mac needs `-i ''`, Linux needs `-i`).

### Option B: initializeCommand calls a script

```json
"initializeCommand": "bash .devcontainer/scripts/copy-kubeconfig.sh 2>/dev/null || true"
```

The script handles platform differences, URL rewriting, error handling. Lives in the repo, runs on the host.

Pro: Clean, maintainable, handles edge cases.
Con: Adds a script file to every project. But we already have `.devcontainer/` as DCT-managed.

### Option C: Mount ~/.kube as a volume

```json
"mounts": [
    "source=${localEnv:HOME}/.kube,target=/home/vscode/.kube,type=bind,readonly"
]
```

Pro: Always up to date, no copying, no helper scripts.
Con: 
- `server: 127.0.0.1` in kubeconfig won't work (needs `host.docker.internal`)
- Read-only means kubectl can't update the kubeconfig (e.g., `kubectl config use-context`)
- On Rancher Desktop macOS, host paths in mounts don't work (the Docker daemon runs in a VM — this is the exact problem that led to `docker-outside-of-docker`)
- Breaks the "one standard devcontainer.json" principle (not all projects need kubectl)

### Option D: postStartCommand copies and rewrites

```json
"postStartCommand": "bash /opt/devcontainer-toolbox/additions/scripts/setup-kubeconfig.sh 2>/dev/null || true"
```

The script runs inside the container after VS Code connects. It has `DEV_HOST_HOME` available. But it can't read the host filesystem — it's inside the container.

Unless... it uses Docker to read from the host:

```bash
docker run --rm -v "${DEV_HOST_HOME}/.kube:/host-kube:ro" alpine cat /host-kube/config > ~/.kube/config
```

Pro: Runs inside container, has access to host via Docker.
Con: Spawns a temporary container on every start. The mount path issue on Rancher Desktop applies here too.

### Option E: initializeCommand + KUBECONFIG env var (recommended)

Combine `initializeCommand` (runs on host, copies file) with the `KUBECONFIG` env var pointing to the copied location:

1. `initializeCommand` script copies `~/.kube/config` → `.devcontainer.secrets/.kube/config` and rewrites URLs
2. `remoteEnv` sets `KUBECONFIG=/workspace/.devcontainer.secrets/.kube/config`
3. `kubectl` inside the container uses the copied config automatically

```json
"remoteEnv": {
    "KUBECONFIG": "/workspace/.devcontainer.secrets/.kube/config"
}
```

Pro: Automatic, no user action, kubeconfig always fresh on container start.
Con: Need a cross-platform `initializeCommand` script that handles Mac `sed` vs Linux `sed`.

### Option F: `uis-exec` passthrough — proxy kubectl through `uis-provision-host`

**Fundamentally different approach:** don't move the kubeconfig at all. Don't install kubectl in DCT. Instead, proxy `kubectl` (and any other binary in the UIS container) through `docker exec uis-provision-host ...` via thin shims on DCT's PATH.

This is the same multi-call pattern busybox uses, and the same shim pattern DCT v1.7.34+ already uses for the `uis` CLI itself.

**Discovered 2026-04-10** during the v1.7.36 E2E test of `python-basic-webserver-database`, when `dev-template configure`'s "next steps" recommended `kubectl get secret delete-test-db -n delete-test` and the user hit `bash: kubectl: command not found`. DCT doesn't ship kubectl, but uis-provision-host does — and it's the kubectl already configured for the cluster the user is working with.

#### Design

**One generic script: `.devcontainer/manage/uis-exec.sh`**

Looks at `$0` (the name it was called as) and decides what to do:

| Invoked as | What it runs |
|---|---|
| `uis-exec kubectl get pods` | `docker exec uis-provision-host kubectl get pods` |
| `kubectl get pods` (via symlink) | `docker exec uis-provision-host kubectl get pods` |
| `helm list` (via symlink) | `docker exec uis-provision-host helm list` |
| `uis-exec bash` | `docker exec -it uis-provision-host bash` (interactive shell into UIS container) |
| `uis-exec ls /opt` | `docker exec uis-provision-host ls /opt` |
| `uis-exec` (no args) | Print usage |

```bash
#!/bin/bash
# uis-exec — execute commands inside the uis-provision-host container.
#
# Multi-call: behaves differently based on $0:
#   /usr/local/bin/uis-exec kubectl get pods   → docker exec uis-provision-host kubectl get pods
#   /usr/local/bin/kubectl get pods            → same (via symlink)
#   /usr/local/bin/helm list                   → same (via symlink)
set -e

SCRIPT_REAL_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_REAL_PATH")"
source "$SCRIPT_DIR/lib/uis-bridge.sh"

INVOKED_AS="$(basename "$0")"
case "$INVOKED_AS" in
    uis-exec)
        if [ $# -eq 0 ]; then
            cat <<'EOF'
uis-exec — run any command inside the uis-provision-host container

Usage: uis-exec <command> [args]

Examples:
  uis-exec kubectl get pods
  uis-exec helm list
  uis-exec bash               (interactive shell)
EOF
            exit 0
        fi
        CMD=("$@")
        ;;
    *)
        CMD=("$INVOKED_AS" "$@")
        ;;
esac

if ! uis_bridge_check 2>/dev/null; then
    echo "❌ uis-provision-host is not running" >&2
    exit 1
fi

if [ -t 0 ] && [ -t 1 ]; then
    docker exec -it "$UIS_CONTAINER" "${CMD[@]}"
elif [ ! -t 0 ]; then
    docker exec -i "$UIS_CONTAINER" "${CMD[@]}"
else
    docker exec "$UIS_CONTAINER" "${CMD[@]}"
fi
```

Plus symlinks in `image/Dockerfile`:

```dockerfile
sudo ln -sf /opt/devcontainer-toolbox/manage/uis-exec.sh /usr/local/bin/uis-exec && \
sudo ln -sf /opt/devcontainer-toolbox/manage/uis-exec.sh /usr/local/bin/kubectl && \
sudo ln -sf /opt/devcontainer-toolbox/manage/uis-exec.sh /usr/local/bin/helm && \
```

Adding a new shim later (k9s, kubectx, etc.) is one symlink line — zero new code per addition.

#### Pro / Con

**Pro:**
- **Zero install** in DCT — no kubectl, helm, or any K8s binary in the image
- **Single source of truth** — the kubectl that DCT uses is the same kubectl uis-provision-host uses, so version drift is impossible
- **No kubeconfig copying** — uis-provision-host already has the right config for the cluster it manages
- **No platform issues** — no Mac vs Linux sed, no PowerShell, no path rewriting, no `127.0.0.1` → `host.docker.internal` rewrites
- **Same proven pattern** as the existing `uis` shim from v1.7.34 (which works flawlessly)
- **Minimal maintenance** — one script handles all current and future commands; new commands are just symlinks
- **Natural syntax** — users type `kubectl get pods` like they expect, no awareness of proxying

**Con:**
- **Only works for clusters managed by uis-provision-host.** A user who wants kubectl against their personal Rancher Desktop cluster (separate from UIS) is not helped by this. Options A-E remain relevant for that use case.
- **uis-provision-host must be running.** If it's down, kubectl is unavailable. Same constraint as the `uis` shim — and if the user is working on a UIS-deployed app, uis-provision-host should be up anyway.
- **Three subtleties from the docker exec model** that need documenting:
  1. **Pipes run on the DCT side, not inside the container.** `kubectl get pods | grep mypod` works (kubectl in container, grep in DCT). Usually what you want.
  2. **File paths in args are interpreted inside the container.** `kubectl apply -f /workspace/foo.yaml` ❌ fails (no `/workspace` inside uis-provision-host). Workaround: pipe via stdin — `kubectl apply -f - < /workspace/foo.yaml` ✅ works.
  3. **DCT-side env vars don't propagate.** `KUBECONFIG=/foo kubectl get pods` won't change which config is used inside the container. Usually what you want — the container has the right config.

#### How Option F relates to Options A-E

These aren't mutually exclusive. They serve different audiences:

| User scenario | Best option |
|---|---|
| Working on a UIS-deployed app, only needs to talk to the cluster UIS manages | **Option F** (proxy through uis-provision-host) |
| Working on a personal cluster (Rancher Desktop, EKS, etc.) unrelated to UIS | **Option E** (copy host kubeconfig + URL rewrite) |
| Both — e.g., dev on UIS cluster, occasionally check personal cluster | **Both** — Option F gives `kubectl` for UIS, user can install a separate `kubectl-personal` tool for personal clusters |

If we ship Option F, it serves the **majority** case (UIS-managed clusters) without any of the kubeconfig complexity. Option E (or another A-E variant) can still be added later for the personal-cluster case.

#### Recommendation

**Ship Option F first.** It solves the immediate problem (the kubectl recommendation in v1.7.36's `dev-template configure` output doesn't work on a fresh DCT) with zero install footprint and zero platform shenanigans. It's the pattern we already validated with the `uis` shim. Cost: ~50 lines of shell + 3 Dockerfile lines.

Then revisit Options A-E later if/when users with personal clusters complain.

---

## Cross-Platform sed Challenge

The kubeconfig URL rewrite (`127.0.0.1` → `host.docker.internal`) uses `sed -i`. But Mac and Linux have incompatible `-i` syntax:

- **Mac:** `sed -i '' 's|...|...|g' file` (empty string after `-i`)
- **Linux:** `sed -i 's|...|...|g' file` (no argument after `-i`)

Solutions:
- Use `perl -pi -e` instead (works the same on both)
- Use a temp file: `sed 's|...|...|g' file > file.tmp && mv file.tmp file`
- Detect platform in the script

---

## What Needs Rewriting in Kubeconfig

| Original | Rewritten | Why |
|----------|-----------|-----|
| `server: https://127.0.0.1:6443` | `server: https://host.docker.internal:6443` | Container can't reach host's localhost |
| `server: https://localhost:6443` | `server: https://host.docker.internal:6443` | Same reason |
| `certificate-authority: /Users/...` | May need adjustment | Host paths don't exist in container |

---

## Questions to Answer

1. Does `initializeCommand` run on Windows PowerShell or WSL2 bash? (Affects which script format to use)
2. On Rancher Desktop macOS, does `host.docker.internal` resolve to the host? (It should via the docker-outside-of-docker feature)
3. Should we add `KUBECONFIG` to `remoteEnv` for ALL users, or only when kubernetes tools are installed?
4. What about users with multiple kubeconfig files (`KUBECONFIG=~/.kube/config:~/.kube/other`)?
5. Should the existing `copy-kubeconfig-mac.sh` / `copy-kubeconfig-win.ps1` helper scripts be replaced or kept as fallback?

---

## Existing Code Reference

| File | What it does |
|------|-------------|
| `.devcontainer/additions/install-tool-kubernetes.sh` | Installs kubectl, k9s, helm. Creates `.devcontainer.secrets/.kube/` and helper scripts. |
| `.devcontainer/additions/install-tool-kubernetes.sh:260` | `setup_kubeconfig()` — symlinks `~/.kube` → `.devcontainer.secrets/.kube/` |
| `.devcontainer/additions/install-tool-kubernetes.sh:284` | `create_kubeconfig_helper_scripts()` — generates Mac/Windows copy scripts |
| `.devcontainer/additions/lib/install-common.sh:636` | Commented-out `KUBECONFIG` env var setup (was planned but never activated) |

---

## Next Steps

- [ ] Decide: Option E (initializeCommand + KUBECONFIG env) or another approach
- [ ] Create cross-platform `copy-kubeconfig.sh` script (handles Mac/Linux sed differences)
- [ ] Test on Mac with Rancher Desktop (is `host.docker.internal` reachable from container?)
- [ ] Test on Windows
- [ ] Decide if KUBECONFIG goes in template for all users or only when kubernetes is installed
- [ ] Update `install-tool-kubernetes.sh` to use the new approach instead of manual helper scripts
