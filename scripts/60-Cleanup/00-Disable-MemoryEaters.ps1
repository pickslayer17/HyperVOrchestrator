$ScriptTarget = "VM"
# 00 - Отключить «пожирателей» ресурсов внутри ВМ: Windows Update, WSearch,
#      SysMain, DiagTrack, system restore, hibernate, scheduled defrag, DoSvc.
#      Выдать пользователю full access на C:\ и перезагрузить.
#
# Перенесено из after_setup/tunr_off_memory_eaters.ps1.
# $ScriptTarget = "VM" -> оркестратор заворачивает в Invoke-Command -VMName сам.
#
# !!! ВНИМАНИЕ: в конце делает Restart-Computer -Force. После этого шага ВМ
# перезагрузится — последующие VM-side шаги должны ждать.

$ErrorActionPreference = "Stop"

$vmUser = "@@credentials.user@@"

Set-Service wuauserv -StartupType Disabled
Stop-Service wuauserv -Force
reg add "HKLM\SOFTWARE\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
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
