param(
    [string]$BindIp,
    [int]$ListenPort,
    [string]$TargetIp,
    [int]$TargetPort
)
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" start_fwd -ip $BindIp -port $ListenPort -targetip $TargetIp -targetport $TargetPort
exit $LASTEXITCODE
