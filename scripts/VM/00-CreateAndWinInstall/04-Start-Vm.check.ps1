# vm must exist

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"

if (-not (Get-VM -Name $vmName -ErrorAction SilentlyContinue)) { Write-Host "VM '$vmName' not found (run 02-Create-Vm first)."; exit 1 }

Write-Host "VM exists."
exit 0
