# 04 - Запустить ВМ и открыть окно vmconnect.
#      Окно нужно, чтобы видеть установку Windows (specialize + OOBE) глазами.
#
# Перенесено из CreateVM_DISM.ps1 (секция 6).
# Значения подменяет оркестратор из конфига перед выполнением.

$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"

Write-Host "Starting VM..."
Start-VM -VMName $vmName
vmconnect localhost $vmName
Write-Host "Done. Windows should boot directly into setup (specialize + OOBE)."
