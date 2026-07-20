$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$exportPath = Join-Path $env:TEMP "assoc_check.xml"
dism /online /Export-DefaultAppAssociations:"$exportPath" | Out-Null
$applied = $false
if (Test-Path $exportPath) {
    $content = Get-Content $exportPath -Raw
    if ($content -match 'Identifier="https"[^>]*ProgId="ChromeHTML"') { $applied = $true }
    Remove-Item $exportPath -Force -ErrorAction SilentlyContinue
}

if ($applied) {
    Write-Host "Chrome already default browser."
    exit 2
}
Write-Host "Chrome not default browser."
exit 0
