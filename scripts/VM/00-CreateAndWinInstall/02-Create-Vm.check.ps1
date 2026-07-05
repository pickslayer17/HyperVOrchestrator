# require built vhdx

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

if (-not (Test-Path $vhdPath)) { Write-Host "VHDX not found: $vhdPath (run 01-Build-Vhdx first)."; exit 1 }

Write-Host "VHDX present."
exit 0
