$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Get-ScheduledTask -TaskName "Agent" -ErrorAction SilentlyContinue) {
    Write-Host "scheduled task 'Agent' already registered."
    exit 2
}
Write-Host "scheduled task 'Agent' not registered."
exit 0
