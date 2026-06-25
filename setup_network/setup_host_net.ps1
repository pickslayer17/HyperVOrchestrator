$ErrorActionPreference = "Stop"

# === NAT SWITCH ===
$natSwitch = Get-VMSwitch -Name "NATSwitch" -ErrorAction SilentlyContinue
if (-not $natSwitch) {
    Write-Host "Creating NATSwitch..."
    New-VMSwitch -Name "NATSwitch" -SwitchType Internal
    $ifIndex = (Get-NetAdapter -Name "vEthernet (NATSwitch)").ifIndex
    New-NetIPAddress -IPAddress 192.168.50.1 -PrefixLength 24 -InterfaceIndex $ifIndex
    Write-Host "NATSwitch created with IP 192.168.50.1"
} else {
    Write-Host "NATSwitch already exists."
}

# === NAT ===
$nat = Get-NetNat -Name "VMNat" -ErrorAction SilentlyContinue
if (-not $nat) {
    New-NetNat -Name "VMNat" -InternalIPInterfaceAddressPrefix "192.168.50.0/24"
    Write-Host "VMNat created."
} else {
    Write-Host "VMNat already exists."
}

# === CONNECT VM ===
$vmName = "TestRunner"
$adapter = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
if ($adapter -and $adapter.SwitchName -ne "NATSwitch") {
    Disconnect-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName "NATSwitch"
    Write-Host "VM connected to NATSwitch."
} elseif ($adapter.SwitchName -eq "NATSwitch") {
    Write-Host "VM already on NATSwitch."
} else {
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName "NATSwitch"
    Write-Host "VM connected to NATSwitch."
}

Write-Host "Host network ready. Now run setup_vm_network.ps1"
