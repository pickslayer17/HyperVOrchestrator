param(
	[string]$AgentName,
	[string]$CapabilityName,
	[string]$CapabilityValue
)
$ErrorActionPreference = "Stop"

$orgUrl = "@@agent.orgUrl@@"
$token  = "@@agent.token@@"
$pool   = "@@agent.pool@@"
$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($pool))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?includeCapabilities=true&api-version=7.1"
$agent = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value | Where-Object { $_.name -eq $AgentName } | Select-Object -First 1
if (-not $agent) { throw "agent not found: $AgentName" }

$caps = @{}
if ($agent.userCapabilities) {
	$agent.userCapabilities.PSObject.Properties | ForEach-Object { $caps[$_.Name] = $_.Value }
}
$caps[$CapabilityName] = $CapabilityValue

$capUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents/$($agent.id)/usercapabilities?api-version=7.1"

$body = $caps | ConvertTo-Json
Invoke-RestMethod -Uri $capUri -Headers $headers -Method Put -ContentType "application/json" -Body $body | Out-Null

Write-Host "agent '$AgentName' user capability set: $CapabilityName=$CapabilityValue"
