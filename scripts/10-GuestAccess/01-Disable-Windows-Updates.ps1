$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

# Отключить автообновление (оставить возможность обновляться вручную)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
  -Name "NoAutoUpdate" -Value 1 -Type DWord -Force

# Отключить планировщик обновлений
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" |
  Disable-ScheduledTask

# Убедиться что служба WU не перезапускается автоматически
sc.exe config wuauserv start= disabled
Stop-Service wuauserv -Force
