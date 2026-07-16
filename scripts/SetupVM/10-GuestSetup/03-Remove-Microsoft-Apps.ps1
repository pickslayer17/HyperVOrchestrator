$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/AppsToRemove.ps1>>

# --- UWP apps + Store + Widgets (only touch those actually present) ---
foreach ($app in $AppsToRemove) {
    if (Test-AppxAbsent -Match $app) { continue }
    Write-Host "'$app': present (removing)"
    Remove-AppxByWildcard -Match $app
}

Write-Host "Microsoft apps removed."
