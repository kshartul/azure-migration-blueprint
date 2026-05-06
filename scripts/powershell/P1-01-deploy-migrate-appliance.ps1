#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Deploy Azure Migrate project and register required resource providers.
.DESCRIPTION
    Creates the resource group, Azure Migrate project, and registers all
    required Azure resource providers for discovery and assessment.
.EXAMPLE
    .\P1-01-deploy-migrate-appliance.ps1 `
        -ResourceGroupName "rg-migrate-prod" `
        -ProjectName       "migration-project-01" `
        -Location          "uksouth" `
        -SubscriptionId    "00000000-0000-0000-0000-000000000000"
#>
param(
    [Parameter(Mandatory)] [string]$ResourceGroupName,
    [Parameter(Mandatory)] [string]$ProjectName,
    [Parameter(Mandatory)] [string]$Location,
    [Parameter(Mandatory)] [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Connect-AzAccount -TenantId $env:ARM_TENANT_ID
Set-AzContext -SubscriptionId $SubscriptionId

# Create resource group
Write-Host "Ensuring resource group: $ResourceGroupName" -ForegroundColor Cyan
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null

# Register resource providers
$providers = @(
    'Microsoft.Migrate',
    'Microsoft.OffAzure',
    'Microsoft.DataMigration',
    'Microsoft.HybridCompute'
)
$providers | ForEach-Object {
    Write-Host "  Registering: $_" -ForegroundColor Gray
    Register-AzResourceProvider -ProviderNamespace $_ | Out-Null
}

# Create Azure Migrate project
$apiVersion = "2023-06-06"
$resourceId  = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName" +
               "/providers/Microsoft.Migrate/MigrateProjects/$ProjectName"

Write-Host "Creating Azure Migrate project: $ProjectName" -ForegroundColor Cyan
New-AzResource -ResourceId $resourceId -ApiVersion $apiVersion `
    -Properties @{} -Location $Location -Force | Out-Null

Write-Host @"

Azure Migrate project created successfully.
Resource ID: $resourceId

Next steps:
  1. Download the OVA appliance from the Azure Migrate portal
  2. Deploy OVA to your VMware/Hyper-V environment
  3. Register the appliance using the key from the portal
  4. Start discovery — allow 30 days for dependency mapping

"@ -ForegroundColor Green
