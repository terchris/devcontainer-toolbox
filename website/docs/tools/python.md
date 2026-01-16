---
title: Python Development
sidebar_position: 1
---

# Python Development

The Python development tools add enhanced Python development capabilities to your devcontainer, including an interactive shell, testing tools, and VS Code extensions.

## What Gets Installed

### Python Packages

| Package | Description |
|---------|-------------|
| `ipython` | Enhanced interactive Python shell with syntax highlighting and auto-completion |
| `pytest-cov` | Code coverage plugin for pytest |
| `python-dotenv` | Load environment variables from `.env` files |

:::note
Python 3, pip, pytest, black, and mypy are already included in the base devcontainer image.
:::

### VS Code Extensions

| Extension | Description |
|-----------|-------------|
| Python (ms-python.python) | Python language support |
| Pylance (ms-python.vscode-pylance) | Fast Python language server |
| Black Formatter (ms-python.black-formatter) | Python code formatter |
| Flake8 (ms-python.flake8) | Python linter |
| Mypy (ms-python.mypy-type-checker) | Python type checker |

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-dev-python.sh
```

To uninstall:

```bash
.devcontainer/additions/install-dev-python.sh --uninstall
```

## How to Use

### Interactive Python Shell

Launch IPython for an enhanced interactive experience:

```bash
ipython
```

IPython provides:
- Syntax highlighting
- Tab completion
- Magic commands (`%timeit`, `%history`, etc.)
- Better error messages

### Running Tests with Coverage

Run your tests with coverage reporting:

```bash
pytest --cov=. tests/
```

Generate an HTML coverage report:

```bash
pytest --cov=. --cov-report=html tests/
open htmlcov/index.html
```

### Environment Variables

Use `python-dotenv` to load environment variables:

```python
from dotenv import load_dotenv
import os

load_dotenv()  # Load from .env file
api_key = os.getenv("API_KEY")
```

## Example Workflows

### Starting a New Project

```bash
# Create project directory
mkdir my-project && cd my-project

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Create basic files
echo "pytest\npytest-cov" > requirements-dev.txt
pip install -r requirements-dev.txt
```

### Running Linting and Formatting

```bash
# Format code with Black
black .

# Check types with Mypy
mypy .

# Lint with Flake8
flake8 .
```

## Troubleshooting

### IPython not found

If `ipython` isn't found after installation, reload your shell:

```bash
source ~/.bashrc
```

### VS Code Extensions Not Working

1. Reload VS Code window: `Ctrl+Shift+P` → "Developer: Reload Window"
2. Ensure Python interpreter is selected: `Ctrl+Shift+P` → "Python: Select Interpreter"

## Documentation

- [IPython Documentation](https://ipython.readthedocs.io/)
- [pytest-cov Documentation](https://pytest-cov.readthedocs.io/)
- [python-dotenv Documentation](https://github.com/theskumar/python-dotenv)
