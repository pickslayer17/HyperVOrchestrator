# check для 02-Create-Vm: нужен готовый VHDX (его делает 01). Без него New-VM нечем кормить.
# exit 0 = можно запускать основной скрипт.

$vmName = "TestRunner"
$vmPath = "D:\VMs"
$vhdPath = "$vmPath\$vmName.vhdx"

if (-not (Test-Path $vhdPath)) {
    Write-Host "VHDX not found: $vhdPath (run 01-Build-Vhdx first)."
    exit 1
}

Write-Host "VHDX present."
exit 0
