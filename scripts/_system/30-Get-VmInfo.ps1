# host: full snapshot of one VM (identity + guest network state) -> single json blob
# guest values are read over PSDirect; empty if the VM is off or unreachable.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$switchName = "@@state.host.switchName@@"
$vmUser     = "@@credentials.user@@"
$vmPass     = "@@credentials.password@@"

# host ip on the nat switch -> base subnet used to pick the guest's own ip
$hostNatIp = ""
$hostIpObj = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
             Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($hostIpObj) { $hostNatIp = $hostIpObj.IPAddress }
$base = if ($hostNatIp) { $hostNatIp.Substring(0, $hostNatIp.LastIndexOf('.') + 1) } else { "" }

$secpass = ConvertTo-SecureString $vmPass -AsPlainText -Force
$cred    = New-Object System.Management.Automation.PSCredential($vmUser, $secpass)

$probe = {
    param($base)
    $rdp   = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name PortNumber -ErrorAction SilentlyContinue).PortNumber
    $alias = (Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name
    $proxy = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
    $proxyPort = if ($proxy -and $proxy.Contains(':')) { $proxy.Split(':')[-1] } else { "" }
    $ip = ""
    if ($base) {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like "$base*" } | Select-Object -First 1).IPAddress
    }
    [pscustomobject]@{ natIp = "$ip"; rdpPort = "$rdp"; interfaceAlias = "$alias"; proxyPort = "$proxyPort" }
}

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
$out = @{ name = $vmName; running = $false; natName = $switchName; natIp = ""; rdpPort = ""; interfaceAlias = ""; proxyPort = "" }

if ($vm) {
    $out.running = $vm.State -eq 'Running'
    if ($out.running) {
        try {
            $g = Invoke-Command -VMName $vm.Name -Credential $cred -ArgumentList $base -ScriptBlock $probe -ErrorAction Stop
            $out.natIp          = $g.natIp
            $out.rdpPort        = $g.rdpPort
            $out.interfaceAlias = $g.interfaceAlias
            $out.proxyPort      = $g.proxyPort
        } catch { }
    }
}

$out | ConvertTo-Json -Depth 4
