$ScriptTarget = "@@state.executor.target@@"
$ErrorActionPreference = "Stop"

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 0)
$listener.Start()
$port = $listener.LocalEndpoint.Port
$listener.Stop()
"$port"
