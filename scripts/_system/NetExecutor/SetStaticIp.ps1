param(
    [string]$Alias,
    [string]$Ip,
    [string]$Gateway,
    [int]$PrefixLength,
    [string]$Dns
)
$ErrorActionPreference = "Stop"

# On the host our NAT adapter has a deterministic name from config: "vEthernet (<switchName>)".
# Target it by that exact name. In the guest that name does not exist, so fall back to the VM's
# single NIC. A target miss onto the host then lands on vEthernet (NATSwitch), never the real NIC.
$adapter = Get-NetAdapter -Name "vEthernet (@@network.switchName@@)" -ErrorAction SilentlyContinue
if (-not $adapter) {
    $adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
}
if (-not $adapter) { throw "No target network adapter found; refusing to configure any interface." }
$Alias = $adapter.Name

Remove-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv4 -Dhcp Disabled
New-NetIPAddress -InterfaceAlias $Alias -IPAddress $Ip -PrefixLength $PrefixLength -DefaultGateway $Gateway | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $Alias -ServerAddresses $Dns
