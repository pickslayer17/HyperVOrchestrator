# Disable background services + Windows Update/defrag tasks, kill the wlms shutdown,
# and stop hibernation. Disk-footprint trimming and sleep timeouts live in
# 02-Trim-Footprint. Backing registry values are applied in 05-Set-Registry.

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/Services.ps1>>

# --- Disable services (only those not yet done) ---
# A burst of back-to-back Stop-Service calls under the SYSTEM task drops the PSDirect
# VMBus socket ("Hyper-V socket target process has ended"). A short pause after each
# stop lets the channel settle; individually/spaced they are fine.
foreach ($service in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $service) { continue }
    Write-Host "'$service': enabled (disabling)"
    Disable-ServiceHard -Name $service
    Start-Sleep -Seconds 1
}
foreach ($registryEntry in $ServiceRegStart) {
    if (Test-RegValue -Path $registryEntry.Path -Name $registryEntry.Name -Value $registryEntry.Value) { continue }
    Write-Host "'$($registryEntry.Path)\$($registryEntry.Name)': missing (setting to $($registryEntry.Value))"
    Set-RegValue @registryEntry
}

# wlms is disabled via registry Start=4 above (won't start after the next reboot).
# We do NOT kill the live process: wlms.exe is a CRITICAL process on eval Windows, so
# taskkill /f triggers a 0xEF CRITICAL_PROCESS_DIED bugcheck. A live wlms may fire one
# last shutdown before the reboot, which is far better than a BSOD loop.
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue |
    Disable-ScheduledTask -ErrorAction SilentlyContinue

# --- No hibernation ---
powercfg /h off
powercfg /setactive SCHEME_MIN

Write-Host "Services disabled, WU/defrag tasks off, wlms killed."
