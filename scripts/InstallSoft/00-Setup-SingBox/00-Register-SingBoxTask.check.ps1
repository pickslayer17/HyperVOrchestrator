$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Get-ScheduledTask -TaskName "SingBox" -ErrorAction SilentlyContinue) {
    Write-Host "scheduled task 'SingBox' already registered."
    exit 2
}
Write-Host "scheduled task 'SingBox' not registered."
exit 0
