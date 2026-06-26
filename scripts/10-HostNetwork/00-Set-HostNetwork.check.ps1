$ScriptTarget = "Host"
# check для 00-Set-HostNetwork (HOST-side). Вся динамика считается ЗДЕСЬ и
# уходит в state; основной скрипт берёт @@state.*@@. Трёхзначный код:
#   exit 1 — нельзя (нет админ-прав / нет Hyper-V).
#   exit 2 — свитч+NAT УЖЕ есть: берём ИХ реальные IP/prefix/ifIndex -> state,
#            основной не нужен, степ зелёный.
#   exit 0 — сети нет: выбрали свободный gateway IP + свободные порты -> state,
#            основной создаёт.
# В конфиге только имена-константы (switchName/natName/dnsServer/Ethernet).

$ErrorActionPreference = "Stop"

$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"

# Желаемые значения — КОНСТАНТЫ скрипта (не конфиг): берём их, если свободны,
# иначе ищем следующее свободное.
$desiredPrefix    = 24
$desiredProxyPort = 3128
$desiredRdpPort   = 13389

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Write-Host "Not running as Administrator."; exit 1 }
if (-not (Get-Module -ListAvailable -Name Hyper-V)) { Write-Host "Hyper-V module not available."; exit 1 }

# --- ПОРТЫ: желаемый, занят на хосте -> следующий по номеру ---
$listening = @((Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue).LocalPort)
function Find-FreePort([int]$start) {
    $p = $start
    while ($listening -contains $p) { $p++ }
    return $p
}
$proxyPort = Find-FreePort $desiredProxyPort
$rdpPort   = Find-FreePort $desiredRdpPort
Write-Host "::set state.proxyPort=$proxyPort"
Write-Host "::set state.rdpForwardPort=$rdpPort"

# --- NAT/СВИТЧ: есть -> берём его реальные IP/prefix/ifIndex ---
$switch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
$nat    = Get-NetNat   -Name $natName    -ErrorAction SilentlyContinue
$ip = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($switch -and $nat -and $ip) {
    Write-Host "::set state.hostIp=$($ip.IPAddress)"
    Write-Host "::set state.prefix=$($ip.PrefixLength)"
    Write-Host "::set state.hostSwitchIfIndex=$($ip.InterfaceIndex)"
    Write-Host "Host network already configured: $($ip.IPAddress)/$($ip.PrefixLength)."
    exit 2
}

# --- НЕТ СЕТИ: выбираем свободный gateway IP (.1 в свободной подсети) ---
$gw = $null
foreach ($third in 50..99) {
    $candidate = "192.168.$third.1"
    if (-not (Get-NetIPAddress -IPAddress $candidate -AddressFamily IPv4 -ErrorAction SilentlyContinue)) {
        $gw = $candidate
        break
    }
}
if (-not $gw) { Write-Host "No free gateway IP found."; exit 1 }

Write-Host "::set state.hostIp=$gw"
Write-Host "::set state.prefix=$desiredPrefix"
Write-Host "Host ready; will create $switchName at $gw/$desiredPrefix."
exit 0
