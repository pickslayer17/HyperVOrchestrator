$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$agentDir = "@@agent.dir@@"
$marker = Join-Path $agentDir ".agent"
$service = Get-Service -Name "vstsagent.*" -ErrorAction SilentlyContinue

if ((Test-Path $marker) -and $service) {
    Write-Host "agent already configured as service: $agentDir"
    exit 2
}
Write-Host "agent not configured."
exit 0
