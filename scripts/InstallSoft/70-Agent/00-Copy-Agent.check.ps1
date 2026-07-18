$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$agentDir = "@@agent.dir@@"

if (Test-Path (Join-Path $agentDir 'config.cmd')) {
    Write-Host "agent binaries already extracted: $agentDir"
    exit 2
}
Write-Host "agent binaries not extracted."
exit 0
