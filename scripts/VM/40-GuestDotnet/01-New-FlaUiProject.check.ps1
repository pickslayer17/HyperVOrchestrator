# dotnet present in guest

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$installDir = "@@paths.dotnetInstallDir@@"
if (-not (Test-Path "$installDir\dotnet.exe")) { throw "dotnet.exe not found in VM (run 00-Install-DotNet first)." }
Write-Host "dotnet present in VM."
