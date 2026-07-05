$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"

Write-Host "Restarting VM..."
Restart-VM -Name $vmName -Force
Write-Host "VM restart issued."
