# host network picture -> decide (exit 2 if ready for THIS vm)

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"
$vmName     = "@@vm.name@@"

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

# ports: let the OS hand us free ephemeral ports (it never returns an occupied one)
function Get-FreePort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 0)
    $listener.Start()
    $port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
    $listener.Stop()
    return $port
}
Write-Host "<<set::state.host.proxyPort=$(Get-FreePort)>>"
Write-Host "<<set::state.vm.hostRdpForwardPort=$(Get-FreePort)>>"

# gateway ip: record existing, or pick a free .1 for a new switch
if ($hostIpObj) {
    Write-Host "<<set::state.host.natIp=$($hostIpObj.IPAddress)>>"
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
    Write-Host "<<set::state.host.natIp=$gw>>"
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
