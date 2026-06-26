# flaui project present in guest

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$desktop     = "C:\Users\@@credentials.user@@\Desktop"
$projectName = "@@flaui.projectName@@"
if (-not (Test-Path "$desktop\$projectName\$projectName.csproj")) { throw "FlaUI project not found in VM (run 01-New-FlaUiProject first)." }
Write-Host "FlaUI project present in VM."
