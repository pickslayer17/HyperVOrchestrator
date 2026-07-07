$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@state.host.switchName@@"
$hostIpAddress = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($hostIpAddress) { $hostIpAddress.IPAddress } else { "" }
