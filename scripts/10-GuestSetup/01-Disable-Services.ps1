# Quiesce the guest: disable background services, kill every sleep/idle timeout,
# shrink the disk footprint of this disposable 40GB VM. Backing registry values
# (NoAutoUpdate, HiberbootEnabled, ...) are applied in 03-Set-Registry.

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>
<<inject::scriptHelpers/RegistryHelpers.ps1>>
<<inject::scriptData/Services.ps1>>

# --- Disable services + Windows Update scheduled tasks ---
foreach ($s in $ServicesToDisable) { Disable-ServiceHard -Name $s }
foreach ($r in $ServiceRegStart) { Set-RegValue @r }
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
