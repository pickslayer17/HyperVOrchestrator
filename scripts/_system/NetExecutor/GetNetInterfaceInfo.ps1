# host: guest nat interface -> json { isDynamic, alias, ip }
# read over PSDirect; empty if the VM is off or unreachable.
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
    $adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    $alias = $adapter.Name
    $ipObj = $null
    if ($subnetPrefix) {
        $ipObj = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -like "$subnetPrefix*" } | Select-Object -First 1
    }
    $ip = if ($ipObj) { $ipObj.IPAddress } else { "" }
    $isDynamic = if ($ipObj) { $ipObj.PrefixOrigin -eq 'Dhcp' } else { $false }
    [pscustomobject]@{ isDynamic = $isDynamic; alias = "$alias"; ip = "$ip" }
}

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
$info = @{ isDynamic = $false; alias = ""; ip = "" }
if ($vm -and $vm.State -eq 'Running') {
    try {
        $g = Invoke-Command -VMName $vm.Name -Credential $credential -ArgumentList $subnetPrefix -ScriptBlock $guestProbe -ErrorAction Stop
        $info.isDynamic = $g.isDynamic
        $info.alias     = $g.alias
        $info.ip        = $g.ip
    } catch { }
}
$info | ConvertTo-Json -Depth 4
