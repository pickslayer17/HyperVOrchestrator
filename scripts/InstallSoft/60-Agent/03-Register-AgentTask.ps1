$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$agentDir = "@@agent.dir@@"
$vmUser   = "@@credentials.user@@"
$taskName = "Agent"
$runCmd   = Join-Path $agentDir "run.cmd"

if (-not (Test-Path $runCmd)) { throw "run.cmd not found: $runCmd (agent not configured?)" }

$action = New-ScheduledTaskAction -Execute $runCmd -WorkingDirectory $agentDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $vmUser
$principal = New-ScheduledTaskPrincipal -UserId $vmUser -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "scheduled task '$taskName' registered (at logon, user $vmUser)."
