$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"

Write-Host "Restarting VM..."
Restart-VM -Name $vmName -Force
Write-Host "VM restart issued."
