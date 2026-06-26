$ScriptTarget = "Host"
# 00 - Подготовка: проверить ISO/unattend,
#      снести существующую ВМ и старый VHDX (откат предыдущей попытки).
#
# Перенесено из CreateVM_DISM.ps1 (секции НАСТРОЙКИ / ПРОВЕРКИ / ОЧИСТКА).
# Значения подменяет оркестратор из конфига перед выполнением.

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ (из конфига) ===
$vmName = "@@vm.name@@"
$windowsIso = "@@paths.windowsIso@@"
$unattendXml = "@@paths.unattendXml@@"
# VHDX = директория ВМ из конфига + имя ВМ + .vhdx
$vhdPath = Join-Path "@@paths.vmDir@@" "$vmName.vhdx"

# === ПРОВЕРКИ ===
if (-not (Test-Path $windowsIso)) { throw "Windows ISO not found: $windowsIso" }
if (-not (Test-Path $unattendXml)) { throw "autounattend.xml not found: $unattendXml" }

# === ОЧИСТКА ===
$existingVm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if ($existingVm) {
    Write-Host "Removing existing VM '$vmName'..."
    if ($existingVm.State -ne 'Off') { Stop-VM -Name $vmName -Force }
    Remove-VM -Name $vmName -Force
}
if (Test-Path $vhdPath) {
    Dismount-VHD -Path $vhdPath -ErrorAction SilentlyContinue
    Remove-Item $vhdPath -Force
}

Write-Host "Prepared. VHDX path: $vhdPath"
