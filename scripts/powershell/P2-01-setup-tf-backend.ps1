#Requires -Modules Az.Storage, Az.Resources
<#
.SYNOPSIS
    Create and configure the Terraform remote state backend on Azure Storage.
.DESCRIPTION
    Creates a GRS storage account with soft-delete, blob versioning, and a
    CanNotDelete resource lock. Outputs the backend.tf block ready to paste.
.EXAMPLE
    .\P2-01-setup-tf-backend.ps1 `
        -ResourceGroupName  "rg-tfstate-prod" `
        -Location           "uksouth" `
        -StorageAccountName "stmigrationtfstate01" `
        -SubscriptionId     "00000000-0000-0000-0000-000000000000"
#>
param(
    [string]$ResourceGroupName  = 'rg-tfstate-prod',
    [string]$Location           = 'uksouth',
    [Parameter(Mandatory)]
    [string]$StorageAccountName,
    [string]$ContainerName      = 'tfstate',
    [Parameter(Mandatory)]
    [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-AzContext -SubscriptionId $SubscriptionId

New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null

$sa = New-AzStorageAccount -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName -Location $Location `
    -SkuName 'Standard_GRS' -Kind 'StorageV2' `
    -AllowBlobPublicAccess $false `
    -MinimumTlsVersion 'TLS1_2' `
    -EnableHttpsTrafficOnly $true

Enable-AzStorageBlobDeleteRetentionPolicy `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName -RetentionDays 30

New-AzStorageContainer -Name $ContainerName -Context $sa.Context -Permission Off | Out-Null

New-AzResourceLock -LockName 'tfstate-protect' -LockLevel CanNotDelete `
    -ResourceGroupName $ResourceGroupName -Force | Out-Null

Write-Host @"

Terraform backend ready.

Add the following to your backend.tf:

terraform {
  backend "azurerm" {
    resource_group_name  = "$ResourceGroupName"
    storage_account_name = "$StorageAccountName"
    container_name       = "$ContainerName"
    key                  = "<workload-name>.tfstate"
  }
}

Storage account: $StorageAccountName
Container: $ContainerName
Redundancy: GRS
Soft-delete: 30 days
Resource lock: CanNotDelete

"@ -ForegroundColor Green
