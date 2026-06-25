# 02 - Очистить временные файлы внутри ВМ: SoftwareDistribution\Download,
#      Windows\Temp, LocalAppData\Temp, Prefetch. Плюс DISM component cleanup.
#
# Перенесено из after_setup/clean_temp.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmUser = "@@credentials.user@@"
$vmPass = "@@credentials.password@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup done."
}
