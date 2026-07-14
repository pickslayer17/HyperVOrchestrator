param(
    [string]$SwitchName
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
Connect-VMNetworkAdapter -VMName $vmName -SwitchName $SwitchName
