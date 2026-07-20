$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$xmlPath = Join-Path $env:TEMP "default_assoc.xml"
$xml = @'
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
  <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
'@
[System.IO.File]::WriteAllText($xmlPath, $xml, (New-Object System.Text.UTF8Encoding($false)))

dism /online /Import-DefaultAppAssociations:"$xmlPath"
if ($LASTEXITCODE -ne 0) { throw "dism Import-DefaultAppAssociations failed with exit $LASTEXITCODE" }
Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue

Write-Host "Chrome set as default browser (applies after next logon)."
