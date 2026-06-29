# exit 2 = all bloat gone (apps + hard features + OneDrive) ; exit 0 = work to do.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject:scriptHelpers/SystemHelpers.ps1>>
<<inject:scriptData/AppsToRemove.ps1>>

# smoke: the tooling we rely on must be present
if (-not (Get-Command Get-AppxProvisionedPackage -ErrorAction SilentlyContinue)) {
    Write-Host "smoke fail: Appx provisioning cmdlets unavailable."
    return 1
}

# done? every targeted app absent (installed-for-any-user is the signal)
foreach ($app in $AppsToRemove) {
    if (-not (Test-AppxAbsent -Match $app)) { Write-Host "todo: app still present: $app"; return 0 }
}

# done? every HARD feature removed (IE tolerant — not gating)
foreach ($f in $FeaturesToRemove) {
    if ($f.Hard -and -not (Test-FeatureRemoved -Name $f.Name)) {
        Write-Host "todo: feature still present: $($f.Name)"; return 0
    }
}

# done? OneDrive setup binaries gone
if ((Test-Path "C:\Windows\System32\OneDriveSetup.exe") -or (Test-Path "C:\Windows\SysWOW64\OneDriveSetup.exe")) {
    Write-Host "todo: OneDrive still present."; return 0
}

Write-Host "already done: apps/features/OneDrive removed."
return 2
