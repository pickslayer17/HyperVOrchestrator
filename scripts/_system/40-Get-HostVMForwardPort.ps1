$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$vmIp = "@@state.vm.ip@@"

if (-not $vmIp) { return }

$machineNames = & python "$serverScript" get_machine_names 2>$null
if ($LASTEXITCODE -ne 0) { return }
if ($machineNames -notcontains $vmIp) { return }

& python "$serverScript" get_host_vm_forward_port -vmip $vmIp
