$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestSingboxDir@@"
$vmUser   = "@@credentials.user@@"
$taskName = "SingBox"
$exePath  = Join-Path $guestDir "sing-box.exe"
$config   = Join-Path $guestDir "config.json"

$action = New-ScheduledTaskAction -Execute "conhost.exe" -Argument "--headless `"$exePath`" run -c `"$config`"" -WorkingDirectory $guestDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $vmUser
$principal = New-ScheduledTaskPrincipal -UserId $vmUser -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "scheduled task '$taskName' registered (at logon, user $vmUser, highest)."
