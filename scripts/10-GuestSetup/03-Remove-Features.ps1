# Remove optional Windows features via DISM (Defender HARD, IE tolerant). Runs as the
# normal admin user, NOT under SYSTEM: DISM /Disable-Feature fails with Access denied
# from a SYSTEM scheduled task, but succeeds under the interactive admin context.
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/FeaturesToRemove.ps1>>

foreach ($f in $FeaturesToRemove) {
    if (Test-FeatureRemoved -Name $f.Name) { continue }
    Write-Host "'$($f.Name)': present (removing)"
    if ($f.Hard) {
        dism /online /Disable-Feature /FeatureName:$($f.Name) /Remove
    } else {
        dism /online /Disable-Feature /FeatureName:$($f.Name) /Remove 2>$null
    }
}

Write-Host "Optional features removed."
