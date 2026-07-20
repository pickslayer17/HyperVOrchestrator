$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$agentDir = "@@agent.dir@@"
$runCmd = Join-Path $agentDir "run.cmd"

if (-not (Test-Path $runCmd)) { throw "run.cmd not found: $runCmd (agent not configured?)" }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $runCmd
$psi.WorkingDirectory = $agentDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
[System.Diagnostics.Process]::Start($psi) | Out-Null

Start-Sleep -Seconds 3
$proc = Get-Process -Name "Agent.Listener" -ErrorAction SilentlyContinue
if (-not $proc) { throw "agent did not start (Agent.Listener not running)." }

Write-Host "agent started detached (pid $($proc.Id))."
