param(
    [string]$ProxyAddress,
    [string]$VmUser
)
$ErrorActionPreference = "Stop"

netsh winhttp set proxy "$ProxyAddress"

$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $key -Name ProxyServer -Value $ProxyAddress
Set-ItemProperty -Path $key -Name ProxyEnable -Value 1

[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://$ProxyAddress", "Machine")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://$ProxyAddress", "Machine")

$userSid = (New-Object System.Security.Principal.NTAccount($VmUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$userKey = "Registry::HKEY_USERS\$userSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
if (Test-Path "Registry::HKEY_USERS\$userSid") {
    Set-ItemProperty -Path $userKey -Name ProxyServer -Value $ProxyAddress
    Set-ItemProperty -Path $userKey -Name ProxyEnable -Value 1
} else {
    reg load "HKU\$userSid" "C:\Users\$VmUser\NTUSER.DAT" 2>$null
    reg add "HKU\$userSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    reg add "HKU\$userSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "$ProxyAddress" /f
    reg unload "HKU\$userSid" 2>$null
}
