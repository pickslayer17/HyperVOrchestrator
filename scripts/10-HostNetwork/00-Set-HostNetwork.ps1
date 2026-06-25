# 00 - Host network: создать NATSwitch (internal), повесить IP хоста, создать NAT,
#      подключить адаптер ВМ к свитчу.
#
# Перенесено из setup_network/setup_host_net.ps1.
# Host-side. Значения подменяет оркестратор из конфига перед выполнением.
#
# ДИНАМИКА: ifIndex адаптера vEthernet (<switch>) вычисляется на лету и
# записывается в state-файл (JSON) — позже используется другими шагами.

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ (из конфига) ===
$switchName = "@@network.switchName@@"
$natName    = "@@network.natName@@"
$hostIp     = "@@network.hostIp@@"
$prefix     = @@network.prefix@@
$vmName     = "@@vm.name@@"

# Префикс подсети для NAT собираем из hostIp: x.y.z.0/prefix
$octets = $hostIp.Split('.')
$subnetPrefix = "$($octets[0]).$($octets[1]).$($octets[2]).0/$prefix"

# === NAT SWITCH ===
$natSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
if (-not $natSwitch) {
    Write-Host "Creating $switchName..."
    New-VMSwitch -Name $switchName -SwitchType Internal
    $ifIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
    New-NetIPAddress -IPAddress $hostIp -PrefixLength $prefix -InterfaceIndex $ifIndex
    Write-Host "$switchName created with IP $hostIp"
} else {
    Write-Host "$switchName already exists."
    $ifIndex = (Get-NetAdapter -Name "vEthernet ($switchName)").ifIndex
}

# === NAT ===
$nat = Get-NetNat -Name $natName -ErrorAction SilentlyContinue
if (-not $nat) {
    New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $subnetPrefix
    Write-Host "$natName created."
} else {
    Write-Host "$natName already exists."
}

# === CONNECT VM ===
$adapter = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
if ($adapter -and $adapter.SwitchName -ne $switchName) {
    Disconnect-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
    Write-Host "VM connected to $switchName."
} elseif ($adapter.SwitchName -eq $switchName) {
    Write-Host "VM already on $switchName."
} else {
    Connect-VMNetworkAdapter -VMName $vmName -SwitchName $switchName
    Write-Host "VM connected to $switchName."
}

# === СОХРАНИТЬ ДИНАМИКУ В STATE ===
# Эмитим значение оркестратору: он положит его в карту интерполяции (следующий
# шаг увидит @@state.hostSwitchIfIndex@@) и в artifacts/state.json. JSON руками
# больше не пишем.
Write-Host "::set state.hostSwitchIfIndex=$ifIndex"

Write-Host "Host network ready."
