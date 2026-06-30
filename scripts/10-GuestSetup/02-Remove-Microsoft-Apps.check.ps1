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

# Collect a per-item report; print it only if there is work to do, otherwise one line.
$report = [System.Collections.Generic.List[string]]::new()
$needsWork = $false

foreach ($app in $AppsToRemove) {
    if (Test-AppxAbsent -Match $app) {
        $report.Add("'$app': absent")
    } else {
        $report.Add("'$app': present (needs removal)")
        $needsWork = $true
    }
}

# OneDrive done = user install folder gone. The OneDriveSetup.exe binary stays
# (TrustedInstaller-owned, undeletable, harmless) so we do NOT gate on it.
if (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive") {
    $report.Add("'OneDrive': installed (needs removal)")
    $needsWork = $true
} else {
    $report.Add("'OneDrive': removed")
}

if ($needsWork) {
    $report | ForEach-Object { Write-Host $_ }
    return 0
}
Write-Host "already done: apps + OneDrive removed."
return 2
