# 01 - Включить RDP в госте: разрешить подключения, отключить NLA, открыть firewall.
#
# Перенесено из setup_network/setup_RDP.ps1.
# VM-side: выполняется ВНУТРИ ВМ через Invoke-Command -VMName -Credential.

$ErrorActionPreference = "Stop"

$vmName = "@@vm.name@@"
$vmUser = "@@credentials.user@@"
$vmPass = "@@credentials.password@@"

$cred = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPass -AsPlainText -Force))

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -Value 0
    netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
    Write-Host "RDP enabled."
}
