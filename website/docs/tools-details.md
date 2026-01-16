---
sidebar_position: 8
sidebar_label: Tool Details
---

# Tool Details

:::note Auto-generated
This page is auto-generated. Regenerate with: `dev-docs`
:::

Detailed installation options for each tool. See [Available Tools](tools) for the overview.

---

## Table of Contents

- [Development Tools](#development-tools)
- [AI & Machine Learning Tools](#ai-machine-learning-tools)
- [Cloud & Infrastructure Tools](#cloud-infrastructure-tools)
- [Data & Analytics Tools](#data-analytics-tools)
- [Infrastructure & Configuration](#infrastructure-configuration)

---

## Development Tools

### Bash Development Tools

*Bash scripting environment with shellcheck linting, shfmt formatting, and language server support.*

**Script ID:** `dev-bash`  
**Script:** `install-dev-bash.sh`  
**Website:** [https://www.gnu.org/software/bash/](https://www.gnu.org/software/bash/)  
**Command:** `.devcontainer/additions/install-dev-bash.sh --help`

Complete Bash development setup including shellcheck for static analysis and linting, shfmt for code formatting, and bash-language-server for IDE features like autocomplete and go-to-definition. Includes VS Code extensions for inline warnings and format-on-save.

**Tags:** bash,shell,scripting,shellcheck,shfmt,linting,formatting

**Related:** `dev-python`, `dev-typescript`

<details>
<summary>Installation details (click to expand)</summary>

```


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Bash Development Tools
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID:           dev-bash
Name:         Bash Development Tools
Script version: 0.0.1
Category:     LANGUAGE_DEV, Development Tools
Description:  Adds shellcheck, shfmt, bash-language-server, and VS Code extensions for Bash development

Usage:

  Action:
      install-dev-bash.sh               # Install Bash development tools
      install-dev-bash.sh --uninstall   # Uninstall Bash development tools

  Info:
      install-dev-bash.sh --help        # Show help and usage information

System Packages (APT):
  - shellcheck
  - shfmt

Node.js Packages (NPM):
  - bash-language-server

VS Code Extensions:
  - ShellCheck (timonwong.shellcheck) - Inline shellcheck warnings
  - shell-format (foxundermoon.shell-format) - Format on save
  - Bash IDE (mads-hartmann.bash-ide-vscode) - Language server integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
</details>

---

### C/C++ Development Tools

*C/C++ development environment with GCC, Clang, CMake, debuggers, and VS Code extensions.*

**Script ID:** `dev-cpp`  
**Script:** `install-dev-cpp.sh`  
**Website:** [https://isocpp.org](https://isocpp.org)  
**Command:** `.devcontainer/additions/install-dev-cpp.sh --help`

Complete C/C++ development setup including GCC and Clang compilers, CMake and Make build systems, GDB and LLDB debuggers, Valgrind for memory analysis, and clang-format/clang-tidy for code quality. Includes VS Code extension pack for C/C++ development.

**Tags:** c,cpp,gcc,clang,cmake,make,gdb,lldb,debugging

**Related:** `dev-rust`, `dev-fortran`, `dev-golang`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### C# Development Tools

*C# and .NET development environment with SDK, ASP.NET Core runtime, and VS Code C# Dev Kit.*

**Script ID:** `dev-csharp`  
**Script:** `install-dev-csharp.sh`  
**Website:** [https://dotnet.microsoft.com](https://dotnet.microsoft.com)  
**Command:** `.devcontainer/additions/install-dev-csharp.sh --help`

Complete C# and .NET development setup including the .NET SDK, ASP.NET Core runtime for web development, and the C# Dev Kit for VS Code providing IntelliSense, debugging, and project management. Supports .NET 8.0 and other versions.

**Tags:** csharp,dotnet,aspnet,microsoft,visual-studio,sdk

**Related:** `dev-java`, `dev-typescript`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Fortran Development Tools

*Fortran development environment with GNU Fortran, LAPACK, BLAS, and VS Code extensions.*

**Script ID:** `dev-fortran`  
**Script:** `install-dev-fortran.sh`  
**Website:** [https://fortran-lang.org](https://fortran-lang.org)  
**Command:** `.devcontainer/additions/install-dev-fortran.sh --help`

Complete Fortran development setup including GNU Fortran compiler (gfortran), LAPACK and BLAS numerical libraries, CMake build system, and VS Code extensions for Modern Fortran with IntelliSense and debugging support.

**Tags:** fortran,gfortran,scientific,computing,lapack,blas,numerical

**Related:** `dev-cpp`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Go Runtime & Development Tools

*Go development environment with runtime, language server, debugger, and static analysis tools.*

**Script ID:** `dev-golang`  
**Script:** `install-dev-golang.sh`  
**Website:** [https://go.dev](https://go.dev)  
**Command:** `.devcontainer/additions/install-dev-golang.sh --help`

Complete Go development setup including the Go runtime, gopls language server for IDE features, Delve debugger, and staticcheck for code analysis. Includes VS Code extensions for Go development, test running, and Protocol Buffer support.

**Tags:** go,golang,gopls,delve,staticcheck,protobuf

**Related:** `dev-rust`, `dev-typescript`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Java Runtime & Development Tools

*Java development environment with JDK, Maven, Gradle, and comprehensive VS Code extension pack.*

**Script ID:** `dev-java`  
**Script:** `install-dev-java.sh`  
**Website:** [https://dev.java](https://dev.java)  
**Command:** `.devcontainer/additions/install-dev-java.sh --help`

Complete Java development setup including the JDK (supports versions 11, 17, 21), Maven and Gradle build tools, and the VS Code Extension Pack for Java with debugging, test running, Maven integration, and dependency management.

**Tags:** java,jdk,maven,gradle,spring,enterprise

**Related:** `dev-csharp`, `dev-golang`, `dev-typescript`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### PHP Laravel Development Tools

*PHP Laravel development environment with PHP 8.4, Composer, Laravel installer, and VS Code extensions.*

**Script ID:** `dev-php-laravel`  
**Script:** `install-dev-php-laravel.sh`  
**Website:** [https://laravel.com](https://laravel.com)  
**Command:** `.devcontainer/additions/install-dev-php-laravel.sh --help`

Complete PHP Laravel development setup including PHP 8.4, Composer package manager, Laravel installer, and comprehensive VS Code extensions for Intelephense, Xdebug, Blade templates, Artisan commands, and namespace resolution.

**Tags:** php,laravel,composer,artisan,blade,web,framework

**Related:** `dev-typescript`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Python Development Tools

*Python development environment with ipython, pytest-cov, and python-dotenv for enhanced coding and testing.*

**Script ID:** `dev-python`  
**Script:** `install-dev-python.sh`  
**Website:** [https://python.org](https://python.org)  
**Command:** `.devcontainer/additions/install-dev-python.sh --help`

Complete Python development setup including ipython for interactive development, pytest-cov for test coverage, and python-dotenv for environment management. Includes VS Code extensions for Python, Pylance, Black formatter, Flake8, and Mypy type checking.

**Tags:** python,pip,ipython,pytest,coverage,development,venv

**Related:** `dev-typescript`, `dev-golang`, `dev-rust`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Rust Development Tools

*Rust development environment with rustup, cargo tooling, and rust-analyzer for systems programming.*

**Script ID:** `dev-rust`  
**Script:** `install-dev-rust.sh`  
**Website:** [https://www.rust-lang.org](https://www.rust-lang.org)  
**Command:** `.devcontainer/additions/install-dev-rust.sh --help`

Complete Rust setup via rustup including the Rust compiler, Cargo package manager, cargo-edit for dependency management, cargo-watch for auto-rebuild, and cargo-outdated for dependency updates. Includes rust-analyzer and CodeLLDB debugger VS Code extensions.

**Tags:** rust,cargo,rustup,systems,programming,memory,safety

**Related:** `dev-golang`, `dev-cpp`, `dev-typescript`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### TypeScript Development Tools

*TypeScript development environment with compiler, tsx runtime, and essential tooling for modern web development.*

**Script ID:** `dev-typescript`  
**Script:** `install-dev-typescript.sh`  
**Website:** [https://www.typescriptlang.org](https://www.typescriptlang.org)  
**Command:** `.devcontainer/additions/install-dev-typescript.sh --help`

Complete TypeScript setup including the TypeScript compiler (tsc), tsx for running TypeScript directly, ts-node for Node.js integration, and @types/node for Node.js type definitions. Includes Prettier and ESLint VS Code extensions.

**Tags:** typescript,javascript,nodejs,npm,tsc,tsx,eslint,prettier

**Related:** `dev-python`, `dev-golang`, `dev-rust`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

## AI & Machine Learning Tools

### Claude Code

*Claude Code - Anthropic's terminal-based AI coding assistant with agentic capabilities.*

**Script ID:** `dev-ai-claudecode`  
**Script:** `install-dev-ai-claudecode.sh`  
**Website:** [https://claude.ai/code](https://claude.ai/code)  
**Command:** `.devcontainer/additions/install-dev-ai-claudecode.sh --help`

Claude Code is Anthropic's terminal-based AI coding assistant with agentic capabilities. Features include codebase understanding, multi-file editing, shell command execution, and LSP integration for intelligent code assistance directly in your terminal.

**Tags:** claude,anthropic,ai,coding,assistant,agentic,terminal

**Related:** `tool-api-dev`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

## Cloud & Infrastructure Tools

### API Development Tools

*API development tools with Thunder Client REST client and OpenAPI/Swagger editor.*

**Script ID:** `tool-api-dev`  
**Script:** `install-tool-api-dev.sh`  
**Website:** [https://www.thunderclient.com](https://www.thunderclient.com)  
**Command:** `.devcontainer/additions/install-tool-api-dev.sh --help`

VS Code extensions for API development including Thunder Client for REST API testing and the OpenAPI Editor for Swagger/OpenAPI specification editing and validation. Lightweight alternatives to Postman and Swagger UI.

**Tags:** api,rest,openapi,swagger,http,client,testing

**Related:** `dev-typescript`, `dev-python`, `tool-azure-dev`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Azure Application Development

*Azure application development with CLI, Functions, Azurite emulator, and VS Code extensions.*

**Script ID:** `tool-azure-dev`  
**Script:** `install-tool-azure-dev.sh`  
**Website:** [https://azure.microsoft.com](https://azure.microsoft.com)  
**Command:** `.devcontainer/additions/install-tool-azure-dev.sh --help`

Complete Azure development toolkit including Azure CLI, Functions Core Tools v4, Azurite storage emulator, and VS Code extensions for App Service, Functions, Storage, Service Bus, Cosmos DB, and Bicep infrastructure as code.

**Tags:** azure,microsoft,cloud,functions,azurite,cosmosdb,servicebus,bicep

**Related:** `tool-azure-ops`, `tool-kubernetes`, `tool-iac`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Azure Operations & Infrastructure Management

*Azure operations tools with PowerShell, Az modules, Microsoft Graph, and KQL support.*

**Script ID:** `tool-azure-ops`  
**Script:** `install-tool-azure-ops.sh`  
**Website:** [https://azure.microsoft.com](https://azure.microsoft.com)  
**Command:** `.devcontainer/additions/install-tool-azure-ops.sh --help`

Azure infrastructure and operations management toolkit including PowerShell 7, Az and Microsoft.Graph modules, Exchange Online Management, Azure CLI, and VS Code extensions for Bicep IaC, KQL queries, and Azure policy management.

**Tags:** azure,powershell,operations,infrastructure,management,policy,graph

**Related:** `tool-azure-dev`, `tool-iac`, `tool-kubernetes`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Okta Identity Management Tools

*Okta identity management tools with CLI and VS Code Okta Explorer extension.*

**Script ID:** `tool-okta`  
**Script:** `install-tool-okta.sh`  
**Website:** [https://www.okta.com](https://www.okta.com)  
**Command:** `.devcontainer/additions/install-tool-okta.sh --help`

Okta identity and access management toolkit including the Okta CLI for managing users, groups, and applications, plus the Okta Explorer VS Code extension for browsing and managing Okta organizations directly from the IDE.

**Tags:** okta,identity,authentication,sso,iam,security

**Related:** `tool-azure-ops`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Microsoft Power Platform Tools

*Microsoft Power Platform CLI (pac) for Power Apps, Power Automate, and PCF development.*

**Script ID:** `tool-powerplatform`  
**Script:** `install-tool-powerplatform.sh`  
**Website:** [https://powerplatform.microsoft.com](https://powerplatform.microsoft.com)  
**Command:** `.devcontainer/additions/install-tool-powerplatform.sh --help`

Microsoft Power Platform development toolkit including the Power Platform CLI (pac) as a .NET global tool for managing Power Apps, Power Automate flows, Dataverse solutions, and Power Platform Component Framework (PCF) controls. Requires .NET SDK.

**Tags:** powerplatform,powerapps,powerautomate,microsoft,lowcode,pcf

**Related:** `tool-azure-dev`, `dev-csharp`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

## Data & Analytics Tools

### Data & Analytics Tools

*Data analytics stack with Jupyter, pandas, numpy, matplotlib, scikit-learn, and dbt.*

**Script ID:** `tool-dataanalytics`  
**Script:** `install-tool-dataanalytics.sh`  
**Website:** [https://jupyter.org](https://jupyter.org)  
**Command:** `.devcontainer/additions/install-tool-dataanalytics.sh --help`

Complete data analytics toolkit including Jupyter notebooks and JupyterLab, pandas for data manipulation, numpy for numerical computing, matplotlib and seaborn for visualization, scikit-learn for machine learning, and dbt for data transformation.

**Tags:** jupyter,pandas,numpy,matplotlib,data,science,analytics,dbt

**Related:** `tool-databricks`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Databricks Development Tools

*Databricks development tools with CLI, SDK, Connect, PySpark, and Delta Lake support.*

**Script ID:** `tool-databricks`  
**Script:** `install-tool-databricks.sh`  
**Website:** [https://www.databricks.com](https://www.databricks.com)  
**Command:** `.devcontainer/additions/install-tool-databricks.sh --help`

Complete Databricks development environment including Databricks CLI, Python SDK, Databricks Connect for remote development, PySpark and Delta Lake for data processing, and VS Code extensions for Asset Bundles development and workspace integration.

**Tags:** databricks,spark,pyspark,delta,lake,data,engineering

**Related:** `tool-dataanalytics`, `dev-python`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

## Infrastructure & Configuration

### Development Utilities

*Development utilities for database management, API testing, and Docker container management.*

**Script ID:** `tool-dev-utils`  
**Script:** `install-tool-dev-utils.sh`  
**Website:** [https://vscode-sqltools.mteixeira.dev](https://vscode-sqltools.mteixeira.dev)  
**Command:** `.devcontainer/additions/install-tool-dev-utils.sh --help`

Language-agnostic development utilities including SQLTools for database management (MySQL, PostgreSQL, SQLite, MSSQL, MongoDB), REST Client for HTTP API testing, and Docker extension for container, image, and volume management.

**Tags:** database,sql,docker,containers,rest,http,utilities

**Related:** `tool-api-dev`, `tool-kubernetes`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Infrastructure as Code Tools

*Infrastructure as Code tools with Terraform, Ansible, and Azure Bicep support.*

**Script ID:** `tool-iac`  
**Script:** `install-tool-iac.sh`  
**Website:** [https://www.terraform.io](https://www.terraform.io)  
**Command:** `.devcontainer/additions/install-tool-iac.sh --help`

Complete Infrastructure as Code toolkit including Terraform for multi-cloud provisioning, Ansible for configuration management and automation, ansible-lint for playbook validation, and Azure Bicep for ARM template development with VS Code extensions.

**Tags:** terraform,ansible,bicep,infrastructure,devops,automation

**Related:** `tool-kubernetes`, `tool-azure-ops`, `tool-azure-dev`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---

### Kubernetes Development Tools

*Kubernetes development tools with kubectl, k9s terminal UI, and Helm package manager.*

**Script ID:** `tool-kubernetes`  
**Script:** `install-tool-kubernetes.sh`  
**Website:** [https://kubernetes.io](https://kubernetes.io)  
**Command:** `.devcontainer/additions/install-tool-kubernetes.sh --help`

Kubernetes development toolkit including kubectl CLI for cluster management, k9s terminal UI for interactive cluster exploration, Helm for package management, and VS Code Kubernetes extension. Sets up .devcontainer.secrets for secure kubeconfig storage.

**Tags:** kubernetes,kubectl,k9s,helm,containers,orchestration

**Related:** `tool-iac`, `tool-azure-dev`, `tool-dev-utils`

<details>
<summary>Installation details (click to expand)</summary>

```


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
</details>

---
