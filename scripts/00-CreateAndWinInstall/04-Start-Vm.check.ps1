# check для 04-Start-Vm: ВМ должна существовать. Запускать нечего, если её нет.
# exit 0 = можно запускать основной скрипт.
# Значения подменяет оркестратор из конфига перед выполнением.

$vmName = "@@vm.name@@"

if (-not (Get-VM -Name $vmName -ErrorAction SilentlyContinue)) {
    Write-Host "VM '$vmName' not found (run 02-Create-Vm first)."
    exit 1
}

Write-Host "VM exists."
exit 0
