# enable rdp in guest

$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -Value 0
netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes
Write-Host "RDP enabled."
