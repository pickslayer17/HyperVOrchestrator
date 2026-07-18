param(
	[string]$Ip,
	[int]$Port
)
$ErrorActionPreference = "Stop"

$serverScript = "@@paths.pythonServer@@"
& python "$serverScript" start_dns -ip $Ip -port $Port
exit $LASTEXITCODE
