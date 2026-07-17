$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path (Join-Path "@@paths.guestOfficeDir@@" "setup.exe")) {
    Write-Host "office files already copied to VM."
    exit 2
}
Write-Host "office files not on VM."
exit 0
