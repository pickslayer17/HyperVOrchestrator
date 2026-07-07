$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" get_machine_names > $null 2>&1
if ($LASTEXITCODE -eq 0) { Write-Host "proxy server already running."; exit 2 }
Write-Host "proxy server not running."
exit 0
