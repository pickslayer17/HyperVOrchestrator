# check для 01-Build-Vhdx: нужны ISO и autounattend.xml — без них DISM-применять нечего.
# exit 0 = можно запускать основной скрипт.
# Значения подменяет оркестратор из конфига перед выполнением.

$windowsIso = "@@paths.windowsIso@@"
$unattendXml = "@@paths.unattendXml@@"

if (-not (Test-Path $windowsIso)) {
    Write-Host "Windows ISO not found: $windowsIso"
    exit 1
}
if (-not (Test-Path $unattendXml)) {
    Write-Host "autounattend.xml not found: $unattendXml"
    exit 1
}

Write-Host "ISO and unattend present."
exit 0
