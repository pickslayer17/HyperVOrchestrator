# disable resource hogs + grant access, then reboot

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

Set-Service wuauserv -StartupType Disabled
sc.exe config wuauserv start= disabled
Stop-Service wuauserv -Force
reg add "HKLM\SOFTWARE\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
# Отключить планировщик обновлений
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" |
  Disable-ScheduledTask
Disable-ComputerRestore -Drive "C:\"
powercfg /h off
Set-Service WSearch -StartupType Disabled
Stop-Service WSearch -Force
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 4 /f
Set-Service SysMain -StartupType Disabled
Stop-Service SysMain -Force
schtasks /Change /TN "\Microsoft\Windows\Defrag\ScheduledDefrag" /Disable
Set-Service DiagTrack -StartupType Disabled
Stop-Service DiagTrack -Force
icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /Q
Write-Host "All done. Rebooting..."
Restart-Computer -Force
