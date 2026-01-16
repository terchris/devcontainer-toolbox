# Investigate: Extend Mechanism for Port Forwarding

## Status: Backlog

**Goal:** Enable projects to define forwarded ports via the `.devcontainer.extend/` mechanism without modifying the generic `devcontainer.json`.

**Last Updated:** 2026-01-16

---

## Problem

The devcontainer-toolbox uses a generic `devcontainer.json` that works for all projects. However, some projects need specific ports forwarded for web development (e.g., port 3000 for Docusaurus, port 8080 for other frameworks).

Currently, VS Code only auto-forwards ports when servers are started from its integrated terminal. When Claude (or other tools) start servers via `docker exec`, the ports aren't forwarded because there's no static `forwardPorts` configuration.

The Hugo devcontainer at `sovereignsky-site` solves this with:
```json
"forwardPorts": [1313]
```

But adding specific ports to the generic devcontainer.json defeats its purpose.

---

## Questions to Answer

1. **Can devcontainer.json be extended/merged?**
   - Does the devcontainer spec support multiple config files?
   - Can we use a `.devcontainer/devcontainer.local.json` that merges with the main config?

2. **Can forwardPorts be set dynamically?**
   - Can postCreateCommand or postStartCommand configure port forwarding?
   - Is there a VS Code API or CLI to add forwarded ports at runtime?

3. **What's the best UX for users?**
   - A `ports.conf` file in `.devcontainer.extend/`?
   - A JSON file that gets merged?
   - Environment variables?

---

## Research Areas

### Devcontainer Spec

- Check [devcontainer.json reference](https://containers.dev/implementors/json_reference/) for merge/extend capabilities
- Look for `localEnv` or variable substitution options for forwardPorts
- Check if multiple devcontainer.json files can coexist

### VS Code Port Forwarding

- How does VS Code detect ports to forward?
- Can we programmatically trigger port forwarding?
- Is there a `devcontainer.json` override mechanism?

### Alternative Approaches

- Docker Compose with port mappings
- Using `runArgs` with `-p` flag dynamically
- Post-start script that uses VS Code CLI

---

## Potential Solutions

### Option A: ports.conf file

```
# .devcontainer.extend/ports.conf
3000
8080
1313
```

**Pros:** Simple, consistent with existing extend pattern
**Cons:** Needs build-time processing to inject into devcontainer.json

### Option B: Local override file

```json
// .devcontainer.extend/devcontainer.extend.json
{
  "forwardPorts": [3000, 8080]
}
```

**Pros:** Standard JSON, easy to understand
**Cons:** Needs merge logic, may not be supported by devcontainer spec

### Option C: Dynamic port forwarding via script

```bash
# postStartCommand adds ports dynamically
# Needs research on how to trigger VS Code port forwarding
```

**Pros:** No config file changes needed
**Cons:** May not be possible, depends on VS Code internals

### Option D: Docker run args

Modify the container startup to include `-p 3000:3000` via runArgs, but this requires knowing ports at build time.

---

## Success Criteria

1. Users can specify ports in `.devcontainer.extend/` folder
2. Ports are forwarded automatically when container starts
3. Works with `docker exec` (not just VS Code terminal)
4. No changes to generic `devcontainer.json` required
5. Simple, documented pattern for users

---

## Next Steps

1. Research devcontainer spec for merge/extend capabilities
2. Test if `runArgs` with `-p` can be dynamically configured
3. Check VS Code extension API for port forwarding
4. Prototype simplest viable solution
5. Document findings and recommend approach

---

## References

- [Devcontainer JSON Reference](https://containers.dev/implementors/json_reference/)
- [VS Code Port Forwarding Docs](https://code.visualstudio.com/docs/remote/ssh#_forwarding-a-port-creating-ssh-tunnel)
- [Devcontainer Features](https://containers.dev/implementors/features/)
- Hugo devcontainer example: `/Users/terje.christensen/learn/projects-2025/sovereignsky-site/.devcontainer/devcontainer.json`
