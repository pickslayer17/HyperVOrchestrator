# vm must exist and be off

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) { Write-Host "VM '$vmName' not found (run 02-Create-Vm first)."; exit 1 }
if ($vm.State -ne 'Off') { Write-Host "VM '$vmName' is $($vm.State) — must be Off."; exit 1 }

Write-Host "VM exists and is Off."
exit 0
