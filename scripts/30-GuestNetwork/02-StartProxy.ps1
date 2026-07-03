# ensure python proxy agent on host, register this vm

$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$server    = "@@paths.pythonServer@@"
$hostIp    = "@@state.hostIp@@"
$proxyPort = @@state.proxyPort@@
$vmIp      = "@@state.vmIp@@"
$fwdPort   = @@state.rdpForwardPort@@
$rdpPort   = @@network.rdpPort@@

function Test-AgentPipe {
    [bool](([System.IO.Directory]::GetFiles("\\.\pipe\")) -match 'hyperv-netagent')
}

# ensure singleton server
if (Test-AgentPipe) {
    Write-Host "proxy server already running."
} else {
    Start-Process -FilePath "python" -WindowStyle Hidden `
        -ArgumentList "`"$server`"", "Start-Proxy", "-ip", $hostIp, "-port", $proxyPort
    $deadline = (Get-Date).AddSeconds(15)
    while (-not (Test-AgentPipe) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 200 }
    if (-not (Test-AgentPipe)) { throw "proxy server did not start (no pipe)" }
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
