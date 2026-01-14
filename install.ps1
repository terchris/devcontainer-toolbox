# install.ps1 - First-time install of devcontainer-toolbox
# Run with: irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex
# If blocked: powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/REPO/main/install.ps1 | iex"

$ErrorActionPreference = "Stop"

$repo = "TOOLBOX_REPO_PLACEHOLDER"
$url = "https://github.com/$repo/releases/download/latest/dev_containers.zip"
$tempZip = Join-Path $env:TEMP "dev_containers.zip"
$tempExtract = Join-Path $env:TEMP "dev_containers_extract"

Write-Host "Installing devcontainer-toolbox from $repo..."

# Download
Invoke-WebRequest -Uri $url -OutFile $tempZip

# Extract
if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force }
Expand-Archive -Path $tempZip -DestinationPath $tempExtract

# Check for existing .devcontainer
if (Test-Path ".devcontainer") {
    if (Test-Path ".devcontainer\.version") {
        Write-Host "Found existing devcontainer-toolbox installation."
        Write-Host "Use 'dev-update' inside the container to update instead."
        Remove-Item $tempZip -Force
        Remove-Item $tempExtract -Recurse -Force
        exit 1
    } else {
        Write-Host "Found existing .devcontainer without version info."
        Write-Host "This may be from an older installation or a different setup."
        Write-Host "Creating backup at .devcontainer.backup..."
        if (Test-Path ".devcontainer.backup") { Remove-Item ".devcontainer.backup" -Recurse -Force }
        Move-Item ".devcontainer" ".devcontainer.backup"
        Write-Host "Backup created."
    }
}

# Copy .devcontainer
Copy-Item -Path "$tempExtract\.devcontainer" -Destination "." -Recurse -Force

# Handle .devcontainer.extend
$extendBackedUp = $false
if (Test-Path ".devcontainer.extend") {
    Write-Host "Found existing .devcontainer.extend."
    Write-Host "Creating backup at .devcontainer.extend.backup..."
    if (Test-Path ".devcontainer.extend.backup") { Remove-Item ".devcontainer.extend.backup" -Recurse -Force }
    Move-Item ".devcontainer.extend" ".devcontainer.extend.backup"
    Write-Host "Backup created."
    $extendBackedUp = $true
}

# Copy fresh .devcontainer.extend
Copy-Item -Path "$tempExtract\.devcontainer.extend" -Destination "." -Recurse

# Cleanup
Remove-Item $tempZip -Force
Remove-Item $tempExtract -Recurse -Force

Write-Host ""
Write-Host "Installed devcontainer-toolbox!"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open this folder in VS Code"
Write-Host "  2. When prompted, click 'Reopen in Container'"
Write-Host "  3. Inside the container, run: dev-help (to see available commands)"
Write-Host "  4. Run: dev-update (to check for updates)"

if ($extendBackedUp) {
    Write-Host ""
    Write-Host "Note: Your previous .devcontainer.extend was backed up."
    Write-Host "Review .devcontainer.extend.backup and reconfigure as needed."
}
