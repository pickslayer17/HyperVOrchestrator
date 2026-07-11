# vm: guest network snapshot -> json { running, natIp, interfaceAlias, proxyAddress }
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
$interfaceAlias = if ($adapter) { $adapter.Name } else { "" }

$natIp = ""
if ($adapter) {
    $ipObj = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
    if ($ipObj) { $natIp = $ipObj.IPAddress }
}

$proxyAddress = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer

[pscustomobject]@{ running = $true; natIp = "$natIp"; interfaceAlias = "$interfaceAlias"; proxyAddress = "$proxyAddress" } | ConvertTo-Json -Depth 2
