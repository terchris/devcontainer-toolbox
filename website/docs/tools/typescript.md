---
title: TypeScript Development
sidebar_position: 2
---

# TypeScript Development

The TypeScript development tools add TypeScript compiler, development utilities, and VS Code extensions for modern TypeScript/JavaScript development.

## What Gets Installed

### Node.js Packages (Global)

| Package | Description |
|---------|-------------|
| `typescript` | TypeScript compiler |
| `tsx` | TypeScript execute - run TypeScript directly |
| `@types/node` | TypeScript definitions for Node.js |
| `ts-node` | TypeScript execution environment for Node.js |

:::note
Node.js and npm are already included in the base devcontainer image.
:::

### VS Code Extensions

| Extension | Description |
|-----------|-------------|
| Prettier (esbenp.prettier-vscode) | Code formatter for consistent code style |
| ESLint (dbaeumer.vscode-eslint) | JavaScript and TypeScript linting |

:::tip
TypeScript language support is built into VS Code - no extension needed!
:::

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-dev-typescript.sh
```

To uninstall:

```bash
.devcontainer/additions/install-dev-typescript.sh --uninstall
```

## How to Use

### Initialize a TypeScript Project

```bash
# Create tsconfig.json with default settings
tsc --init
```

### Run TypeScript Files Directly

Use `tsx` to run TypeScript files without compiling first:

```bash
tsx index.ts
```

Or use `ts-node`:

```bash
ts-node index.ts
```

### Compile TypeScript

```bash
# Compile a single file
tsc index.ts

# Compile entire project (uses tsconfig.json)
tsc

# Watch mode - recompile on changes
tsc --watch
```

## Example Workflows

### Starting a New Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Initialize npm and TypeScript
npm init -y
tsc --init

# Create source file
mkdir src
echo 'console.log("Hello TypeScript!")' > src/index.ts

# Run it
tsx src/index.ts
```

### Setting Up a Node.js Project

```json
// package.json
{
  "name": "my-project",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  }
}
```

```json
// tsconfig.json (key settings)
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true
  }
}
```

### Running with Watch Mode

```bash
# Watch and rerun on changes
tsx watch src/index.ts

# Or compile and watch
tsc --watch
```

## Troubleshooting

### `tsc` not found

If `tsc` isn't found after installation, reload your shell or use npx:

```bash
source ~/.bashrc
# or
npx tsc --version
```

### Type Errors with Node.js APIs

Ensure `@types/node` is installed:

```bash
npm install --save-dev @types/node
```

### ESLint Not Working

1. Ensure you have an ESLint config file (`.eslintrc.js` or `eslint.config.js`)
2. Reload VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"

## Documentation

- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [tsx Documentation](https://tsx.is/)
- [ts-node Documentation](https://typestrong.org/ts-node/)
