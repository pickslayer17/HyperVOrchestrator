# Strip the UWP bloat (Store, Widgets, Xbox, Teams, ...) and OneDrive. Paint/Photos
# kept. Optional features (Defender/IE) live in 03-Remove-Features. OneDrive backing
# registry value is applied in 04-Set-Registry.
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

# --- OneDrive: kill + uninstall via its own setup. The OneDriveSetup.exe binary is
# owned by TrustedInstaller and cannot be deleted even as SYSTEM; it is harmless
# (nothing launches it once uninstalled), so we leave it and don't gate on it. ---
Write-Host "uninstalling OneDrive"
Stop-ProcessHard -ImageName OneDrive.exe
if (Test-Path "C:\Windows\SysWOW64\OneDriveSetup.exe") { Start-Process "C:\Windows\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait }
if (Test-Path "C:\Windows\System32\OneDriveSetup.exe") { Start-Process "C:\Windows\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait }
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Microsoft apps + OneDrive removed."
