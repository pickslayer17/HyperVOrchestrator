$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$machineNames = & python "$serverScript" get_machine_names 2>$null
if ($LASTEXITCODE -ne 0) { "false 0"; return }
$count = @($machineNames | Where-Object { $_ -ne "" }).Count
"true $count"
