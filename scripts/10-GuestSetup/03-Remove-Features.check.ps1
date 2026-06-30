# exit 2 = every HARD feature removed ; exit 0 = work to do (IE tolerant, not gating).

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/FeaturesToRemove.ps1>>

# Collect a per-item report; print it only if there is work to do, otherwise one line.
$report = [System.Collections.Generic.List[string]]::new()
$needsWork = $false
foreach ($f in $FeaturesToRemove) {
    if (-not $f.Hard) { continue }
    if (Test-FeatureRemoved -Name $f.Name) {
        $report.Add("'$($f.Name)': absent")
    } else {
        $report.Add("'$($f.Name)': present (needs removal)")
        $needsWork = $true
    }
}

if ($needsWork) {
    $report | ForEach-Object { Write-Host $_ }
    return 0
}
Write-Host "already done: optional features removed."
return 2
