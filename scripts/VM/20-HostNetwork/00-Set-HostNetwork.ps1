# create nat switch + nat, connect vm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"
$hostIp     = "@@state.host.natIp@@"
$prefixLength = @@network.subnetPrefixLength@@
$vmName     = "@@state.vm.name@@"

$octets = $hostIp.Split('.')
$subnetPrefix = "$($octets[0]).$($octets[1]).$($octets[2]).0/$prefixLength"

# switch
$natSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (-not $natSwitch) {
    Write-Host "Creating $switchName..."
    New-VMSwitch -Name $switchName -SwitchType Internal
    $interfaceIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
    New-NetIPAddress -IPAddress $hostIp -PrefixLength $prefixLength -InterfaceIndex $interfaceIndex
    Write-Host "$switchName created with IP $hostIp"
} else {
    Write-Host "$switchName already exists."
    $interfaceIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
}

# nat
$natEntry = Get-NetNat -Name $natName -ErrorAction SilentlyContinue
if (-not $natEntry) {
    New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $subnetPrefix
    Write-Host "$natName created."
} else {
    Write-Host "$natName already exists."
}

# connect vm
$adapter = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
if ($adapter -and $adapter.SwitchName -ne $switchName) {
    Disconnect-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
    Write-Host "VM connected to $switchName."
} elseif ($adapter.SwitchName -eq $switchName) {
    Write-Host "VM already on $switchName."
} else {
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
    Write-Host "VM connected to $switchName."
}

Write-Host "Host network ready."
