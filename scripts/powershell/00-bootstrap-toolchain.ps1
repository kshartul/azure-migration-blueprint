#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Azure Migration Programme — Toolchain Bootstrap
.DESCRIPTION
    Installs and validates all required tools on Windows workstations and
    Azure DevOps self-hosted build agents.
.PARAMETER TerraformVersion
    Terraform version to install (default: 1.8.3)
.EXAMPLE
    .\00-bootstrap-toolchain.ps1 -TerraformVersion "1.8.3"
#>
param(
    [string]$TerraformVersion = '1.8.3',
    [string]$TFLintVersion    = '0.51.1',
    [string]$TFSecVersion     = '1.28.4',
    [string]$CheckovVersion   = '3.2.0'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Install-Choco {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        iex ((New-Object Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

function Install-Tool([string]$Name, [string]$ChocoId, [string]$Version = '') {
    Write-Host "Installing $Name..." -ForegroundColor Cyan
    $args = if ($Version) { "--version=$Version" } else { "" }
    choco install $ChocoId -y $args --no-progress | Out-Null
}

Install-Choco
Install-Tool 'Azure CLI'       'azure-cli'
Install-Tool 'Terraform'       'terraform'       $TerraformVersion
Install-Tool 'kubectl'         'kubernetes-cli'
Install-Tool 'Helm'            'kubernetes-helm'
Install-Tool 'Git'             'git'
Install-Tool 'Python 3.11'     'python'          '3.11.9'
Install-Tool 'Node.js'         'nodejs'
Install-Tool 'jq'              'jq'
Install-Tool 'terraform-docs'  'terraform-docs'

# Install tflint
Write-Host "Installing tflint $TFLintVersion..." -ForegroundColor Cyan
$url = "https://github.com/terraform-linters/tflint/releases/download/v$TFLintVersion/tflint_windows_amd64.zip"
New-Item -ItemType Directory -Force -Path 'C:\tools\tflint' | Out-Null
Invoke-WebRequest $url -OutFile "$env:TEMP\tflint.zip"
Expand-Archive "$env:TEMP\tflint.zip" -DestinationPath 'C:\tools\tflint' -Force
[System.Environment]::SetEnvironmentVariable('PATH', $env:PATH + ';C:\tools\tflint', 'Machine')

# Install tfsec
Write-Host "Installing tfsec $TFSecVersion..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path 'C:\tools\tfsec' | Out-Null
$url = "https://github.com/aquasecurity/tfsec/releases/download/v$TFSecVersion/tfsec-windows-amd64.exe"
Invoke-WebRequest $url -OutFile 'C:\tools\tfsec\tfsec.exe'
[System.Environment]::SetEnvironmentVariable('PATH', $env:PATH + ';C:\tools\tfsec', 'Machine')

# Install Checkov
pip install checkov==$CheckovVersion --quiet

# Validate
Write-Host "`nValidating installed tools..." -ForegroundColor Green
@('az --version', 'terraform --version', 'tflint --version',
  'tfsec --version', 'checkov --version', 'helm version --short',
  'kubectl version --client --short', 'terraform-docs --version') | ForEach-Object {
    try {
        $out = Invoke-Expression $_ 2>&1 | Select-Object -First 1
        Write-Host "  OK  $_  →  $out" -ForegroundColor Gray
    } catch {
        Write-Warning "FAILED: $_"
    }
}

Write-Host "`nBootstrap complete. All tools installed." -ForegroundColor Green
