$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$installer = Join-Path $env:TEMP "chrome_enterprise.msi"
$url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"

& curl.exe -sS -L -o $installer $url 2>$null
if ($LASTEXITCODE -ne 0) { throw "curl download failed (exit $LASTEXITCODE)" }
$proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i","`"$installer`"","/qn","/norestart" -Wait -PassThru
if ($proc.ExitCode -ne 0) { throw "msiexec failed (exit $($proc.ExitCode))" }
Remove-Item $installer -Force -ErrorAction SilentlyContinue

$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) { throw "Chrome not installed: $chromeExe" }
Write-Host "Chrome installed."
