$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$installer = Join-Path $env:TEMP "chrome_installer.exe"
$url = "https://dl.google.com/chrome/install/standalonesetup64.exe"

Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
Start-Process -FilePath $installer -ArgumentList "/silent","/install" -Wait
Remove-Item $installer -Force -ErrorAction SilentlyContinue

$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) { throw "Chrome not installed: $chromeExe" }
Write-Host "Chrome installed."
