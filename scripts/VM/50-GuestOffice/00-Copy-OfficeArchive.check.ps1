$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if ((Test-Path 'C:\office_cache\Office.zip') -and (Test-Path 'C:\office_cache\setup.exe')) {
    Write-Host "archive + setup already on VM."
    exit 2
}
Write-Host "office files not on VM."
exit 0
