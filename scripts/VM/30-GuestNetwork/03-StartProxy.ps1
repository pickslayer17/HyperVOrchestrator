$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$hostIp    = "@@state.host.natIp@@"
$proxyPort = @@state.host.proxyPort@@

& python "$serverScript" Start-Proxy -ip $hostIp -port $proxyPort
& python "$serverScript" GetMachineNames > $null 2>&1
if ($LASTEXITCODE -ne 0) { throw "proxy server did not start" }
Write-Host "proxy server started on ${hostIp}:$proxyPort."
