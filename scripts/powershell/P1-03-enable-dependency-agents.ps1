#Requires -Modules Az.Compute, Az.OperationalInsights
<#
.SYNOPSIS
    Install MMA and Dependency Agent on all VMs matching a resource group filter.
.DESCRIPTION
    Enables dependency analysis for Azure Migrate by deploying the Microsoft
    Monitoring Agent (MMA) and Dependency Agent extensions to all in-scope VMs.
.EXAMPLE
    .\P1-03-enable-dependency-agents.ps1 `
        -WorkspaceResourceId "/subscriptions/.../workspaces/law-migrate" `
        -ResourceGroupFilter "prod-" `
        -SubscriptionId "00000000-0000-0000-0000-000000000000"
#>
param(
    [Parameter(Mandatory)] [string]$WorkspaceResourceId,
    [Parameter(Mandatory)] [string]$ResourceGroupFilter,
    [Parameter(Mandatory)] [string]$SubscriptionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-AzContext -SubscriptionId $SubscriptionId

$workspace = Get-AzOperationalInsightsWorkspace |
    Where-Object { $_.ResourceId -eq $WorkspaceResourceId }
if (-not $workspace) { throw "Workspace not found: $WorkspaceResourceId" }

$workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey `
    -ResourceGroupName $workspace.ResourceGroupName `
    -Name $workspace.Name).PrimarySharedKey

$vms = Get-AzVM | Where-Object { $_.ResourceGroupName -like "*$ResourceGroupFilter*" }
Write-Host "Found $($vms.Count) VMs matching filter: $ResourceGroupFilter" -ForegroundColor Cyan

$results = @()
foreach ($vm in $vms) {
    Write-Host "  Processing: $($vm.Name)" -ForegroundColor Gray
    try {
        # Install MMA
        Set-AzVMExtension -VMName $vm.Name `
            -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location `
            -Name 'MicrosoftMonitoringAgent' `
            -Publisher 'Microsoft.EnterpriseCloud.Monitoring' `
            -ExtensionType 'MicrosoftMonitoringAgent' -TypeHandlerVersion '1.0' `
            -Settings @{ workspaceId = $workspace.CustomerId } `
            -ProtectedSettings @{ workspaceKey = $workspaceKey } -Force | Out-Null

        # Install Dependency Agent
        Set-AzVMExtension -VMName $vm.Name `
            -ResourceGroupName $vm.ResourceGroupName -Location $vm.Location `
            -Name 'DependencyAgentWindows' `
            -Publisher 'Microsoft.Azure.Monitoring.DependencyAgent' `
            -ExtensionType 'DependencyAgentWindows' -TypeHandlerVersion '9.10' `
            -Force | Out-Null

        $results += [PSCustomObject]@{ VM = $vm.Name; Status = "Success" }
    } catch {
        $results += [PSCustomObject]@{ VM = $vm.Name; Status = "Failed: $_" }
    }
}

$results | Export-Csv "dependency-agent-status.csv" -NoTypeInformation
$ok   = ($results | Where-Object Status -eq "Success").Count
$fail = ($results | Where-Object Status -ne "Success").Count
Write-Host "Complete: $ok succeeded, $fail failed. See dependency-agent-status.csv" -ForegroundColor Green
