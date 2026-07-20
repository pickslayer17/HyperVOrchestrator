$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

if (Test-Path "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\mage.exe") {
    Write-Host "Windows SDK (mage.exe) already installed."
    exit 2
}
Write-Host "Windows SDK (mage.exe) not installed."
exit 0
