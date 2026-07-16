# Azure DevOps (vsts) self-hosted agent: download + extract + HEADLESS (unattended) config.
# Manual run for now (inside the VM):
#   .\Install-Agent.ps1 -OrgUrl https://dev.azure.com/YOURORG -Pool YOURPOOL -Token <PAT>
param(
    [Parameter(Mandatory)][string]$OrgUrl,
    [Parameter(Mandatory)][string]$Pool,
    [Parameter(Mandatory)][string]$Token,
    [string]$Version  = "5.275.0",
    [string]$AgentDir = "C:\agent",
    [string]$AgentName = $env:COMPUTERNAME
)
$ErrorActionPreference = "Stop"

$url = "https://download.agent.dev.azure.com/agent/$Version/vsts-agent-win-x64-$Version.zip"
$zip = Join-Path $AgentDir "agent.zip"

# download + extract (only if not already unpacked). VM reaches the CDN via the system proxy we set.
New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null
if (-not (Test-Path (Join-Path $AgentDir 'config.cmd'))) {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $AgentDir)
    Remove-Item $zip -Force
}

# headless config — all answers passed as flags, no prompts.
# no --runAsService on purpose: FlaUI needs an INTERACTIVE desktop, so the agent runs via run.cmd
# in the logged-in session, not as a Windows service.
& "$AgentDir\config.cmd" --unattended `
    --url $OrgUrl `
    --auth pat --token $Token `
    --pool $Pool `
    --agent $AgentName `
    --replace `
    --work "_work"
if ($LASTEXITCODE -ne 0) { throw "config.cmd failed (exit $LASTEXITCODE)" }

Write-Host "agent '$AgentName' configured -> $OrgUrl (pool: $Pool)"
Write-Host "start it with:  $AgentDir\run.cmd"
