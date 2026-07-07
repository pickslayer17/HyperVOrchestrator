$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path 'C:\office_cache\Office') { Remove-Item 'C:\office_cache\Office' -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory('C:\office_cache\Office.zip', 'C:\office_cache')
Write-Host "extracted to C:\office_cache\Office"
