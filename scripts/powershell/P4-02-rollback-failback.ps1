#Requires -Modules Az.RecoveryServices
<#
.SYNOPSIS
    Roll back a migration wave by failing back VMs to on-premises via ASR.
.DESCRIPTION
    Commits the failover, re-protects VMs to the source environment, and
    logs the rollback event to Azure Monitor / Log Analytics.
.EXAMPLE
    .\P4-02-rollback-failback.ps1 `
        -VaultName          "rsv-migration-prod-uks" `
        -VaultResourceGroup "rg-migration-prod" `
        -VMNames            @("vm-app01","vm-app02") `
        -RollbackReason     "Application health check failed after cutover"
#>
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [Parameter(Mandatory)] [string]$VaultResourceGroup,
    [Parameter(Mandatory)] [string[]]$VMNames,
    [Parameter(Mandatory)] [string]$RollbackReason
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== INITIATING ROLLBACK ===" -ForegroundColor Red
Write-Host "Timestamp: $([datetime]::UtcNow.ToString('o'))" -ForegroundColor Yellow
Write-Host "Reason:    $RollbackReason" -ForegroundColor Yellow
Write-Host "VMs:       $($VMNames -join ', ')" -ForegroundColor Yellow

$vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $VaultResourceGroup
Set-AzRecoveryServicesVaultContext -Vault $vault

foreach ($vmName in $VMNames) {
    Write-Host "`nRolling back: $vmName" -ForegroundColor Cyan
    $item = Get-AzRecoveryServicesAsrReplicationProtectedItem |
            Where-Object { $_.FriendlyName -eq $vmName }

    # Commit the failover (required before re-protect)
    Write-Host "  Committing failover..." -ForegroundColor Gray
    Start-AzRecoveryServicesAsrCommitFailoverJob -ReplicationProtectedItem $item | Out-Null
    Start-Sleep -Seconds 60

    # Re-protect to source (initiates replication back to on-prem)
    Write-Host "  Initiating re-protection to source..." -ForegroundColor Gray
    Update-AzRecoveryServicesAsrProtectionDirection `
        -ReplicationProtectedItem $item -Direction RecoveryToPrimary | Out-Null

    Write-Host "  $vmName: re-protection initiated." -ForegroundColor Green
}

# Log rollback event to Log Analytics (via Data Collector API)
if ($env:LOG_ANALYTICS_WORKSPACE_ID -and $env:LOG_ANALYTICS_SHARED_KEY) {
    $body = @{
        RollbackVMs   = $VMNames
        Reason        = $RollbackReason
        Timestamp     = [datetime]::UtcNow.ToString('o')
        InitiatedBy   = $env:BUILD_REQUESTEDFOREMAIL ?? 'manual'
    } | ConvertTo-Json

    $date    = [datetime]::UtcNow.ToString('r')
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $hmac    = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Convert]::FromBase64String($env:LOG_ANALYTICS_SHARED_KEY)
    $sig     = [Convert]::ToBase64String($hmac.ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes("POST`n$($bodyBytes.Length)`napplication/json`nx-ms-date:$date`n/api/logs")))

    Invoke-RestMethod `
        -Uri "https://$($env:LOG_ANALYTICS_WORKSPACE_ID).ods.opinsights.azure.com/api/logs?api-version=2016-04-01" `
        -Method Post -Body $body -ContentType 'application/json' `
        -Headers @{ 'Authorization' = "SharedKey $($env:LOG_ANALYTICS_WORKSPACE_ID):$sig"; 'x-ms-date' = $date; 'Log-Type' = 'MigrationRollback' }
    Write-Host "`nRollback event logged to Log Analytics." -ForegroundColor Gray
}

Write-Host "`nRollback initiated. Monitor ASR for re-protection completion (est. 30-60 min)." -ForegroundColor Yellow
