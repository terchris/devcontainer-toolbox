# Research: AI Security Documentation Enrichment

**Status:** For Review
**Created:** 2025-01-17
**Purpose:** Enrich existing AI development docs with external best practices

---

## Sources Reviewed

1. [Isolating AI Agents with DevContainer](https://dev.to/siddhantkcode/isolating-ai-agents-with-devcontainer-a-secure-and-scalable-approach-4hi4)
2. [How Dev Containers Protect Your Machine from AI Coding Agents](https://zenvanriel.nl/ai-engineer-blog/dev-containers-ai-agent-security/)
3. [How to Safely Run AI Agents Like Cursor and Claude Code Inside a DevContainer](https://codewithandrea.com/articles/run-ai-agents-inside-devcontainer/)
4. [Docker Sandboxes: A New Approach for Coding Agent Safety](https://www.docker.com/blog/docker-sandboxes-a-new-approach-for-coding-agent-safety/)

---

## Aligns with Our Practices (Can Add)

### Real-World Security Incidents

Add these examples to make the "cage" concept more concrete:

- A developer's home directory was wiped by an AI agent running a cleanup script
- AI agents executing `rm -rf` commands without proper boundaries
- Agents accessing SSH keys and pushing to production
- Resource exhaustion from runaway AI processes

### Specific Threats Addressed by Containers

- **Prompt injection attacks** - Cannot reach host system
- **Supply chain attacks** - Isolated within container
- **Credential exposure** - No access to ~/.ssh, ~/.aws, etc.
- **Resource exhaustion** - Container limits prevent system lockup

### Best Practices to Add

1. **Use non-root user in container**
   - Create `vscode` user with specific UID/GID
   - Set `remoteUser` in devcontainer.json

2. **Only mount project directory**
   - NEVER mount home directory or broad paths
   - Explicit volume mounts only

3. **Use read-only SSH deploy keys**
   - Project-specific keys
   - Prevents accidental force pushes

4. **Project-specific cloud credentials**
   - Isolated IAM users with minimal permissions
   - No production access from dev containers

5. **The `--dangerously-skip-permissions` flag**
   - This flag enables autonomous AI operation
   - ONLY safe inside containers
   - Never use on host machine

### Limitations to Document

- iOS/Android emulators don't work in containers
- Visual UI testing needs host machine
- Breakpoint debugging may need host for some frameworks
- Containers aren't a perfect security boundary (VS Code extensions can create backdoors)

---

## Alternative Approaches (List Separately)

### Docker Sandboxes (New)

Docker's new feature specifically for AI agents:
- Runs in microVMs for extra isolation (beyond regular containers)
- Purpose-built for coding agent safety
- Stricter default policies than standard containers
- Still experimental

### Headless CLI Mode

Run AI agents without IDE:
```bash
npm install -g @devcontainers/cli
devcontainer exec --workspace-folder . claude --dangerously-skip-permissions
```
- Useful for VPS deployments
- CI/CD pipeline integration
- Remote agent execution

### Dual-Environment Workflow

Some developers maintain two IDE windows:
- **Container window:** AI coding, refactoring, tests
- **Host window:** UI testing, visual debugging, emulators

This maximizes productivity while keeping AI contained.

---

## Suggested Documentation Changes

### Option A: Add to existing index.md

Add these sections:
- "Real-World Risks" (after "The Cage" section)
- "Security Best Practices" (new section)
- "Limitations" (new section)
- "Alternative Approaches" (new section)

### Option B: Create new page

Create `security-best-practices.md` with:
- Detailed security configuration
- Best practices checklist
- Alternative approaches
- Links to external resources

### Option C: Both

- Keep index.md focused on the concept
- Create detailed security page for those who want more

---

## Decision Needed

- [ ] Review this research
- [ ] Decide which enrichments to add
- [ ] Choose documentation structure (A, B, or C)
- [ ] Implement changes
