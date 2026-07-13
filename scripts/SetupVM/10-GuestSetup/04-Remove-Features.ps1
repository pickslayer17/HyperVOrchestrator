# Remove optional Windows features via DISM (Defender HARD, IE tolerant). Runs as the
# normal admin user, NOT under SYSTEM: DISM /Disable-Feature fails with Access denied
# from a SYSTEM scheduled task, but succeeds under the interactive admin context.
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/FeaturesToRemove.ps1>>

foreach ($feature in $FeaturesToRemove) {
    if (Test-FeatureRemoved -Name $feature.Name) { continue }
    Write-Host "'$($feature.Name)': present (removing)"
    if ($feature.Hard) {
        dism /online /Disable-Feature /FeatureName:$($feature.Name) /Remove
    } else {
        dism /online /Disable-Feature /FeatureName:$($feature.Name) /Remove 2>$null
    }
}

Write-Host "Optional features removed."
