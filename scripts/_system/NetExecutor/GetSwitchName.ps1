# host: name of the NAT-backed internal switch, or "" if none
# derived from the NAT subnet -> vEthernet adapter (no Hyper-V cmdlets, no elevation)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$switchName = ""
$nat = Get-NetNat -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nat) {
    $base = $nat.InternalIPInterfaceAddressPrefix.Split('/')[0]
    $subnet = $base.Substring(0, $base.LastIndexOf('.') + 1)
    $ifAlias = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object { $_.IPAddress -like "$subnet*" -and $_.InterfaceAlias -like 'vEthernet (*)' } |
               Select-Object -First 1 -ExpandProperty InterfaceAlias
    if ($ifAlias -match '^vEthernet \((.+)\)$') { $switchName = $Matches[1] }
}
"$switchName"
