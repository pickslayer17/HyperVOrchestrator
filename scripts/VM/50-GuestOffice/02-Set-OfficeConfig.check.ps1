$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path 'C:\office_cache\configuration.xml') {
    Write-Host "config already present."
    exit 2
}
Write-Host "no config."
exit 0
