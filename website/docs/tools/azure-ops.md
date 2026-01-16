---
title: Azure Operations & Infrastructure
sidebar_position: 6
---

# Azure Operations & Infrastructure Management

Comprehensive Azure operations toolkit with Azure CLI, PowerShell, and VS Code extensions for managing Azure resources, infrastructure as code, and policy management.

## What Gets Installed

### CLI Tools

| Tool | Description |
|------|-------------|
| Azure CLI | Command-line interface for Azure resource management |
| PowerShell 7 | Cross-platform automation and scripting |

### PowerShell Modules

| Module | Description |
|--------|-------------|
| Az | Azure cloud automation (Resource Manager, Storage, Compute, etc.) |
| Microsoft.Graph | Microsoft 365 and Graph API automation |
| ExchangeOnlineManagement | Exchange Online management |
| PSScriptAnalyzer | PowerShell script analysis and linting |

### VS Code Extensions

| Extension | Description |
|-----------|-------------|
| PowerShell | PowerShell language support and debugging |
| Azure Tools | Complete Azure development toolkit |
| Azure Account | Azure subscription management and sign-in |
| Azure Resources | View and manage Azure resources |
| Bicep | Bicep language support for Infrastructure as Code |
| Azure Policy | View and manage Azure Policy definitions |
| Kusto Syntax Highlighting | KQL syntax highlighting for log queries |

## Installation

Install via the interactive menu:

```bash
dev-setup
```

Or install directly:

```bash
.devcontainer/additions/install-tool-azure-ops.sh
```

To uninstall:

```bash
.devcontainer/additions/install-tool-azure-ops.sh --uninstall
```

## Azure CLI

### Getting Started

```bash
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set active subscription
az account set --subscription "My Subscription"

# List resource groups
az group list --output table
```

### Common Operations

```bash
# List virtual machines
az vm list --output table

# List storage accounts
az storage account list --output table

# Get resource details
az resource show --ids /subscriptions/.../resourceGroups/.../providers/...

# Create a resource group
az group create --name myResourceGroup --location eastus
```

## PowerShell with Az Module

### Getting Started

```bash
# Launch PowerShell
pwsh
```

```powershell
# Import Az module
Import-Module Az

# Connect to Azure
Connect-AzAccount

# List subscriptions
Get-AzSubscription

# Set active subscription
Set-AzContext -Subscription "My Subscription"
```

### Common Operations

```powershell
# List resource groups
Get-AzResourceGroup

# List VMs
Get-AzVM

# Get VM details
Get-AzVM -ResourceGroupName "myRG" -Name "myVM"

# Start/Stop VM
Start-AzVM -ResourceGroupName "myRG" -Name "myVM"
Stop-AzVM -ResourceGroupName "myRG" -Name "myVM"
```

## Infrastructure as Code with Bicep

Bicep is Microsoft's domain-specific language for deploying Azure resources.

### Example Bicep File

```bicep
// main.bicep
param location string = resourceGroup().location
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output storageAccountId string = storageAccount.id
```

### Deploy Bicep

```bash
# Deploy to a resource group
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters storageAccountName=mystorageaccount

# What-if deployment (preview changes)
az deployment group what-if \
  --resource-group myResourceGroup \
  --template-file main.bicep

# Build to ARM JSON
az bicep build --file main.bicep
```

## Azure Policy

### Managing Policies

```bash
# List policy definitions
az policy definition list --output table

# List policy assignments
az policy assignment list --output table

# Create policy assignment
az policy assignment create \
  --name "require-tag" \
  --policy "/providers/Microsoft.Authorization/policyDefinitions/..." \
  --scope "/subscriptions/..."
```

## Log Analytics with KQL

Create `.kql` files for syntax highlighting in VS Code.

### Example KQL Query

```kql
// Find failed requests in the last hour
AzureDiagnostics
| where TimeGenerated > ago(1h)
| where ResultType == "Failed"
| summarize Count = count() by Resource, OperationName
| order by Count desc
```

Run KQL queries in the Azure Portal Log Analytics workspace.

## Example Workflows

### Setting Up a New Environment

```bash
# Login
az login

# Create resource group
az group create --name prod-rg --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group prod-rg \
  --template-file infrastructure/main.bicep
```

### Auditing Resources

```powershell
# Get all VMs and their sizes
Get-AzVM | Select-Object Name, ResourceGroupName, @{N='Size';E={$_.HardwareProfile.VmSize}}

# Find untagged resources
Get-AzResource | Where-Object { $_.Tags -eq $null }

# Export resource inventory
Get-AzResource | Export-Csv -Path resources.csv
```

### Managing Costs

```bash
# Get consumption summary
az consumption budget list --output table

# Get cost by resource group
az costmanagement query \
  --type ActualCost \
  --dataset-grouping name=ResourceGroup type=Dimension
```

## Troubleshooting

### Azure CLI Login Issues

```bash
# Clear cached credentials
az account clear

# Login with device code (for remote environments)
az login --use-device-code
```

### PowerShell Module Not Found

```powershell
# Reinstall module
Install-Module -Name Az -Force -AllowClobber

# Update modules
Update-Module -Name Az
```

### Bicep Compilation Errors

1. Check syntax in VS Code (Bicep extension highlights errors)
2. Validate the template:
   ```bash
   az bicep build --file main.bicep
   ```

## Documentation

- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [PowerShell Az Module](https://learn.microsoft.com/powershell/azure/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Policy](https://learn.microsoft.com/azure/governance/policy/)
- [KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)
- [Microsoft.Graph PowerShell](https://learn.microsoft.com/powershell/microsoftgraph/)
