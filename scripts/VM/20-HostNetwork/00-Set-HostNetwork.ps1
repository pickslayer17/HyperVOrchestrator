# create nat switch + nat, connect vm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"
$hostIp     = "@@state.host.natIp@@"
$prefix     = @@network.subnetPrefixLength@@
$vmName     = "@@vm.name@@"

$octets = $hostIp.Split('.')
$subnetPrefix = "$($octets[0]).$($octets[1]).$($octets[2]).0/$prefix"

# switch
$natSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (-not $natSwitch) {
    Write-Host "Creating $switchName..."
    New-VMSwitch -Name $switchName -SwitchType Internal
    $ifIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
    New-NetIPAddress -IPAddress $hostIp -PrefixLength $prefix -InterfaceIndex $ifIndex
    Write-Host "$switchName created with IP $hostIp"
} else {
    Write-Host "$switchName already exists."
    $ifIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
}

# nat
$nat = Get-NetNat -Name $natName -ErrorAction SilentlyContinue
if (-not $nat) {
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
