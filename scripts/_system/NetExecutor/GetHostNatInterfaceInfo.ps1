# host: nat vEthernet interface -> json { isDynamic, alias, ip }
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@state.host.switchName@@"
$alias = "vEthernet ($switchName)"

$ipObj = Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
         Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1

$ip = if ($ipObj) { $ipObj.IPAddress } else { "" }
$isDynamic = if ($ipObj) { $ipObj.PrefixOrigin -eq 'Dhcp' } else { $false }

[pscustomobject]@{ isDynamic = $isDynamic; alias = $alias; ip = "$ip" } | ConvertTo-Json -Depth 2
