# 00 - Дать пользователю full access на C:\ внутри ВМ.
#
# Перенесено из setup_access/user_full_access.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmUser = "@@credentials.user@@"
$vmPass = "@@credentials.password@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ArgumentList $vmUser -ScriptBlock {
    param($vmUser)
    icacls "C:\" /grant "${vmUser}:(OI)(CI)F" /T /Q
    Write-Host "$vmUser has full access to C:\"
}
