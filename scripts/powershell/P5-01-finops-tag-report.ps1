#Requires -Modules Az.Accounts, Az.Resources
<#
.SYNOPSIS
    Generate a weekly FinOps tag compliance report across all migration subscriptions.
.DESCRIPTION
    Scans all resources in specified subscriptions and reports on mandatory tag
    compliance. Outputs a CSV and prints a summary to the console.
.EXAMPLE
    .\P5-01-finops-tag-report.ps1 `
        -SubscriptionIds @("sub-id-1","sub-id-2") `
        -OutputPath "finops-tag-compliance-$(Get-Date -Format 'yyyyMMdd').csv"
#>
param(
    [Parameter(Mandatory)] [string[]]$SubscriptionIds,
    [string[]]$RequiredTags = @('Environment','WorkloadName','CostCentre','Owner','MigrationWave'),
    [string]$OutputPath     = "finops-tag-compliance.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$report = @()

foreach ($subId in $SubscriptionIds) {
    Set-AzContext -SubscriptionId $subId -ErrorAction Stop | Out-Null
    $sub       = Get-AzSubscription -SubscriptionId $subId
    $resources = Get-AzResource

    Write-Host "Processing $($resources.Count) resources in: $($sub.Name)" -ForegroundColor Cyan

    foreach ($res in $resources) {
        $tags    = $res.Tags ?? @{}
        $missing = $RequiredTags | Where-Object { -not $tags.ContainsKey($_) }
        $present = $RequiredTags | Where-Object { $tags.ContainsKey($_) }

        $report += [PSCustomObject]@{
            SubscriptionName = $sub.Name
            SubscriptionId   = $subId
            ResourceName     = $res.Name
            ResourceType     = $res.ResourceType
            ResourceGroup    = $res.ResourceGroupName
            Location         = $res.Location
            TagsPresent      = $present -join ', '
            TagsMissing      = $missing -join ', '
            MissingCount     = $missing.Count
            Compliant        = ($missing.Count -eq 0)
        }
    }
}

$report | Export-Csv $OutputPath -NoTypeInformation

$total     = $report.Count
$compliant = ($report | Where-Object Compliant).Count
$pct       = if ($total -gt 0) { [math]::Round($compliant / $total * 100, 1) } else { 0 }
$colour    = if ($pct -ge 90) { 'Green' } elseif ($pct -ge 70) { 'Yellow' } else { 'Red' }

Write-Host "`nTag Compliance Summary" -ForegroundColor White
Write-Host "  Total resources:  $total"
Write-Host "  Compliant:        $compliant ($pct%)" -ForegroundColor $colour
Write-Host "  Non-compliant:    $($total - $compliant)"
Write-Host "  Report saved:     $OutputPath" -ForegroundColor Green

# Top 10 most common missing tags
$report | Where-Object { -not $_.Compliant } |
    Select-Object -ExpandProperty TagsMissing |
    ForEach-Object { $_ -split ', ' } |
    Group-Object | Sort-Object Count -Descending |
    Select-Object -First 10 |
    ForEach-Object { Write-Host "  Missing '$($_.Name)': $($_.Count) resources" -ForegroundColor Yellow }
