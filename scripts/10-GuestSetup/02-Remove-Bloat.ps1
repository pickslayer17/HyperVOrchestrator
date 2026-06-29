# Strip everything we don't need: UWP bloat, Store, Widgets, OneDrive, Defender,
# Internet Explorer. Defender removal is HARD (must succeed). Paint/Photos kept.
# Backing registry value (OneDrive policy) is applied in 03-Set-Registry.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptData/AppsToRemove.ps1>>

# --- UWP apps + Store + Widgets ---
foreach ($app in $AppsToRemove) { Remove-AppxByWildcard -Match $app }

# --- OneDrive: kill, uninstall, scrub ---
taskkill /f /im OneDrive.exe 2>$null
if (Test-Path "C:\Windows\SysWOW64\OneDriveSetup.exe") { Start-Process "C:\Windows\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait }
if (Test-Path "C:\Windows\System32\OneDriveSetup.exe") { Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait }
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

# --- Optional features (Defender HARD via $ErrorActionPreference=Stop; IE tolerant) ---
foreach ($f in $FeaturesToRemove) {
    if ($f.Hard) {
        dism /online /Disable-Feature /FeatureName:$($f.Name) /Remove
    } else {
        dism /online /Disable-Feature /FeatureName:$($f.Name) /Remove 2>$null
    }
}

Write-Host "Bloat removed (UWP/Store/Widgets/OneDrive/Defender/IE)."
