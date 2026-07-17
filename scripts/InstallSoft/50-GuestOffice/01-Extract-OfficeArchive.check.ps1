$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path (Join-Path "@@paths.guestOfficeDir@@" "Office\Data")) {
    Write-Host "archive already extracted."
    exit 2
}
Write-Host "archive not extracted."
exit 0
