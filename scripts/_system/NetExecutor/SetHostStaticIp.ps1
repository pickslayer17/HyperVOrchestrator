param(
	[string]$Alias,
	[string]$Ip,
	[int]$PrefixLength
)
$ErrorActionPreference = "Stop"

Remove-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Set-NetIPInterface -InterfaceAlias $Alias -AddressFamily IPv4 -Dhcp Disabled
New-NetIPAddress -InterfaceAlias $Alias -IPAddress $Ip -PrefixLength $PrefixLength | Out-Null
