param(
	[string]$PoolName
)
$ErrorActionPreference = "Stop"

$orgUrl = "@@agent.orgUrl@@"
$token  = "@@agent.token@@"
$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($PoolName))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?api-version=7.1"
$agents = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value

$result = @($agents | ForEach-Object {
	[PSCustomObject]@{ Id = [int]$_.id; Name = "$($_.name)"; Running = [bool]$_.enabled; Online = ("$($_.status)" -eq "online") }
})
ConvertTo-Json @($result) -Depth 3
