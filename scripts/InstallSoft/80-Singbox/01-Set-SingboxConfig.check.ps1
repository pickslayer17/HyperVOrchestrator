$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path (Join-Path "@@paths.guestSingboxDir@@" "config.json")) {
    Write-Host "config.json already present."
    exit 2
}
Write-Host "config.json not present."
exit 0
