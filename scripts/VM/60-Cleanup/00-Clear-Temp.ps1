# clear temp files + dism component cleanup

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup done."
