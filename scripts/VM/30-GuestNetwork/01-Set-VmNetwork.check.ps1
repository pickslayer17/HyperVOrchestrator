# pick free vm ip from real picture (hyper-v, not ping) -> state

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName = "@@state.vm.name@@"
$hostIp = "@@state.host.natIp@@"
$octets = $hostIp.Split('.')
$subnetPrefix = "$($octets[0]).$($octets[1]).$($octets[2])."

# picture: ips already reported by other vms + host gateway
$takenIps = @($hostIp)
Get-VMNetworkAdapter -VMName * -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.VMName -ne $vmName) {
        foreach ($ip in $_.IPAddresses) {
            if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$') { $takenIps += $ip }
        }
    }
}

# keep our vm's ip if it's already unique in-subnet, else pick first free
$ourAdapter = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
$vmIp = @($ourAdapter.IPAddresses |
    Where-Object { $_ -like "$subnetPrefix*" -and $takenIps -notcontains $_ }) | Select-Object -First 1

if (-not $vmIp) {
    foreach ($lastOctet in 2..254) {
        $candidate = "$subnetPrefix$lastOctet"
        if ($takenIps -notcontains $candidate) { $vmIp = $candidate; break }
    }
}
if (-not $vmIp) { Write-Host "No free IP in subnet ${subnetPrefix}0/24."; exit 1 }

Write-Host "<<set::state.vm.ip=$vmIp>>"
Write-Host "VM IP: $vmIp (taken: $($takenIps -join ', '))"
exit 0
