---
title: Claude Code
sidebar_position: 5
---

# Claude Code

Claude Code is Anthropic's terminal-based AI coding assistant with agentic capabilities. It can read, write, and execute code directly in your development environment.

## What Gets Installed

### Packages

| Package | Description |
|---------|-------------|
| `@anthropic-ai/claude-code` | Claude Code CLI tool (npm global) |
| `curl` | Required for API communication |

### Configuration

The installer sets up:
- Environment configuration in `.devcontainer.secrets/`
- Skills directory at `/workspace/.claude/skills`
- Bashrc configuration for environment loading

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-dev-ai-claudecode.sh
```

To uninstall:

```bash
.devcontainer/additions/install-dev-ai-claudecode.sh --uninstall
```

## Configuration

### API Key Setup

Claude Code requires an Anthropic API key. Create the environment file:

```bash
mkdir -p .devcontainer.secrets/env-vars
echo "ANTHROPIC_API_KEY=your-api-key-here" > .devcontainer.secrets/env-vars/anthropic.env
```

:::caution
The `.devcontainer.secrets/` directory is gitignored by default to protect your API keys. Never commit API keys to your repository.
:::

### Verify Installation

```bash
claude --version
```

## How to Use

### Starting Claude Code

```bash
claude
```

This opens an interactive session where you can:
- Ask questions about your codebase
- Request code changes
- Run commands
- Debug issues

### Common Commands

```bash
# Start interactive mode
claude

# Ask a specific question
claude "How does the authentication work in this project?"

# Request a code change
claude "Add input validation to the user registration form"
```

## Example Workflows

### Exploring a New Codebase

```bash
claude "Give me an overview of this project's architecture"
claude "What are the main entry points?"
claude "How is the database configured?"
```

### Implementing Features

```bash
claude "Add a new endpoint to get user preferences"
claude "Implement caching for the API responses"
claude "Add unit tests for the UserService class"
```

### Debugging

```bash
claude "Why is this test failing?"
claude "Find potential null pointer exceptions in this file"
claude "Explain this error message: [paste error]"
```

### Code Review

```bash
claude "Review this function for potential issues"
claude "Suggest improvements for error handling"
claude "Check for security vulnerabilities"
```

## Why Use Claude Code in a Devcontainer?

Running Claude Code inside a devcontainer provides several benefits:

1. **Isolation**: AI-generated code runs in a sandboxed environment
2. **Safety**: System files are protected from accidental modification
3. **Reproducibility**: Same environment for all team members
4. **Easy cleanup**: Delete container to reset if needed

## Skills Directory

Claude Code can use custom skills from `/workspace/.claude/skills`. Skills are reusable prompts and instructions that extend Claude's capabilities.

### Creating a Skill

Create a markdown file in `.claude/skills/`:

```markdown
# my-skill.md

This skill helps with [specific task].

## Instructions

1. First, do this
2. Then, do that
3. Finally, verify the result
```

## Troubleshooting

### Claude Command Not Found

Reload your shell:

```bash
source ~/.bashrc
```

Or check the installation path:

```bash
ls -la ~/.local/bin/claude
```

### API Key Not Working

1. Verify the API key is set:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. Check the environment file exists:
   ```bash
   cat .devcontainer.secrets/env-vars/anthropic.env
   ```

3. Reload environment:
   ```bash
   source ~/.bashrc
   ```

### Rate Limiting

If you hit rate limits, wait a moment and try again. Consider upgrading your API plan for higher limits.

## Best Practices

1. **Be Specific**: Clear, detailed prompts get better results
2. **Review Changes**: Always review AI-generated code before committing
3. **Use Version Control**: Commit frequently so you can revert if needed
4. **Iterate**: If the first result isn't perfect, refine your prompt
5. **Leverage Context**: Claude can read your files, so reference them by name

## Documentation

- [Claude Code Documentation](https://claude.ai/claude-code)
- [Anthropic API Documentation](https://docs.anthropic.com/)
