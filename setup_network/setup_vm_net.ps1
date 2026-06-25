$ErrorActionPreference = "Stop"

$vmName = "TestRunner"

if (-not $cred) {
    $cred = Get-Credential -Message "VM credentials (TestUser / Test1234!)"
}

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {

    # === STATIC IP ===
    $existing = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existing | Where-Object { $_.IPAddress -eq "192.168.50.2" }) {
        Write-Host "IP 192.168.50.2 already set."
    } else {
        # Remove old IPs
        Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.PrefixOrigin -ne "WellKnown" } |
            ForEach-Object { Remove-NetIPAddress -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue }
        Remove-NetRoute -InterfaceAlias "Ethernet" -Confirm:$false -ErrorAction SilentlyContinue
        New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.50.2 -PrefixLength 24 -DefaultGateway 192.168.50.1
        Write-Host "IP set: 192.168.50.2"
    }

    # === DNS ===
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8
    Write-Host "DNS set: 8.8.8.8"

    # === PROXY: SYSTEM (winhttp) ===
    netsh winhttp set proxy "192.168.50.1:3128"

    # === PROXY: MACHINE LEVEL (services, SYSTEM account) ===
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value "192.168.50.1:3128"

    # === PROXY: ENV VARS (git, npm, pip, curl.exe) ===
    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY", "http://192.168.50.1:3128", "Machine")
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://192.168.50.1:3128", "Machine")

    # === PROXY: TESTUSER HKCU ===
    $sid = (New-Object System.Security.Principal.NTAccount("TestUser")).Translate([System.Security.Principal.SecurityIdentifier]).Value
    reg load "HKU\$sid" "C:\Users\TestUser\NTUSER.DAT" 2>$null
    reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
    reg add "HKU\$sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "192.168.50.1:3128" /f
    reg unload "HKU\$sid" 2>$null

    Write-Host "All proxy settings configured."

    # === VERIFY ===
    Write-Host "Testing connectivity..."
    $result = curl https://google.com -UseBasicParsing -TimeoutSec 10 -Proxy "http://192.168.50.1:3128" -ErrorAction SilentlyContinue
    if ($result.StatusCode -eq 200) {
        Write-Host "INTERNET OK"
    } else {
        Write-Host "INTERNET FAILED - check proxy.py on host"
    }
}
