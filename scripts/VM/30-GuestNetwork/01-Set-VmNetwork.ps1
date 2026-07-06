# guest network: static ip, dns, proxy (all levels), verify

$RootPriviledges = $true
$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$vmIp          = "@@state.vm.ip@@"
$prefixLength  =  @@network.subnetPrefixLength@@
$gateway       = "@@state.host.natIp@@"
$dns           = "@@network.dnsServer@@"
$proxyHostPort = "@@state.host.natIp@@:@@state.host.proxyPort@@"
$vmUser        = "@@credentials.user@@"
$interfaceAlias = "@@state.vm.interfaceAlias@@"

# static ip
$existingIpAddresses = Get-NetIPAddress -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existingIpAddresses | Where-Object { $_.IPAddress -eq $vmIp }) {
    Write-Host "IP $vmIp already set."
} else {
    Get-NetIPAddress -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
        ForEach-Object { Remove-NetIPAddress -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue }
    Remove-NetRoute -InterfaceAlias $interfaceAlias -Confirm:$false -ErrorAction SilentlyContinue
    Set-NetIPInterface -InterfaceAlias $interfaceAlias -AddressFamily IPv4 -Dhcp Disabled
    New-NetIPAddress -InterfaceAlias $interfaceAlias -IPAddress $vmIp -PrefixLength $prefixLength -DefaultGateway $gateway
    Write-Host "IP set: $vmIp"
}

# dns
Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dns
Write-Host "DNS set: $dns"

# real rdp port this guest listens on -> state (host uses it as forward target)
$vmRdpPort = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name PortNumber).PortNumber
Write-Host "<<set::state.vm.rdpPort=$vmRdpPort>>"

# proxy: system (winhttp)
netsh winhttp set proxy "$proxyHostPort"

# proxy: machine
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -Path $registryPath -Name ProxyEnable -Value 1
Set-ItemProperty -Path $registryPath -Name ProxyServer -Value "$proxyHostPort"

# proxy: env vars
[System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://$proxyHostPort", "Machine")
[System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://$proxyHostPort", "Machine")

# proxy: user hkcu
$userSid = (New-Object System.Security.Principal.NTAccount($vmUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
reg load "HKU\$userSid" "C:\Users\$vmUser\NTUSER.DAT" 2>$null
reg add "HKU\$userSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKU\$userSid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "$proxyHostPort" /f
reg unload "HKU\$userSid" 2>$null

Write-Host "All proxy settings configured."

# verify
Write-Host "Testing connectivity..."
$connectivityResult = curl https://google.com -UseBasicParsing -TimeoutSec 10 -Proxy "http://$proxyHostPort" -ErrorAction SilentlyContinue
if ($connectivityResult.StatusCode -eq 200) {
    Write-Host "INTERNET OK"
} else {
    Write-Host "INTERNET FAILED - check proxy.py on host"
}
