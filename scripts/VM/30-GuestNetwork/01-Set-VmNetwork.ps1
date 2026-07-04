# guest network: static ip, dns, proxy (all levels), verify

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmIp          = "@@state.vm.ip@@"
$prefix        =  @@network.subnetPrefixLength@@
$gateway       = "@@state.host.natIp@@"
$dns           = "@@network.dnsServer@@"
$proxyHostPort = "@@state.host.natIp@@:@@state.host.proxyPort@@"
$vmUser        = "@@credentials.user@@"
$ifAlias       = "@@state.vm.interfaceAlias@@"

# static ip
$existing = Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existing | Where-Object { $_.IPAddress -eq $vmIp }) {
    Write-Host "IP $vmIp already set."
} else {
    Get-NetIPAddress -InterfaceAlias $ifAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
        ForEach-Object { Remove-NetIPAddress -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue }
    Remove-NetRoute -InterfaceAlias $ifAlias -Confirm:$false -ErrorAction SilentlyContinue
    Set-NetIPInterface -InterfaceAlias $ifAlias -AddressFamily IPv4 -Dhcp Disabled
    New-NetIPAddress -InterfaceAlias $ifAlias -IPAddress $vmIp -PrefixLength $prefix -DefaultGateway $gateway
    Write-Host "IP set: $vmIp"
}

# dns
Set-DnsClientServerAddress -InterfaceAlias $ifAlias -ServerAddresses $dns
Write-Host "DNS set: $dns"

# real rdp port this guest listens on -> state (host uses it as forward target)
$vmRdpPort = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name PortNumber).PortNumber
Write-Host "<<set::state.vm.rdpPort=$vmRdpPort>>"

# proxy: system (winhttp)
netsh winhttp set proxy "$proxyHostPort"

# proxy: machine
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
Set-ItemProperty -Path $regPath -Name ProxyServer -Value "$proxyHostPort"

# proxy: env vars
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://$proxyHostPort", "Machine")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://$proxyHostPort", "Machine")

# proxy: user hkcu
$sid = (New-Object System.Security.Principal.NTAccount($vmUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
reg load "HKU\$sid" "C:\Users\$vmUser\NTUSER.DAT" 2>$null
reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "$proxyHostPort" /f
reg unload "HKU\$sid" 2>$null

Write-Host "All proxy settings configured."

# verify
Write-Host "Testing connectivity..."
$result = curl https://google.com -UseBasicParsing -TimeoutSec 10 -Proxy "http://$proxyHostPort" -ErrorAction SilentlyContinue
if ($result.StatusCode -eq 200) {
    Write-Host "INTERNET OK"
} else {
    Write-Host "INTERNET FAILED - check proxy.py on host"
}
