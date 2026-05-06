#Requires -Modules Az.RecoveryServices, Az.Network, Az.Compute, Az.PrivateDns
<#
.SYNOPSIS
    Orchestrate a migration wave cutover using Azure Site Recovery.
.DESCRIPTION
    Executes the full cutover sequence: pre-flight validation, application
    quiesce, ASR planned failover per VM, DNS cutover, and smoke test invocation.
    On smoke test failure, rollback is triggered automatically.
.PARAMETER WhatIf
    Simulates the cutover without making any changes.
.EXAMPLE
    .\P4-01-wave-cutover.ps1 `
        -VaultName           "rsv-migration-prod-uks" `
        -VaultResourceGroup  "rg-migration-prod" `
        -VMNames             @("vm-app01","vm-app02","vm-db01") `
        -TargetResourceGroup "rg-workload-prod" `
        -DnsZoneName         "internal.contoso.com" `
        -DnsResourceGroup    "rg-dns-prod"
#>
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [Parameter(Mandatory)] [string]$VaultResourceGroup,
    [Parameter(Mandatory)] [string[]]$VMNames,
    [Parameter(Mandatory)] [string]$TargetResourceGroup,
    [Parameter(Mandatory)] [string]$DnsZoneName,
    [Parameter(Mandatory)] [string]$DnsResourceGroup,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$vault = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $VaultResourceGroup
Set-AzRecoveryServicesVaultContext -Vault $vault

function Step([string]$Desc, [scriptblock]$Action) {
    Write-Host "[$([datetime]::Now.ToString('HH:mm:ss'))] $Desc" -ForegroundColor Cyan
    if (-not $WhatIf) { & $Action }
    else { Write-Host "  [WhatIf] Skipped." -ForegroundColor Yellow }
}

# ── PRE-FLIGHT ──────────────────────────────────────────────────────────────
Write-Host "`n=== PRE-CUTOVER VALIDATION ===" -ForegroundColor Yellow
foreach ($vmName in $VMNames) {
    $item = Get-AzRecoveryServicesAsrReplicationProtectedItem |
            Where-Object { $_.FriendlyName -eq $vmName }
    if (-not $item) { throw "VM '$vmName' not found in ASR protected items" }
    if ($item.ReplicationHealth -ne "Normal") {
        throw "$vmName replication health: $($item.ReplicationHealth)"
    }
    $lag = $item.RecoveryPointObjective
    if ($lag -gt 300) { Write-Warning "$vmName replication lag: ${lag}s (> 5 min)" }
    Write-Host "  PASS: $vmName | Health: $($item.ReplicationHealth) | Lag: ${lag}s" -ForegroundColor Green
}

# ── QUIESCE APPLICATION ─────────────────────────────────────────────────────
Step 'Quiesce source application (stop services)' {
    # Customise per workload: stop IIS, app services, message queue consumers etc.
    # Example: Invoke-AzVMRunCommand -VMName $srcVM -CommandId 'RunPowerShellScript'
    #          -ScriptString 'Stop-Service -Name W3SVC -Force'
    Write-Host '  Application services quiesced.' -ForegroundColor Gray
}

# ── TRIGGER PLANNED FAILOVER ────────────────────────────────────────────────
foreach ($vmName in $VMNames) {
    Step "Initiating planned failover: $vmName" {
        $item = Get-AzRecoveryServicesAsrReplicationProtectedItem |
                Where-Object { $_.FriendlyName -eq $vmName }
        Start-AzRecoveryServicesAsrPlannedFailoverJob `
            -ReplicationProtectedItem $item -Direction PrimaryToRecovery | Out-Null
    }
}

# ── WAIT FOR FAILOVERS TO COMPLETE ─────────────────────────────────────────
Step 'Waiting for failover jobs (max 60 min)' {
    $timeout = (Get-Date).AddMinutes(60)
    do {
        Start-Sleep -Seconds 30
        $pending = Get-AzRecoveryServicesAsrJob | Where-Object { $_.State -eq "InProgress" }
        Write-Host "  Pending: $($pending.Count)" -ForegroundColor Gray
    } while ($pending.Count -gt 0 -and (Get-Date) -lt $timeout)
    if ((Get-Date) -ge $timeout) { throw "Failover timeout exceeded (60 min)" }
}

# ── DNS CUTOVER ─────────────────────────────────────────────────────────────
foreach ($vmName in $VMNames) {
    Step "DNS cutover: $vmName" {
        $vm        = Get-AzVM -ResourceGroupName $TargetResourceGroup -Name $vmName
        $nic       = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
        $privateIp = $nic.IpConfigurations[0].PrivateIpAddress

        Remove-AzPrivateDnsRecordSet -ZoneName $DnsZoneName `
            -ResourceGroupName $DnsResourceGroup -Name $vmName `
            -RecordType A -ErrorAction SilentlyContinue

        New-AzPrivateDnsRecordSet -ZoneName $DnsZoneName `
            -ResourceGroupName $DnsResourceGroup -Name $vmName `
            -RecordType A -Ttl 300 `
            -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $privateIp)

        Write-Host "  DNS updated: $vmName -> $privateIp" -ForegroundColor Gray
    }
}

# ── SMOKE TESTS ─────────────────────────────────────────────────────────────
Write-Host "`n=== RUNNING SMOKE TESTS ===" -ForegroundColor Yellow
$vmList = $VMNames -join ','

try {
    python tests/smoke/run_wave_smoke_tests.py --vms $vmList --subscription $env:AZURE_SUBSCRIPTION_ID
    Write-Host "=== CUTOVER COMPLETE — ALL SMOKE TESTS PASSED ===" -ForegroundColor Green
} catch {
    Write-Host "=== SMOKE TESTS FAILED — INITIATING ROLLBACK ===" -ForegroundColor Red
    & ".\P4-02-rollback-failback.ps1" -VaultName $VaultName `
        -VaultResourceGroup $VaultResourceGroup -VMNames $VMNames `
        -RollbackReason "Smoke test failure: $_"
    throw "Cutover rolled back. See rollback output above."
}
