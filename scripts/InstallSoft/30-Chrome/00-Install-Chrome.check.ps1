$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
    Write-Host "Chrome already installed."
    exit 2
}
Write-Host "Chrome not installed."
exit 0
