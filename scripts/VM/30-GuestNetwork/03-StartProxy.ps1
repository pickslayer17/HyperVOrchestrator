# ensure python proxy agent on host, register this vm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$hostIp    = "@@state.host.natIp@@"
$proxyPort = @@state.host.proxyPort@@
$vmIp      = "@@state.vm.ip@@"
$vmHostRdpForwardPort = @@state.vm.hostRdpForwardPort@@
$vmRdpPort            = @@state.vm.rdpPort@@

function Test-AgentLive {
    & python "$serverScript" GetMachineNames > $null 2>&1
    return ($LASTEXITCODE -eq 0)
}

# ensure singleton server (server self-detaches; Start-Proxy waits until live)
if (Test-AgentLive) {
    Write-Host "proxy server already running."
} else {
    & python "$serverScript" Start-Proxy -ip $hostIp -port $proxyPort
    if (-not (Test-AgentLive)) { throw "proxy server did not start" }
    Write-Host "proxy server started."
}

# register this vm if not present
$machineNames = & python "$serverScript" GetMachineNames
if ($machineNames -contains $vmIp) {
    Write-Host "$vmIp already registered."
} else {
    & python "$serverScript" AddMachine -vmip $vmIp
    & python "$serverScript" Set-ForwardPort -vmip $vmIp -portadress $vmHostRdpForwardPort -targetport $vmRdpPort
    Write-Host "$vmIp registered: proxy + forward $vmHostRdpForwardPort -> ${vmIp}:$vmRdpPort."
}
