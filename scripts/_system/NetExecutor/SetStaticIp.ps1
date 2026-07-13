param(
    [string]$Alias,
    [string]$Ip,
    [string]$Gateway,
    [int]$PrefixLength,
    [string]$Dns
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

Remove-NetIPAddress -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $Alias -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $Alias -IPAddress $Ip -PrefixLength $PrefixLength -DefaultGateway $Gateway | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $Alias -ServerAddresses $Dns
