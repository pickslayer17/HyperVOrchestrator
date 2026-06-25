#:target vm
# 01 - DISM cleanup внутри ВМ: компонентная очистка с ResetBase,
#      удаление Windows Defender и Internet Explorer.
#
# Перенесено из after_setup/dism_clean.ps1.
# #:target vm -> оркестратор заворачивает в Invoke-Command -VMName сам.

$ErrorActionPreference = "Stop"

dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
dism /online /Disable-Feature /FeatureName:Windows-Defender /Remove
dism /online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /Remove
Write-Host "Done."
