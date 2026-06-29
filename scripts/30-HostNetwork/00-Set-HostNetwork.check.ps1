# find/verify host network -> state (exit 2 if already configured)

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"

$desiredPrefix    = 24
$desiredProxyPort = 3128
$desiredRdpPort   = 13389

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "Not running as Administrator."; exit 1 }
if (-not (Get-Module -ListAvailable -Name Hyper-V)) { Write-Host "Hyper-V module not available."; exit 1 }

# free ports (bump if taken)
$listening = @((Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue).LocalPort)
function Find-FreePort([int]$start) {
    $p = $start
    while ($listening -contains $p) { $p++ }
    return $p
}
Write-Host "<<set::state.proxyPort=$(Find-FreePort $desiredProxyPort)>>"
Write-Host "<<set::state.rdpForwardPort=$(Find-FreePort $desiredRdpPort)>>"

# existing switch + nat -> take their real values
$switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
$nat    = Get-NetNat   -Name $natName    -ErrorAction SilentlyContinue
$ip = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($switch -and $nat -and $ip) {
    Write-Host "<<set::state.hostIp=$($ip.IPAddress)>>"
    Write-Host "<<set::state.prefix=$($ip.PrefixLength)>>"
    Write-Host "<<set::state.hostSwitchIfIndex=$($ip.InterfaceIndex)>>"
    Write-Host "Host network already configured: $($ip.IPAddress)/$($ip.PrefixLength)."
    exit 2
}

# none -> pick free gateway ip (.1 in a free subnet)
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
Write-Host "Host ready; will create $switchName at $gw/$desiredPrefix."
exit 0
