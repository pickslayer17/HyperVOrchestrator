$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path (Join-Path "@@paths.guestOfficeDir@@" "configuration.xml")) {
    Write-Host "config already present."
    exit 2
}
Write-Host "no config."
exit 0
