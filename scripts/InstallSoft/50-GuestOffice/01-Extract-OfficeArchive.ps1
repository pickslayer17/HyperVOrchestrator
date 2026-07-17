$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestOfficeDir@@"
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path (Join-Path $guestDir "Office")) { Remove-Item (Join-Path $guestDir "Office") -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $guestDir "Office.zip"), $guestDir)
Remove-Item (Join-Path $guestDir "Office.zip") -Force
Write-Host "extracted to $guestDir\Office; removed Office.zip"
