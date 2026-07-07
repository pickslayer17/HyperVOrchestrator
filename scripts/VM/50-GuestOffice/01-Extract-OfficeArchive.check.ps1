$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path 'C:\office_cache\Office\Data') {
    Write-Host "archive already extracted."
    exit 2
}
Write-Host "archive not extracted."
exit 0
