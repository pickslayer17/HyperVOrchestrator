# host: one VM network snapshot -> json { running, natIp, interfaceAlias, proxyAddress }
# guest values are read over PSDirect; empty if the VM is off or unreachable.
$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$switchName = "@@state.host.switchName@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"

$hostNatIp = ""
$hostIpAddress = Get-NetIPAddress -InterfaceAlias "vEthernet ($switchName)" -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                 Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
if ($hostIpAddress) { $hostNatIp = $hostIpAddress.IPAddress }
$subnetPrefix = if ($hostNatIp) { $hostNatIp.Substring(0, $hostNatIp.LastIndexOf('.') + 1) } else { "" }

$securePassword = ConvertTo-SecureString $vmPassword -AsPlainText -Force
$credential    = New-Object System.Management.Automation.PSCredential($vmUser, $securePassword)

$guestProbe = {
    param($subnetPrefix)
    $proxyAddress = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
    $interfaceAlias = (Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1).Name
    $guestIp = ""
    if ($subnetPrefix) {
        $guestIp = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like "$subnetPrefix*" } | Select-Object -First 1).IPAddress
    }
    [pscustomobject]@{ natIp = "$guestIp"; interfaceAlias = "$interfaceAlias"; proxyAddress = "$proxyAddress" }
}

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
$info = @{ running = $false; natIp = ""; interfaceAlias = ""; proxyAddress = "" }
if ($vm) {
    $info.running = $vm.State -eq 'Running'
    if ($info.running) {
        try {
            $g = Invoke-Command -VMName $vm.Name -Credential $credential -ArgumentList $subnetPrefix -ScriptBlock $guestProbe -ErrorAction Stop
            $info.natIp          = $g.natIp
            $info.interfaceAlias = $g.interfaceAlias
            $info.proxyAddress   = $g.proxyAddress
        } catch { }
    }
}
$info | ConvertTo-Json -Depth 4
