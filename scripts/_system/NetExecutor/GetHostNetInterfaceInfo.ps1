param(
    [string]$NatName
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$isDynamic = $false
$alias = ""
$ip = ""

$nat = Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
if ($nat) {
    $base = $nat.InternalIPInterfaceAddressPrefix.Split('/')[0]
    $subnet = $base.Substring(0, $base.LastIndexOf('.') + 1)
    $ipObj = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.IPAddress -like "$subnet*" -and $_.InterfaceAlias -like 'vEthernet (*)' } |
             Select-Object -First 1
    if ($ipObj) {
        $alias = $ipObj.InterfaceAlias
        $ip = $ipObj.IPAddress
        $isDynamic = $ipObj.PrefixOrigin -eq 'Dhcp'
    }
}

[pscustomobject]@{ isDynamic = $isDynamic; alias = "$alias"; ip = "$ip" } | ConvertTo-Json -Depth 2
