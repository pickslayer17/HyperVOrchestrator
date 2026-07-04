# start vm + open vmconnect

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmHost = "@@vm.host@@"

Write-Host "Starting VM..."
Start-VM -VMName $vmName
#Start-Process vmconnect -ArgumentList $vmHost, $vmName
Write-Host "Done. Windows should boot directly into Desktop"
