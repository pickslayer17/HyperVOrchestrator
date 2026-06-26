$ScriptTarget = "VM"
# 02 - Очистить временные файлы внутри ВМ: SoftwareDistribution\Download,
#      Windows\Temp, LocalAppData\Temp, Prefetch. Плюс DISM component cleanup.
#
# Перенесено из after_setup/clean_temp.ps1.
# $ScriptTarget = "VM" -> оркестратор заворачивает в Invoke-Command -VMName сам.

$ErrorActionPreference = "Stop"

dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup done."
