# host: full snapshot of one VM (identity + guest network state) -> single json blob
# guest values are read over PSDirect; empty if the VM is off or unreachable.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$switchName = "@@state.host.switchName@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"

# host ip on the nat switch -> base subnet used to pick the guest's own ip
$hostNatIp = ""
$hostIpAddress = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($hostIpAddress) { $hostNatIp = $hostIpAddress.IPAddress }
$subnetPrefix = if ($hostNatIp) { $hostNatIp.Substring(0, $hostNatIp.LastIndexOf('.') + 1) } else { "" }

$securePassword = ConvertTo-SecureString $vmPassword -AsPlainText -Force
$credential    = New-Object System.Management.Automation.PSCredential($vmUser, $securePassword)

$guestProbe = {
    param($subnetPrefix)
    $rdpPort   = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name PortNumber -ErrorAction SilentlyContinue).PortNumber
    $interfaceAlias = (Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name
    $proxyAddress = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
    $proxyPort = if ($proxyAddress -and $proxyAddress.Contains(':')) { $proxyAddress.Split(':')[-1] } else { "" }
    $guestIp = ""
    if ($subnetPrefix) {
        $guestIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like "$subnetPrefix*" } | Select-Object -First 1).IPAddress
    }
    [pscustomobject]@{ natIp = "$guestIp"; rdpPort = "$rdpPort"; interfaceAlias = "$interfaceAlias"; proxyPort = "$proxyPort" }
}

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
$vmInfo = @{ name = $vmName; running = $false; natName = $switchName; natIp = ""; rdpPort = ""; interfaceAlias = ""; proxyPort = "" }

if ($vm) {
    $vmInfo.running = $vm.State -eq 'Running'
    if ($vmInfo.running) {
        try {
            $guestInfo = Invoke-Command -VMName $vm.Name -Credential $credential -ArgumentList $subnetPrefix -ScriptBlock $guestProbe -ErrorAction Stop
            $vmInfo.natIp          = $guestInfo.natIp
            $vmInfo.rdpPort        = $guestInfo.rdpPort
            $vmInfo.interfaceAlias = $guestInfo.interfaceAlias
            $vmInfo.proxyPort      = $guestInfo.proxyPort
        } catch { }
    }
}

$vmInfo | ConvertTo-Json -Depth 4
