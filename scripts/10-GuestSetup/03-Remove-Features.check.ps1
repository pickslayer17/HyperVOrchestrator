# exit 2 = every HARD feature removed ; exit 0 = work to do (IE tolerant, not gating).

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/FeaturesToRemove.ps1>>

# Only list what is actually present (needs removal); count the rest.
$present = [System.Collections.Generic.List[string]]::new()
$absentCount = 0
foreach ($f in $FeaturesToRemove) {
    if (-not $f.Hard) { continue }
    if (Test-FeatureRemoved -Name $f.Name) { $absentCount++ } else { $present.Add($f.Name) }
}

if ($present.Count -gt 0) {
    Write-Host "$absentCount absent, $($present.Count) present (need removal):"
    $present | ForEach-Object { Write-Host "  $_" }
    return 0
}
Write-Host "already done: optional features removed."
return 2
