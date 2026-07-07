$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$vmIp = "@@state.vm.ip@@"

if (-not $vmIp) { return }

$machineNames = & python "$serverScript" GetMachineNames 2>$null
if ($LASTEXITCODE -ne 0) { return }
if ($machineNames -notcontains $vmIp) { return }

& python "$serverScript" Get-MachineHostForwardPort -vmip $vmIp
