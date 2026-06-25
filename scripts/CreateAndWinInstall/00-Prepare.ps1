# 00 - Подготовка: проверить ISO/unattend, найти свободные буквы дисков,
#      снести существующую ВМ и старый VHDX (откат предыдущей попытки).
#
# Перенесено из CreateVM_DISM.ps1 (секции НАСТРОЙКИ / ПРОВЕРКИ / ПОИСК БУКВ / ОЧИСТКА).
# Выводит выбранные буквы дисков, чтобы следующий шаг знал, что использовать.

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ ===
$vmName = "TestRunner"
$vmPath = "D:\VMs"
$vhdPath = "$vmPath\$vmName.vhdx"
$windowsIso = "$vmPath\26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$unattendXml = "$vmPath\unattend\autounattend.xml"

# === ПРОВЕРКИ ===
if (-not (Test-Path $windowsIso)) { throw "Windows ISO not found: $windowsIso" }
if (-not (Test-Path $unattendXml)) { throw "autounattend.xml not found: $unattendXml" }

# === ПОИСК СВОБОДНЫХ БУКВ ===
$usedLetters = @()
$usedLetters += (Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$usedLetters += (Get-Partition | Where-Object { $_.DriveLetter } | ForEach-Object { $_.DriveLetter })
$freeLetters = [char[]](68..90) | Where-Object { $_ -notin $usedLetters }  # D-Z
if ($freeLetters.Count -lt 2) { throw "Not enough free drive letters" }
$efiLetter = [string]$freeLetters[0]
$winLetter = [string]$freeLetters[1]
Write-Host "Using drive letters: EFI=$efiLetter, Windows=$winLetter"

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
