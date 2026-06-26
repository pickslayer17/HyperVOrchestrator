$ScriptTarget = "VM"
# 00 - Guest network: статический IP, DNS, прокси на всех уровнях (winhttp,
#      machine reg, env vars, HKCU пользователя), проверка интернета.
#
# Перенесено из setup_network/setup_vm_net.ps1.
# $ScriptTarget = "VM" -> оркестратор сам заворачивает этот файл в Invoke-Command -VMName
# с кредами из конфига. Тело пишем как «что сделать ВНУТРИ ВМ».

$ErrorActionPreference = "Stop"

# === НАСТРОЙКИ (из конфига) ===
$vmIp          = "@@network.vmIp@@"
$prefix        = @@network.prefix@@
$gateway       = "@@network.hostIp@@"
$dns           = "@@network.dnsServer@@"
$proxyHostPort = "@@network.hostIp@@:@@network.proxyPort@@"
$vmUser        = "@@credentials.user@@"
$ifAlias       = "@@network.guestInterfaceAlias@@"

# === STATIC IP ===
$existing = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existing | Where-Object { $_.IPAddress -eq $vmIp }) {
    Write-Host "IP $vmIp already set."
} else {
    Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
        ForEach-Object { Remove-NetIPAddress -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue }
    Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $vmIp -PrefixLength $prefix -DefaultGateway $gateway
    Write-Host "IP set: $vmIp"
}

# === DNS ===
Set-DnsClientServerAddress -InterfaceAlias $ifAlias -ServerAddresses $dns
Write-Host "DNS set: $dns"

# === PROXY: SYSTEM (winhttp) ===
netsh winhttp set proxy "$proxyHostPort"

# === PROXY: MACHINE LEVEL (services, SYSTEM account) ===
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
Set-ItemProperty -Path $regPath -Name ProxyServer -Value "$proxyHostPort"

# === PROXY: ENV VARS (git, npm, pip, curl.exe) ===
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://$proxyHostPort", "Machine")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://$proxyHostPort", "Machine")

# === PROXY: USER HKCU ===
$sid = (New-Object System.Security.Principal.NTAccount($vmUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
reg load "HKU\$sid" "C:\Users\$vmUser\NTUSER.DAT" 2>$null
reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "$proxyHostPort" /f
reg unload "HKU\$sid" 2>$null

Write-Host "All proxy settings configured."

# === VERIFY ===
Write-Host "Testing connectivity..."
$result = curl https://google.com -UseBasicParsing -TimeoutSec 10 -Proxy "http://$proxyHostPort" -ErrorAction SilentlyContinue
if ($result.StatusCode -eq 200) {
    Write-Host "INTERNET OK"
} else {
    Write-Host "INTERNET FAILED - check proxy.py on host"
}
