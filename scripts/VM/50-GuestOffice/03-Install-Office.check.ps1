$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE') {
    Write-Host "Office already installed."
    exit 2
}
Write-Host "Office not installed."
exit 0
