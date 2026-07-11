# host: names of all NATs -> json array of strings
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$natNames = @(Get-NetNat -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
ConvertTo-Json @($natNames) -Depth 2
