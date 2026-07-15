# vm: guest nat interface -> json { isDynamic, alias, ip }
$ErrorActionPreference = "Stop"

$adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
$alias = if ($adapter) { $adapter.Name } else { "" }

$ip = ""
$isDynamic = $false
$prefixLength = 0
$gateway = ""
$dnsServers = @()
if ($adapter) {
    $ipObj = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
    if ($ipObj) {
        $ip = $ipObj.IPAddress
        $isDynamic = $ipObj.PrefixOrigin -eq 'Dhcp'
        $prefixLength = $ipObj.PrefixLength
    }
    $gateway = Get-NetRoute -InterfaceAlias $adapter.Name -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
               Sort-Object RouteMetric | Select-Object -First 1 -ExpandProperty NextHop
    $dnsServers = @(Get-DnsClientServerAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty ServerAddresses)
}

[pscustomobject]@{
    isDynamic = $isDynamic
    alias = "$alias"
    ip = "$ip"
    prefixLength = $prefixLength
    gateway = "$gateway"
    dnsServers = @($dnsServers)
} | ConvertTo-Json -Depth 2
