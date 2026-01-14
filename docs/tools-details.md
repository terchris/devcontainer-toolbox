# Tool Details

> **Auto-generated** | Last updated: 2026-01-14 17:07:58  
> Regenerate with: `.devcontainer/manage/generate-manual.sh`

Detailed installation options for each tool. See [tools.md](tools.md) for the overview.

---

## Table of Contents

- [Development Tools](#development-tools)
- [AI & Machine Learning Tools](#ai---machine-learning-tools)
- [Cloud & Infrastructure Tools](#cloud---infrastructure-tools)
- [Data & Analytics Tools](#data---analytics-tools)
- [Infrastructure & Configuration](#infrastructure---configuration)

---

## Development Tools

### C/C++ Development Tools

**Script ID:** `dev-cpp`  
**Script:** `install-dev-cpp.sh`  
**Command:** `.devcontainer/additions/install-dev-cpp.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-cpp-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 C/C++ Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-cpp
Name:         C/C++ Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs GCC, Clang, build tools, debuggers, and VS Code extensions for C/C++ development

Usage:

  Action:
      install-dev-cpp.sh                # Install C/C++ development tools
      install-dev-cpp.sh --uninstall    # Uninstall C/C++ development tools

  Info:
      install-dev-cpp.sh --help         # Show help and usage information

System Packages (APT):
  - build-essential
  - gcc
  - g++
  - clang
  - clang-format
  - clang-tidy
  - cmake
  - make
  - ninja-build
  - gdb
  - lldb
  - valgrind
  - pkg-config
  - autoconf
  - automake
  - libtool

VS Code Extensions:
  - C/C++ (ms-vscode.cpptools) - C/C++ IntelliSense, debugging, and code browsing
  - C/C++ Extension Pack (ms-vscode.cpptools-extension-pack) - Popular extensions for C/C++ development
  - CMake Tools (ms-vscode.cmake-tools) - CMake support for VS Code
  - CMake (twxs.cmake) - CMake language support
  - CodeLLDB (vadimcn.vscode-lldb) - Native debugger based on LLDB

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### C# Development Tools

**Script ID:** `dev-csharp`  
**Script:** `install-dev-csharp.sh`  
**Command:** `.devcontainer/additions/install-dev-csharp.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-csharp-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 C# Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-csharp
Name:         C# Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs .NET SDK, ASP.NET Core Runtime, and VS Code extensions for C# development
Default:      Version 8.0

Usage:

  Action:
      install-dev-csharp.sh             # Install C# / .NET development tools
      install-dev-csharp.sh --uninstall # Uninstall C# / .NET development tools

  Info:
      install-dev-csharp.sh --help      # Show help and usage information

VS Code Extensions:
  - C# Dev Kit (ms-dotnettools.csdevkit) - Complete C# development experience
  - C# (ms-dotnettools.csharp) - C# language support
  - .NET Runtime (ms-dotnettools.vscode-dotnet-runtime) - .NET runtime support

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Fortran Development Tools

**Script ID:** `dev-fortran`  
**Script:** `install-dev-fortran.sh`  
**Command:** `.devcontainer/additions/install-dev-fortran.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-fortran-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Fortran Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-fortran
Name:         Fortran Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs GNU Fortran compiler (gfortran), build tools, and VS Code extensions for Fortran development

Usage:

  Action:
      install-dev-fortran.sh            # Install Fortran development tools
      install-dev-fortran.sh --uninstall # Uninstall Fortran development tools

  Info:
      install-dev-fortran.sh --help     # Show help and usage information

System Packages (APT):
  - gfortran
  - build-essential
  - cmake
  - make
  - liblapack-dev
  - libblas-dev

VS Code Extensions:
  - Modern Fortran (fortran-lang.linter-gfortran) - Fortran language support with linting and IntelliSense
  - Fortran IntelliSense (hansec.fortran-ls) - Language server for Fortran
  - Fortran Breakpoint Support (ekibun.fortranbreaker) - Debugging support for Fortran

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Go Runtime & Development Tools

**Script ID:** `dev-golang`  
**Script:** `install-dev-golang.sh`  
**Command:** `.devcontainer/additions/install-dev-golang.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-golang-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Go Runtime & Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-golang
Name:         Go Runtime & Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs Go runtime, common tools, and VS Code extensions for Go development.
Default:      Version 1.21.0

Usage:

  Action:
      install-dev-golang.sh             # Install Go with default version
      install-dev-golang.sh --version <arg> # Install specific Go version
      install-dev-golang.sh --uninstall # Uninstall Go development tools

  Info:
      install-dev-golang.sh --help      # Show help and usage information

Go Packages (go install):
  - golang.org/x/tools/gopls@latest
  - github.com/go-delve/delve/cmd/dlv@latest
  - honnef.co/go/tools/cmd/staticcheck@latest

VS Code Extensions:
  - Go (golang.go) - Core Go language support
  - Go Test Explorer (premparihar.gotestexplorer) - Test runner and debugger
  - Protocol Buffers (zxh404.vscode-proto3) - Protocol Buffer support

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Java Runtime & Development Tools

**Script ID:** `dev-java`  
**Script:** `install-dev-java.sh`  
**Command:** `.devcontainer/additions/install-dev-java.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-java-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Java Runtime & Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-java
Name:         Java Runtime & Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs Java JDK, Maven, Gradle, and VS Code extensions for Java development.
Default:      Version 17

Usage:

  Action:
      install-dev-java.sh               # Install Java with default version
      install-dev-java.sh --version <arg> # Install specific Java version
      install-dev-java.sh --uninstall   # Uninstall Java development tools

  Info:
      install-dev-java.sh --help        # Show help and usage information

Java Build Tools (APT):
  - maven
  - gradle

VS Code Extensions:
  - Language Support for Java (redhat.java) - Core Java language support
  - Debugger for Java (vscjava.vscode-java-debug) - Debugging support
  - Test Runner for Java (vscjava.vscode-java-test) - Test runner and debugger
  - Maven for Java (vscjava.vscode-maven) - Maven project support
  - Dependency Viewer (vscjava.vscode-java-dependency) - View and manage dependencies
  - Extension Pack for Java (vscjava.vscode-java-pack) - Collection of popular Java extensions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### PHP Laravel Development Tools

**Script ID:** `dev-php-laravel`  
**Script:** `install-dev-php-laravel.sh`  
**Command:** `.devcontainer/additions/install-dev-php-laravel.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-php-laravel-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 PHP Laravel Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-php-laravel
Name:         PHP Laravel Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs PHP 8.4, Composer, Laravel installer, and sets up Laravel development environment
Default:      Version 8.4

Usage:

  Action:
      install-dev-php-laravel.sh        # Install PHP Laravel development tools
      install-dev-php-laravel.sh --uninstall # Uninstall PHP Laravel development tools

  Info:
      install-dev-php-laravel.sh --help # Show help and usage information

VS Code Extensions:
  - PHP Intelephense (bmewburn.vscode-intelephense-client) - Advanced PHP language support with IntelliSense
  - PHP Debug (xdebug.php-debug) - Debug PHP applications using Xdebug
  - PHP DocBlocker (neilbrayfield.php-docblocker) - Automatically generate PHPDoc comments
  - Composer (ikappas.composer) - Composer dependency manager integration
  - PHP Namespace Resolver (mehedidracula.php-namespace-resolver) - Auto-import and resolve PHP namespaces
  - Laravel Blade Snippets (onecentlin.laravel-blade) - Blade syntax highlighting and snippets
  - Laravel Artisan (ryannaddy.laravel-artisan) - Run Laravel Artisan commands from VS Code

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Python Development Tools

**Script ID:** `dev-python`  
**Script:** `install-dev-python.sh`  
**Command:** `.devcontainer/additions/install-dev-python.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-python-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Python Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-python
Name:         Python Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Adds ipython, pytest-cov, and VS Code extensions for Python development

Usage:

  Action:
      install-dev-python.sh             # Install Python development tools
      install-dev-python.sh --uninstall # Uninstall Python development tools

  Info:
      install-dev-python.sh --help      # Show help and usage information

Python Packages (pip):
  - ipython
  - pytest-cov
  - python-dotenv

VS Code Extensions:
  - Python (ms-python.python) - Python language support
  - Pylance (ms-python.vscode-pylance) - Python language server
  - Black Formatter (ms-python.black-formatter) - Python code formatter
  - Flake8 (ms-python.flake8) - Python linter
  - Mypy (ms-python.mypy-type-checker) - Python type checker

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Rust Development Tools

**Script ID:** `dev-rust`  
**Script:** `install-dev-rust.sh`  
**Command:** `.devcontainer/additions/install-dev-rust.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-rust-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Rust Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-rust
Name:         Rust Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Installs Rust (latest stable via rustup), cargo, and sets up Rust development environment

Usage:

  Action:
      install-dev-rust.sh               # Install Rust development tools
      install-dev-rust.sh --uninstall   # Uninstall Rust development tools

  Info:
      install-dev-rust.sh --help        # Show help and usage information

System Packages (APT):
  - build-essential
  - pkg-config
  - libssl-dev

Rust Packages (cargo install):
  - cargo-edit
  - cargo-watch
  - cargo-outdated

VS Code Extensions:
  - Rust Analyzer (rust-lang.rust-analyzer) - Rust language support with rust-analyzer
  - CodeLLDB (vadimcn.vscode-lldb) - Native debugger for Rust
  - Dependi (serayuzgur.dependi) - Replacement for Crates; manages Rust dependencies

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### TypeScript Development Tools

**Script ID:** `dev-typescript`  
**Script:** `install-dev-typescript.sh`  
**Command:** `.devcontainer/additions/install-dev-typescript.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-typescript-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 TypeScript Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-typescript
Name:         TypeScript Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Adds TypeScript and development tools (Node.js already in devcontainer)

Usage:

  Action:
      install-dev-typescript.sh         # Install TypeScript development tools
      install-dev-typescript.sh --uninstall # Uninstall TypeScript development tools

  Info:
      install-dev-typescript.sh --help  # Show help and usage information

Node.js Packages (NPM):
  - typescript
  - tsx
  - @types/node
  - ts-node

VS Code Extensions:
  - Prettier (esbenp.prettier-vscode) - Code formatter for consistent code style
  - ESLint (dbaeumer.vscode-eslint) - JavaScript and TypeScript linting

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

## AI & Machine Learning Tools

### Claude Code

**Script ID:** `dev-ai-claudecode`  
**Script:** `install-dev-ai-claudecode.sh`  
**Command:** `.devcontainer/additions/install-dev-ai-claudecode.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-dev-ai-claudecode-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Claude Code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-ai-claudecode
Name:         Claude Code
Script version: 0.0.1
Category:     AI_TOOLS, AI & Machine Learning Tools
Description:  Installs Claude Code, Anthropic's terminal-based AI coding assistant with agentic capabilities and LSP integration

Usage:

  Action:
      install-dev-ai-claudecode.sh      # Install Claude Code
      install-dev-ai-claudecode.sh --uninstall # Uninstall Claude Code

  Info:
      install-dev-ai-claudecode.sh --help # Show help and usage information

System Packages (APT):
  - curl

Node.js Packages (NPM):
  - @anthropic-ai/claude-code

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

## Cloud & Infrastructure Tools

### API Development Tools

**Script ID:** `tool-api-dev`  
**Script:** `install-tool-api-dev.sh`  
**Command:** `.devcontainer/additions/install-tool-api-dev.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-api-dev-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 API Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-api-dev
Name:         API Development Tools
Script version: 0.0.1
Category:     CLOUD_TOOLS, Cloud & Infrastructure Tools
Description:  Installs Thunder Client REST API client and OpenAPI Editor for API development, testing, and documentation

Usage:

  Action:
      install-tool-api-dev.sh           # Install API development tools
      install-tool-api-dev.sh --uninstall # Uninstall API development tools

  Info:
      install-tool-api-dev.sh --help    # Show help and usage information

VS Code Extensions:
  - Thunder Client (rangav.vscode-thunder-client) - Lightweight REST API client
  - OpenAPI Editor (42crunch.vscode-openapi) - OpenAPI/Swagger editing and validation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Azure Application Development

**Script ID:** `tool-azure-dev`  
**Script:** `install-tool-azure-dev.sh`  
**Command:** `.devcontainer/additions/install-tool-azure-dev.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-azure-dev-20260114-170758.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Azure Application Development
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-azure-dev
Name:         Azure Application Development
Script version: 0.0.1
Category:     CLOUD_TOOLS, Cloud & Infrastructure Tools
Description:  Installs Azure CLI, Functions Core Tools, Azurite, and VS Code extensions for building Azure applications, APIs, Service Bus, and Cosmos DB solutions

Usage:

  Action:
      install-tool-azure-dev.sh         # Install Azure development tools
      install-tool-azure-dev.sh --uninstall # Uninstall Azure development tools

  Info:
      install-tool-azure-dev.sh --help  # Show help and usage information

System Packages (APT):
  - azure-cli

Node.js Packages (NPM):
  - azure-functions-core-tools@4
  - azurite

VS Code Extensions:
  - Azure Account (ms-vscode.azure-account) - Azure account management
  - Azure Resources (ms-azuretools.vscode-azureresourcegroups) - View and manage Azure resources
  - Azure App Service (ms-azuretools.vscode-azureappservice) - Deploy to Azure App Service
  - Azure Functions (ms-azuretools.vscode-azurefunctions) - Create and deploy Azure Functions
  - Azure Storage (ms-azuretools.vscode-azurestorage) - Manage Azure Storage accounts
  - Service Bus Explorer (digital-molecules.service-bus-explorer) - Browse queues, topics, and messages
  - Azure Cosmos DB (ms-azuretools.vscode-cosmosdb) - Cosmos DB and database support
  - Bicep (ms-azuretools.vscode-bicep) - Bicep language support for IaC

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Azure Operations & Infrastructure Management

**Script ID:** `tool-azure-ops`  
**Script:** `install-tool-azure-ops.sh`  
**Command:** `.devcontainer/additions/install-tool-azure-ops.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-azure-ops-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Azure Operations & Infrastructure Management
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-azure-ops
Name:         Azure Operations & Infrastructure Management
Script version: 0.0.1
Category:     CLOUD_TOOLS, Cloud & Infrastructure Tools
Description:  Installs Azure CLI, PowerShell with Az/Graph modules, and VS Code extensions for Azure resource management, policy, Bicep IaC, and KQL queries
Default:      Version 7.5.4

Usage:

  Action:
      install-tool-azure-ops.sh         # Install Azure operations tools
      install-tool-azure-ops.sh --uninstall # Uninstall Azure operations tools

  Info:
      install-tool-azure-ops.sh --help  # Show help and usage information

System Packages (APT):
  - azure-cli

PowerShell Modules:
  - Az
  - Microsoft.Graph
  - ExchangeOnlineManagement
  - PSScriptAnalyzer

VS Code Extensions:
  - PowerShell (ms-vscode.powershell) - PowerShell language support and debugging
  - Azure Tools (ms-vscode.vscode-node-azure-pack) - Complete Azure development toolkit
  - Azure Account (ms-vscode.azure-account) - Azure subscription management and sign-in
  - Azure Resources (ms-azuretools.vscode-azureresourcegroups) - View and manage Azure resources
  - Bicep (ms-azuretools.vscode-bicep) - Bicep language support for IaC
  - Azure Policy (AzurePolicy.azurepolicyextension) - View and manage Azure Policy definitions
  - Kusto Syntax Highlighting (josin.kusto-syntax-highlighting) - KQL syntax highlighting for log queries

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Okta Identity Management Tools

**Script ID:** `tool-okta`  
**Script:** `install-tool-okta.sh`  
**Command:** `.devcontainer/additions/install-tool-okta.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-okta-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Okta Identity Management Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-okta
Name:         Okta Identity Management Tools
Script version: 0.0.3
Category:     CLOUD_TOOLS, Cloud & Infrastructure Tools
Description:  Installs Okta CLI and VS Code extensions for Okta identity and access management

Usage:

  Action:
      install-tool-okta.sh              # Install Okta identity management tools
      install-tool-okta.sh --uninstall  # Uninstall Okta tools

  Info:
      install-tool-okta.sh --help       # Show help and usage information

Python Packages (pip):
  - okta-cli

VS Code Extensions:
  - Okta Explorer (OktaDcp.okta-explorer) - Browse and manage Okta organizations, users, and groups

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Microsoft Power Platform Tools

**Script ID:** `tool-powerplatform`  
**Script:** `install-tool-powerplatform.sh`  
**Command:** `.devcontainer/additions/install-tool-powerplatform.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-powerplatform-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Microsoft Power Platform Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-powerplatform
Name:         Microsoft Power Platform Tools
Script version: 0.0.3
Category:     CLOUD_TOOLS, Cloud & Infrastructure Tools
Description:  Installs Power Platform CLI (pac - dotnet global tool), Power Platform Tools VS Code extension. Requires .NET SDK and x64 (AMD64) architecture.

Usage:

  Action:
      install-tool-powerplatform.sh     # Install Power Platform tools
      install-tool-powerplatform.sh --uninstall # Uninstall Power Platform tools

  Info:
      install-tool-powerplatform.sh --help # Show help and usage information

.NET Tools (dotnet tool install --global):
  - Microsoft.PowerApps.CLI.Tool

VS Code Extensions:
  - Power Platform Tools (microsoft-IsvExpTools.powerplatform-vscode) - Power Platform CLI integration and development tools

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

## Data & Analytics Tools

### Data & Analytics Tools

**Script ID:** `tool-dataanalytics`  
**Script:** `install-tool-dataanalytics.sh`  
**Command:** `.devcontainer/additions/install-tool-dataanalytics.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-dataanalytics-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Data & Analytics Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-dataanalytics
Name:         Data & Analytics Tools
Script version: 0.0.1
Category:     DATA_ANALYTICS, Data & Analytics Tools
Description:  Installs Python data analysis libraries, Jupyter notebooks, and related VS Code extensions

Usage:

  Action:
      install-tool-dataanalytics.sh     # Install data analytics tools
      install-tool-dataanalytics.sh --uninstall # Uninstall data analytics tools

  Info:
      install-tool-dataanalytics.sh --help # Show help and usage information

Python Packages (pip):
  - pandas
  - numpy
  - matplotlib
  - seaborn
  - scikit-learn
  - jupyter
  - jupyterlab
  - notebook
  - dbt-core
  - dbt-postgres

VS Code Extensions:
  - Python (ms-python.python) - Python language support
  - Jupyter (ms-toolsai.jupyter) - Jupyter notebook support
  - Pylance (ms-python.vscode-pylance) - Python language server
  - DBT (bastienboutonnet.vscode-dbt) - DBT language support
  - DBT Power User (innoverio.vscode-dbt-power-user) - Enhanced DBT support

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Databricks Development Tools

**Script ID:** `tool-databricks`  
**Script:** `install-tool-databricks.sh`  
**Command:** `.devcontainer/additions/install-tool-databricks.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-databricks-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Databricks Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-databricks
Name:         Databricks Development Tools
Script version: 0.0.1
Category:     DATA_ANALYTICS, Data & Analytics Tools
Description:  Installs Databricks CLI, Python SDK, Connect, and related tooling for Asset Bundles development

Usage:

  Action:
      install-tool-databricks.sh        # Install Databricks development tools
      install-tool-databricks.sh --uninstall # Uninstall Databricks development tools

  Info:
      install-tool-databricks.sh --help # Show help and usage information

Python Packages (pip):
  - databricks-sdk
  - databricks-connect
  - pyspark
  - delta-spark
  - pyarrow
  - sqlparse

VS Code Extensions:
  - Databricks (databricks.databricks) - Databricks workspace integration and Asset Bundles
  - Jupyter (ms-toolsai.jupyter) - Notebook support for Databricks notebooks
  - Python (ms-python.python) - Python language support
  - Pylance (ms-python.vscode-pylance) - Python language server
  - YAML (redhat.vscode-yaml) - YAML support for databricks.yml
  - REST Client (humao.rest-client) - Test Databricks REST APIs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

## Infrastructure & Configuration

### Development Utilities

**Script ID:** `tool-dev-utils`  
**Script:** `install-tool-dev-utils.sh`  
**Command:** `.devcontainer/additions/install-tool-dev-utils.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-dev-utils-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Development Utilities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-dev-utils
Name:         Development Utilities
Script version: 0.0.1
Category:     INFRA_CONFIG, Infrastructure & Configuration
Description:  Database management (SQLTools), API testing (REST Client), and container management (Docker) for multi-language development

Usage:

  Action:
      install-tool-dev-utils.sh         # Install development utilities
      install-tool-dev-utils.sh --uninstall # Uninstall development utilities

  Info:
      install-tool-dev-utils.sh --help  # Show help and usage information

System Packages (APT):
  - docker.io

VS Code Extensions:
  - SQLTools (mtxr.sqltools) - Database management and SQL query tool for MySQL, PostgreSQL, SQLite, MSSQL, MongoDB
  - REST Client (humao.rest-client) - Send HTTP requests and view responses directly in VS Code
  - Docker (ms-azuretools.vscode-docker) - Manage containers, images, volumes, networks, and Dockerfiles

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Infrastructure as Code Tools

**Script ID:** `tool-iac`  
**Script:** `install-tool-iac.sh`  
**Command:** `.devcontainer/additions/install-tool-iac.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-iac-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Infrastructure as Code Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-iac
Name:         Infrastructure as Code Tools
Script version: 0.0.1
Category:     INFRA_CONFIG, Infrastructure & Configuration
Description:  Installs Infrastructure as Code and configuration management tools: Ansible, Terraform, and Bicep

Usage:

  Action:
      install-tool-iac.sh               # Install Infrastructure as Code tools
      install-tool-iac.sh --uninstall   # Uninstall Infrastructure as Code tools

  Info:
      install-tool-iac.sh --help        # Show help and usage information

System Packages (APT):
  - ansible
  - ansible-lint
  - terraform

VS Code Extensions:
  - Ansible (redhat.ansible) - Ansible language support and tools
  - Terraform (hashicorp.terraform) - Terraform language support and IntelliSense
  - Bicep (ms-azuretools.vscode-bicep) - Azure Bicep language support

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---

### Kubernetes Development Tools

**Script ID:** `tool-kubernetes`  
**Script:** `install-tool-kubernetes.sh`  
**Command:** `.devcontainer/additions/install-tool-kubernetes.sh --help`

```
📝 Logging to: /tmp/devcontainer-install/install-tool-kubernetes-20260114-170759.log
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Kubernetes Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           tool-kubernetes
Name:         Kubernetes Development Tools
Script version: 0.0.1
Category:     INFRA_CONFIG, Infrastructure & Configuration
Description:  Installs kubectl, k9s, helm and sets up .devcontainer.secrets folder for kubeconfig

Usage:

  Action:
      install-tool-kubernetes.sh        # Install Kubernetes development tools
      install-tool-kubernetes.sh --uninstall # Uninstall Kubernetes tools

  Info:
      install-tool-kubernetes.sh --help # Show help and usage information

VS Code Extensions:
  - Kubernetes (ms-kubernetes-tools.vscode-kubernetes-tools) - Develop, deploy and debug Kubernetes applications
  - YAML (redhat.vscode-yaml) - YAML language support with Kubernetes schema

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
---
