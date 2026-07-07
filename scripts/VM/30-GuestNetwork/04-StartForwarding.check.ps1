$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$vmIp = "@@state.vm.ip@@"

$machineNames = & python "$serverScript" get_machine_names 2>$null
if ($LASTEXITCODE -ne 0) { Write-Host "proxy server not running (run 03-StartProxy first)."; exit 1 }
if ($machineNames -contains $vmIp) { Write-Host "$vmIp already registered."; exit 2 }
Write-Host "$vmIp not registered."
exit 0
