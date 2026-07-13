param(
    [string]$Ip,
    [int]$Port
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" start_proxy -ip $Ip -port $Port
