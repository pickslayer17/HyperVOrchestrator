# pick free vm ip in subnet -> state

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$octets = "@@state.hostIp@@".Split('.')
$base = "$($octets[0]).$($octets[1]).$($octets[2])."

$vmIp = $null
foreach ($n in 2..254) {
    $candidate = "$base$n"
    if (-not (Test-Connection -ComputerName $candidate -Count 1 -Quiet)) {
        $vmIp = $candidate
        break
    }
}
if (-not $vmIp) { Write-Host "No free IP in subnet ${base}0/24."; exit 1 }

Write-Host "::set state.vmIp=$vmIp"
Write-Host "Free VM IP picked: $vmIp"
exit 0
