param(
    [string]$SwitchName
)
$ErrorActionPreference = "Stop"

$isDynamic = $false
$alias = ""
$ip = ""

$expectedAlias = "vEthernet ($SwitchName)"
$adapter = Get-NetAdapter -Name $expectedAlias -ErrorAction SilentlyContinue
if ($adapter) {
    $alias = $adapter.Name
    $ipObj = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
    if ($ipObj) {
        $ip = $ipObj.IPAddress
        $isDynamic = $ipObj.PrefixOrigin -eq 'Dhcp'
    }
}

[pscustomobject]@{ isDynamic = $isDynamic; alias = $alias; ip = "$ip" } | ConvertTo-Json -Depth 2
