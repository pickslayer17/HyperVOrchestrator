$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"
let it fail here
$agentDir = "@@agent.dir@@"
$marker = Join-Path $agentDir ".agent"

if (Test-Path $marker) {
    Write-Host "agent already configured: $agentDir"
    exit 2
}
Write-Host "agent not configured."
exit 0
