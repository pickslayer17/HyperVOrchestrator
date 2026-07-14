$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$isDynamic = $false
$alias = ""
$ip = ""

$route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
         Sort-Object RouteMetric | Select-Object -First 1
if ($route) {
    $ipObj = Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Select-Object -First 1
    if ($ipObj) {
        $alias = $ipObj.InterfaceAlias
        $ip = $ipObj.IPAddress
        $isDynamic = $ipObj.PrefixOrigin -eq 'Dhcp'
    }
}

[pscustomobject]@{ isDynamic = $isDynamic; alias = "$alias"; ip = "$ip" } | ConvertTo-Json -Depth 2
