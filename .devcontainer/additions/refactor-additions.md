# Additions while we are refactoring

tools that we should add while refactoring


## Okta tool ✅ COMPLETED

✅ Created install-tool-okta.sh
- Installs okta-cli Python package (v18.1.2)
- Installs Okta Explorer VS Code extension
- Comprehensive documentation with IaC references (Terraform, Pulumi)
- Script version: 0.0.3
- Category: CLOUD_TOOLS


## Power platform tool ✅ COMPLETED

✅ Created install-tool-powerplatform.sh
- Installs Microsoft Power Platform CLI (pac) via PACKAGES_DOTNET
- Installs Power Platform Tools VS Code extension
- Prerequisites: .NET SDK, x64 (AMD64) architecture only
- ARM64 detection with clear error message
- Comprehensive documentation about Linux devcontainer capabilities
- Script version: 0.0.3
- Category: CLOUD_TOOLS

Implementation notes:
- Created new PACKAGES_DOTNET infrastructure (lib/core-install-dotnet.sh)
- Power Platform CLI only supports x64 on Linux (not ARM64)
- 80-90% of Power Platform development works in Linux devcontainer
- Windows-only tools (PRT, CMT, pac data) clearly documented

## Azure Tools ✅ COMPLETED

✅ Created three install scripts based on user profiles:

**1. install-tool-azure-ops.sh** - Azure Operations & Infrastructure Management
- PowerShell 7.5.4 runtime + Az/Graph/Exchange modules
- Azure CLI
- VS Code: PowerShell, Azure Tools pack, Bicep, Azure Policy, Kusto
- Script version: 0.0.1
- Category: CLOUD_TOOLS
- Target: Azure ops/infrastructure teams
- Replaced: install-tool-powershell.sh (deleted)

**2. install-tool-azure-dev.sh** - Azure Application Development
- Azure CLI, Functions Core Tools v4, Azurite
- VS Code: Azure Account, Resources, App Service, Functions, Storage, Service Bus Explorer, Cosmos DB, Bicep
- Script version: 0.0.1
- Category: CLOUD_TOOLS
- Target: Azure application developers
- Replaced: install-tool-azure.sh (deleted)

**3. install-tool-api-dev.sh** - API Development Tools
- VS Code: Thunder Client, OpenAPI Editor
- Script version: 0.0.1
- Category: CLOUD_TOOLS
- Target: General API developers (cloud-agnostic)

Implementation notes:
- Split original Azure/PowerShell scripts into three focused user profiles
- Fixed bug in lib/core-install-node.sh (npm hanging on packages with version specifiers like @4)
- All scripts tested and validated (install/uninstall working)
- Auto-enable/disable functionality working

See original discussion: https://claude.ai/share/e1b9f3ae-1902-4146-9abd-ec7d06dcaad3

## Documentation & Diagramming Tools

Potential `install-tool-documentation.sh` script for visual documentation and diagramming.

**Visual Diagram Tools:**
- **Draw.io Integration** (hediet.vscode-drawio)
  - Create/edit architecture diagrams, flowcharts, network diagrams
  - Saves as .drawio.svg or .drawio.png (version controllable)
  - Alternative to Visio/Lucidchart
  - https://marketplace.visualstudio.com/items?itemName=hediet.vscode-drawio

**Extended Mermaid Tools** (beyond base bierner.markdown-mermaid):
- **Mermaid Chart** (MermaidChart.vscode-mermaid-chart)
  - Official Mermaid editor with live preview
  - https://marketplace.visualstudio.com/items?itemName=MermaidChart.vscode-mermaid-chart
- **Mermaid Preview** (vstirbu.vscode-mermaid-preview)
  - Standalone preview pane for .mmd files
  - https://marketplace.visualstudio.com/items?itemName=vstirbu.vscode-mermaid-preview

**Alternative Text-Based Diagrams:**
- **PlantUML** (jebbs.plantuml)
  - Text-based UML diagrams (sequence, class, component, etc.)
  - More powerful than Mermaid for complex UML
  - https://marketplace.visualstudio.com/items?itemName=jebbs.plantuml
  - **Note:** Requires Java runtime and Graphviz (system packages)


**Technical Documentation:**
- **AsciiDoc** (asciidoctor.asciidoctor-vscode)
  - Alternative to Markdown for complex technical docs
  - Better for books, technical manuals, multi-file docs
  - https://marketplace.visualstudio.com/items?itemName=asciidoctor.asciidoctor-vscode

**Recommendation for MVP:**
Keep it simple with just Draw.io - most universal and works standalone.
Other tools can be added if needed, or users install manually.


## API developer tool ✅ COMPLETED

✅ Created install-tool-api-dev.sh (part of Azure Tools reorganization)
- Thunder Client (rangav.vscode-thunder-client) - Lightweight REST API client
- OpenAPI Editor (42crunch.vscode-openapi) - OpenAPI/Swagger editing and validation
- Script version: 0.0.1
- Category: CLOUD_TOOLS
- Extensions-only script (no system/node packages)
- Target: General API developers (cloud-agnostic)

See Azure Tools section above for full context.
