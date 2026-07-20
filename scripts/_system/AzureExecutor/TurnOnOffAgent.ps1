param(
	[string]$AgentName,
	[string]$TurnOff
)
$ErrorActionPreference = "Stop"

$orgUrl = "@@agent.orgUrl@@"
$token  = "@@agent.token@@"
$pool   = "@@agent.pool@@"
$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$enabled = -not [System.Convert]::ToBoolean($TurnOff)

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($pool))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?api-version=7.1"
$agent = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value | Where-Object { $_.name -eq $AgentName } | Select-Object -First 1
if (-not $agent) { throw "agent not found: $AgentName" }

$patchUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents/$($agent.id)?api-version=7.1"
$body = @{ id = $agent.id; enabled = $enabled } | ConvertTo-Json
Invoke-RestMethod -Uri $patchUri -Headers $headers -Method Patch -ContentType "application/json" -Body $body | Out-Null

Write-Host "agent '$AgentName' enabled=$enabled"
