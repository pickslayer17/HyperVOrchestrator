$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$switchName = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue |
              Select-Object -First 1 -ExpandProperty SwitchName
"$switchName"
