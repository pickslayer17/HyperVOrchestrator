$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$orgUrl   = "@@agent.orgUrl@@"
$pool     = "@@agent.pool@@"
$token    = "@@agent.token@@"
$agentDir = "@@agent.dir@@"

$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($pool))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?api-version=7.1"
$existingNames = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value.name

$baseName = "$env:COMPUTERNAME-desktop"
$maxNumber = 0
foreach ($name in $existingNames) {
    if ($name -match "^$([regex]::Escape($baseName))-(\d+)$") {
        $number = [int]$matches[1]
        if ($number -gt $maxNumber) { $maxNumber = $number }
    }
}
$agentName = "$baseName-$($maxNumber + 1)"

& "$agentDir\config.cmd" --unattended `
    --url $orgUrl `
    --auth pat --token $token `
    --pool $pool `
    --agent $agentName `
    --replace `
    --work "_work"
if ($LASTEXITCODE -ne 0) { throw "config.cmd failed (exit $LASTEXITCODE)" }

Write-Host "agent '$agentName' configured -> $orgUrl (pool: $pool)"
