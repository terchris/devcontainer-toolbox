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
