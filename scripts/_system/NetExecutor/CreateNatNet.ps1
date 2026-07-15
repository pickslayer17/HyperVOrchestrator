param(
    [string]$NatName,
    [string]$SwitchName,
    [string]$HostIp,
    [int]$PrefixLength
)
$ErrorActionPreference = "Stop"

$octets = $HostIp.Split('.')
$subnetPrefix = "$($octets[0]).$($octets[1]).$($octets[2]).0/$PrefixLength"

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
}

$ifIndex = (Get-NetAdapter -Name "vEthernet ($SwitchName)").ifIndex
if (-not (Get-NetIPAddress -InterfaceIndex $ifIndex -IPAddress $HostIp -ErrorAction SilentlyContinue)) {
    New-NetIPAddress -IPAddress $HostIp -PrefixLength $PrefixLength -InterfaceIndex $ifIndex | Out-Null
}

if (-not (Get-NetNat -Name $NatName -ErrorAction SilentlyContinue)) {
    New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $subnetPrefix | Out-Null
}
