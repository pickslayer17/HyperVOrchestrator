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
foreach ($s in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $s) { continue }
    Write-Host "'$s': enabled (disabling)"
    Disable-ServiceHard -Name $s
    Start-Sleep -Seconds 1
}
foreach ($r in $ServiceRegStart) {
    if (Test-RegValue -Path $r.Path -Name $r.Name -Value $r.Value) { continue }
    Write-Host "'$($r.Path)\$($r.Name)': missing (setting to $($r.Value))"
    Set-RegValue @r
}

# Start=4 only blocks the NEXT boot; a live wlms keeps running and will shut the VM
# down once more. Kill it now so there is no leftover shutdown.
Stop-Service wlms -Force -ErrorAction SilentlyContinue
Stop-ProcessHard -ImageName wlms.exe
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask -ErrorAction SilentlyContinue
schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable

# --- No hibernation ---
powercfg /h off
powercfg /setactive SCHEME_MIN

Write-Host "Services disabled, WU/defrag tasks off, wlms killed."
