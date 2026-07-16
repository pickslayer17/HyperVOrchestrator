$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/AppsToRemove.ps1>>

# smoke: the tooling we rely on must be present
if (-not (Get-Command Get-AppxProvisionedPackage -ErrorAction SilentlyContinue)) {
    Write-Host "smoke fail: Appx provisioning cmdlets unavailable."
    exit 1
}

# Only list what is actually present (needs removal); count the rest.
$presentApps = [System.Collections.Generic.List[string]]::new()
$absentCount = 0

foreach ($app in $AppsToRemove) {
    if (Test-AppxAbsent -Match $app) { $absentCount++ } else { $presentApps.Add($app) }
}

if ($presentApps.Count -gt 0) {
    Write-Host "$absentCount absent, $($presentApps.Count) present (need removal):"
    $presentApps | ForEach-Object { Write-Host "  $_" }
    exit 0
}
Write-Host "already done: apps removed."
exit 2
