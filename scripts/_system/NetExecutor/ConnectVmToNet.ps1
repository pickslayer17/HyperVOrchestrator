param(
    [string]$SwitchName
)
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
Connect-VMNetworkAdapter -VMName $vmName -SwitchName $SwitchName
