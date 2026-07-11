# vm: guest nat interface -> json { isDynamic, alias, ip }
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
$alias = if ($adapter) { $adapter.Name } else { "" }

$ip = ""
$isDynamic = $false
if ($adapter) {
    $ipObj = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
    if ($ipObj) {
        $ip = $ipObj.IPAddress
        $isDynamic = $ipObj.PrefixOrigin -eq 'Dhcp'
    }
}

[pscustomobject]@{ isDynamic = $isDynamic; alias = "$alias"; ip = "$ip" } | ConvertTo-Json -Depth 2
