param(
	[string]$AgentName
)
$ErrorActionPreference = "Stop"

$orgUrl = "@@agent.orgUrl@@"
$token  = "@@agent.token@@"
$pool   = "@@agent.pool@@"
$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($pool))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?api-version=7.1"
$agent = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value | Where-Object { $_.name -eq $AgentName } | Select-Object -First 1
if (-not $agent) { throw "agent not found: $AgentName" }

$deleteUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents/$($agent.id)?api-version=7.1"
Invoke-RestMethod -Uri $deleteUri -Headers $headers -Method Delete | Out-Null

Write-Host "agent removed: $AgentName (id $($agent.id))"
