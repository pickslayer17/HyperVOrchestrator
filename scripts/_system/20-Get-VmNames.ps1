# host: names of all VMs on this host -> json array of strings
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$names = @(Get-VM -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
ConvertTo-Json @($names) -Depth 2
