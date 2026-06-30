# Quiesce the guest: disable background services, kill every sleep/idle timeout,
# shrink the disk footprint of this disposable 40GB VM. Backing registry values
# (NoAutoUpdate, HiberbootEnabled, ...) are applied in 04-Set-Registry.

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/Services.ps1>>

# --- Disable services + Windows Update scheduled tasks (only those not yet done) ---
foreach ($s in $ServicesToDisable) {
    if (Test-ServiceDisabled -Name $s) { continue }
    Write-Host "'$s': enabled (disabling)"
    Disable-ServiceHard -Name $s
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

# --- Never sleep: kill all sleep/hibernate/idle timeouts ---
powercfg /h off
powercfg /setactive SCHEME_MIN
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0

# --- Disk footprint: keep this disposable 40GB VM from growing ---
Disable-ComputerRestore -Drive "C:\"
vssadmin delete shadows /all /quiet
$cs = Get-WmiObject -Class Win32_ComputerSystem
if ($cs.AutomaticManagedPagefile) { $cs.AutomaticManagedPagefile = $false; $cs.Put() | Out-Null }
Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue | ForEach-Object { $_.Delete() }
Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{ Name = "C:\pagefile.sys"; InitialSize = 4096; MaximumSize = 4096 } | Out-Null
dism /online /Set-ReservedStorageState /State:Disabled
Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue
wevtutil sl Application /ms:20971520
wevtutil sl System /ms:20971520
wevtutil sl Security /ms:20971520 2>$null
Remove-Item "C:\Windows\Web\Wallpaper\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Web\4K\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Services quiesced, sleep disabled, disk footprint trimmed."
