$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
$vmIp                 = "@@state.vm.ip@@"
$vmHostRdpForwardPort = @@state.vm.hostRdpForwardPort@@
$vmRdpPort            = @@state.vm.rdpInPort@@

& python "$serverScript" add_machine -vmip $vmIp
& python "$serverScript" set_forward_port -vmip $vmIp -portadress $vmHostRdpForwardPort -targetport $vmRdpPort
Write-Host "$vmIp registered: forward $vmHostRdpForwardPort -> ${vmIp}:$vmRdpPort."
