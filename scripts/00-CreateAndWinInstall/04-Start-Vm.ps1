# start vm + open vmconnect

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"

Write-Host "Starting VM..."
Start-VM -VMName $vmName
vmconnect localhost $vmName
Write-Host "Done. Windows should boot directly into setup (specialize + OOBE)."
