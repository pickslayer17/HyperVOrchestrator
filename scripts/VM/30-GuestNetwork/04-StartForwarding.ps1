$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$vmIp                 = "@@state.vm.ip@@"
$vmHostRdpForwardPort = @@state.vm.hostRdpForwardPort@@
$vmRdpPort            = @@state.vm.rdpPort@@

& python "$serverScript" AddMachine -vmip $vmIp
& python "$serverScript" Set-ForwardPort -vmip $vmIp -portadress $vmHostRdpForwardPort -targetport $vmRdpPort
Write-Host "$vmIp registered: forward $vmHostRdpForwardPort -> ${vmIp}:$vmRdpPort."
