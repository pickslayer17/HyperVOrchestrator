$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$orgUrl   = "@@agent.orgUrl@@"
$pool     = "@@agent.pool@@"
$token    = "@@agent.token@@"
$version  = "@@agent.version@@"
$agentDir = "@@agent.dir@@"
$addin    = "@@office.apps@@".Split(',')[0].Trim()

$headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token")) }

$poolUri = "$orgUrl/_apis/distributedtask/pools?poolName=$([uri]::EscapeDataString($pool))&api-version=7.1"
$poolId = (Invoke-RestMethod -Uri $poolUri -Headers $headers).value[0].id

$agentsUri = "$orgUrl/_apis/distributedtask/pools/$poolId/agents?api-version=7.1"
$existingNames = (Invoke-RestMethod -Uri $agentsUri -Headers $headers).value.name

$baseName = "$env:COMPUTERNAME-$addin-desktop"
$maxNumber = 0
foreach ($name in $existingNames) {
    if ($name -match "^$([regex]::Escape($baseName))-(\d+)$") {
        $number = [int]$matches[1]
        if ($number -gt $maxNumber) { $maxNumber = $number }
    }
}
$agentName = "$baseName-$($maxNumber + 1)"

$url = "https://download.agent.dev.azure.com/agent/$version/vsts-agent-win-x64-$version.zip"
$zip = Join-Path $agentDir "agent.zip"

New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
if (-not (Test-Path (Join-Path $agentDir 'config.cmd'))) {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $agentDir)
    Remove-Item $zip -Force
}

& "$agentDir\config.cmd" --unattended `
    --url $orgUrl `
    --auth pat --token $token `
    --pool $pool `
    --agent $agentName `
    --replace `
    --work "_work"
if ($LASTEXITCODE -ne 0) { throw "config.cmd failed (exit $LASTEXITCODE)" }

Write-Host "agent '$agentName' configured -> $orgUrl (pool: $pool)"
