$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Get-Process -Name "Agent.Listener" -ErrorAction SilentlyContinue) {
    Write-Host "agent already running."
    exit 2
}
Write-Host "agent not running."
exit 0
