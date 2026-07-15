param(
    [string]$NatName
)
$ErrorActionPreference = "Stop"

$hostNetInterface = [pscustomobject]@{ isDynamic = $false; alias = ""; ip = "" }
$netInterfaces = @()

$nat = Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
if ($nat) {
    $base = $nat.InternalIPInterfaceAddressPrefix.Split('/')[0]
    $subnet = $base.Substring(0, $base.LastIndexOf('.') + 1)

    $ipObj = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.IPAddress -like "$subnet*" -and $_.InterfaceAlias -like 'vEthernet (*)' } |
             Select-Object -First 1
    if ($ipObj) {
        $hostNetInterface = [pscustomobject]@{
            isDynamic = ($ipObj.PrefixOrigin -eq 'Dhcp')
            alias = $ipObj.InterfaceAlias
            ip = $ipObj.IPAddress
        }
    }

    $neighbors = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.IPAddress -like "$subnet*" -and $_.State -in 'Reachable', 'Stale', 'Permanent' -and $_.IPAddress -ne $hostNetInterface.ip }
    foreach ($n in $neighbors) {
        $netInterfaces += [pscustomobject]@{ isDynamic = $false; alias = ""; ip = $n.IPAddress }
    }
}

[pscustomobject]@{ alias = "$NatName"; hostNetInterface = $hostNetInterface; netInterfaces = @($netInterfaces) } | ConvertTo-Json -Depth 4
