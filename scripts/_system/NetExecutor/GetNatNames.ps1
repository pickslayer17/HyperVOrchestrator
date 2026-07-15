# host: names of all NATs -> json array of strings
$ErrorActionPreference = "Stop"

$natNames = @(Get-NetNat -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
ConvertTo-Json @($natNames) -Depth 2
