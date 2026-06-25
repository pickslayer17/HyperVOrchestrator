# check для 01-Build-Vhdx: нужны ISO и autounattend.xml — без них DISM-применять нечего.
# exit 0 = можно запускать основной скрипт.

$vmPath = "D:\VMs"
$windowsIso = "$vmPath\26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
$unattendXml = "$vmPath\unattend\autounattend.xml"

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
