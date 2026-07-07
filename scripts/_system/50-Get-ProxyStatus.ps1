$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$machineNames = & python "$serverScript" GetMachineNames 2>$null
if ($LASTEXITCODE -ne 0) { "false 0"; return }
$count = @($machineNames | Where-Object { $_ -ne "" }).Count
"true $count"
