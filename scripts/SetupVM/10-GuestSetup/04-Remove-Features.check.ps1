# exit 2 = every HARD feature removed ; exit 0 = work to do (IE tolerant, not gating).

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/FeaturesToRemove.ps1>>

# Only list what is actually present (needs removal); count the rest.
$presentFeatures = [System.Collections.Generic.List[string]]::new()
$absentCount = 0
foreach ($feature in $FeaturesToRemove) {
    if (-not $feature.Hard) { continue }
    if (Test-FeatureRemoved -Name $feature.Name) { $absentCount++ } else { $presentFeatures.Add($feature.Name) }
}

if ($presentFeatures.Count -gt 0) {
    Write-Host "$absentCount absent, $($presentFeatures.Count) present (need removal):"
    $presentFeatures | ForEach-Object { Write-Host "  $_" }
    exit 0
}
Write-Host "already done: optional features removed."
exit 2
