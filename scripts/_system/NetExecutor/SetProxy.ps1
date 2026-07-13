param(
    [string]$ProxyAddress
)
$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $key -Name ProxyServer -Value $ProxyAddress
Set-ItemProperty -Path $key -Name ProxyEnable -Value 1
