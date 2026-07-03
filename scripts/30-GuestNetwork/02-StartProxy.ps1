# ensure python proxy agent on host, register this vm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$server    = "@@paths.pythonServer@@"
$hostIp    = "@@state.hostIp@@"
$proxyPort = @@state.proxyPort@@
$vmIp      = "@@state.vmIp@@"
$fwdPort   = @@state.rdpForwardPort@@
$rdpPort   = @@network.rdpPort@@

function Test-AgentLive {
    & python "$server" GetMachineNames > $null 2>&1
    return ($LASTEXITCODE -eq 0)
}

# ensure singleton server (server self-detaches; Start-Proxy waits until live)
if (Test-AgentLive) {
    Write-Host "proxy server already running."
} else {
    & python "$server" Start-Proxy -ip $hostIp -port $proxyPort
    if (-not (Test-AgentLive)) { throw "proxy server did not start" }
    Write-Host "proxy server started."
}

# register this vm if not present
$names = & python "$server" GetMachineNames
if ($names -contains $vmIp) {
    Write-Host "$vmIp already registered."
} else {
    & python "$server" AddMachine -vmip $vmIp
    & python "$server" Set-ForwardPort -vmip $vmIp -portadress $fwdPort -targetport $rdpPort
    Write-Host "$vmIp registered: proxy + forward $fwdPort -> ${vmIp}:$rdpPort."
}
