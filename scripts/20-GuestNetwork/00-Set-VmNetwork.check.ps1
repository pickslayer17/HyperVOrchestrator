$ScriptTarget = "Host"
# check для 00-Set-VmNetwork (HOST-side). Динамика — здесь: находим СВОБОДНЫЙ IP
# в подсети ВМ и отдаём оркестратору через ::set state.vmIp. Основной (VM-side)
# берёт @@state.vmIp@@. «Что занято» — знание хоста (он в подсети на .1), поэтому
# скан тут. Константы (NATSwitch/Ethernet/8.8.8.8/prefix) остаются в конфиге.

$ErrorActionPreference = "Stop"

# Подсеть берём из шлюза (host): 192.168.50.1 -> база 192.168.50.
$octets = "@@state.hostIp@@".Split('.')
$base = "$($octets[0]).$($octets[1]).$($octets[2])."

# .1 — шлюз (host), пропускаем. Сканируем .2..254, берём первый, который НЕ
# отвечает на ping = свободен. Свободный обычно находится сразу (.2 на свежей ВМ).
$vmIp = $null
foreach ($n in 2..254) {
    $candidate = "$base$n"
    if (-not (Test-Connection -ComputerName $candidate -Count 1 -Quiet)) {
        $vmIp = $candidate
        break
    }
}
if (-not $vmIp) { Write-Host "No free IP in subnet ${base}0/24."; exit 1 }

Write-Host "::set state.vmIp=$vmIp"
Write-Host "Free VM IP picked: $vmIp"
exit 0
