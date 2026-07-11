# host: names of all VMs on this host -> json array of strings
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$vmNames = @(Get-VM -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
ConvertTo-Json @($vmNames) -Depth 2
