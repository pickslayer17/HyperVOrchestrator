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
    $dismOutput = dism /online /Disable-Feature /FeatureName:$($feature.Name) /Remove 2>&1 | ForEach-Object { "$_" }
    $dismExitCode = $LASTEXITCODE
    if ($dismExitCode -notin @(0, 3010)) {
        if ($feature.Hard) {
            $dismOutput | ForEach-Object { Write-Host $_ }
            throw "DISM failed to remove '$($feature.Name)' with exit code $dismExitCode."
        }
        Write-Host "'$($feature.Name)': removal unsupported, skipped (exit $dismExitCode)"
    }
}

Write-Host "Optional features removed."
