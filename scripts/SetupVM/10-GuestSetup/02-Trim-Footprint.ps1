# Kill all sleep/idle timeouts and shrink the disk footprint of this disposable 40GB
# VM (no restore points, no shadow copies, fixed page file, no reserved storage,
# trimmed event logs, no stock wallpapers). Split out of 01-Disable-Services so the
# service-stop burst and this disk work don't share one SYSTEM task.

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

<<inject::scriptHelpers/SystemHelpers.ps1>>

# --- Never sleep: kill all sleep/hibernate/idle timeouts ---
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0

# --- Disk footprint: keep this disposable 40GB VM from growing ---
Disable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
if (Get-CimInstance Win32_ShadowCopy -ErrorAction SilentlyContinue) {
	vssadmin delete shadows /all /quiet 2>$null | Out-Null
}
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
if ($computerSystem.AutomaticManagedPagefile) { $computerSystem.AutomaticManagedPagefile = $false; $computerSystem.Put() | Out-Null }
Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue | ForEach-Object { $_.Delete() }
Set-WmiInstance -Class Win32_PageFileSetting -Arguments @{ Name = "C:\pagefile.sys"; InitialSize = 4096; MaximumSize = 4096 } | Out-Null
$dismOutput = dism /online /Set-ReservedStorageState /State:Disabled 2>&1 | ForEach-Object { "$_" }
$dismExitCode = $LASTEXITCODE
if ($dismExitCode -notin @(0, 3010)) {
	$dismOutput | ForEach-Object { Write-Host $_ }
	throw "DISM failed to disable reserved storage with exit code $dismExitCode."
}
if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
	Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue
}
Remove-Item "C:\Windows\SoftwareDistribution\DeliveryOptimization\*" -Recurse -Force -ErrorAction SilentlyContinue
wevtutil sl Application /ms:20971520 2>$null | Out-Null
wevtutil sl System /ms:20971520 2>$null | Out-Null
wevtutil sl Security /ms:20971520 2>$null | Out-Null
Remove-Item "C:\Windows\Web\Wallpaper\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Web\4K\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Sleep disabled, disk footprint trimmed."
