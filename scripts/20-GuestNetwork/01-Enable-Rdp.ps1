#:target vm
# 01 - Включить RDP в госте: разрешить подключения, отключить NLA, открыть firewall.
#
# Перенесено из setup_network/setup_RDP.ps1.
# #:target vm -> оркестратор заворачивает в Invoke-Command -VMName сам.

$ErrorActionPreference = "Stop"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -Value 0
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
Write-Host "RDP enabled."
