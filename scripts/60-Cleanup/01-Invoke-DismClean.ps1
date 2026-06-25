# 01 - DISM cleanup внутри ВМ: компонентная очистка с ResetBase,
#      удаление Windows Defender и Internet Explorer.
#
# Перенесено из after_setup/dism_clean.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmUser = "@@credentials.user@@"
$vmPass = "@@credentials.password@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
    dism /online /Disable-Feature /FeatureName:Windows-Defender /Remove
    dism /online /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /Remove
    Write-Host "Done."
}
