# host network picture -> decide (exit 2 if ready for THIS vm)

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"
$vmName     = "@@vm.name@@"

$desiredPrefix    = 24
$desiredProxyPort = 3128
$desiredRdpPort   = 13389

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "Not running as Administrator."; exit 1 }
if (-not (Get-Module -ListAvailable -Name Hyper-V)) { Write-Host "Hyper-V module not available."; exit 1 }

# picture
$switch    = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
$nat       = Get-NetNat   -Name $natName    -ErrorAction SilentlyContinue
$hostIpObj = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
$adapter   = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
$onSwitch  = $adapter -and ($adapter.SwitchName -eq $switchName)

# free ports (bump if taken)
$listening = @((Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue).LocalPort)
function Find-FreePort([int]$start) {
    $p = $start
    while ($listening -contains $p) { $p++ }
    return $p
}
Write-Host "<<set::state.proxyPort=$(Find-FreePort $desiredProxyPort)>>"
Write-Host "<<set::state.rdpForwardPort=$(Find-FreePort $desiredRdpPort)>>"

# gateway ip: record existing, or pick a free .1 for a new switch
if ($hostIpObj) {
    Write-Host "<<set::state.hostIp=$($hostIpObj.IPAddress)>>"
    Write-Host "<<set::state.prefix=$($hostIpObj.PrefixLength)>>"
    Write-Host "<<set::state.hostSwitchIfIndex=$($hostIpObj.InterfaceIndex)>>"
} else {
    $gw = $null
    foreach ($third in 50..99) {
        $candidate = "192.168.$third.1"
        if (-not (Get-NetIPAddress -IPAddress $candidate -AddressFamily IPv4 -ErrorAction SilentlyContinue)) {
            $gw = $candidate
            break
        }
    }
    if (-not $gw) { Write-Host "No free gateway IP found."; exit 1 }
    Write-Host "<<set::state.hostIp=$gw>>"
    Write-Host "<<set::state.prefix=$desiredPrefix>>"
}

# done only if infra exists AND this vm is on the switch
if ($switch -and $nat -and $hostIpObj -and $onSwitch) {
    Write-Host "Host network ready; $vmName on $switchName at $($hostIpObj.IPAddress)/$($hostIpObj.PrefixLength)."
    exit 2
}

if (-not $switch)    { Write-Host "switch $switchName missing." }
if (-not $nat)       { Write-Host "nat $natName missing." }
if (-not $hostIpObj) { Write-Host "host gateway ip missing." }
if (-not $onSwitch)  { Write-Host "$vmName not on ${switchName} (current: '$($adapter.SwitchName)')." }
exit 0
