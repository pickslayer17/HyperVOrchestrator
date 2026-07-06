# exit 2 = all targeted apps + OneDrive gone ; exit 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/AppsToRemove.ps1>>

# smoke: the tooling we rely on must be present
if (-not (Get-Command Get-AppxProvisionedPackage -ErrorAction SilentlyContinue)) {
    Write-Host "smoke fail: Appx provisioning cmdlets unavailable."
    return 1
}

# Only list what is actually present (needs removal); count the rest.
$presentApps = [System.Collections.Generic.List[string]]::new()
$absentCount = 0

foreach ($app in $AppsToRemove) {
    if (Test-AppxAbsent -Match $app) { $absentCount++ } else { $presentApps.Add($app) }
}

# OneDrive done = user install folder gone. The OneDriveSetup.exe binary stays
# (TrustedInstaller-owned, undeletable, harmless) so we do NOT gate on it.
if (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive") { $presentApps.Add("OneDrive") } else { $absentCount++ }

if ($presentApps.Count -gt 0) {
    Write-Host "$absentCount absent, $($presentApps.Count) present (need removal):"
    $presentApps | ForEach-Object { Write-Host "  $_" }
    return 0
}
Write-Host "already done: apps + OneDrive removed."
return 2
