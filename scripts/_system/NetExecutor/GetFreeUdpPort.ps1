$ErrorActionPreference = "Stop"

$client = [System.Net.Sockets.UdpClient]::new(0)
$port = $client.Client.LocalEndPoint.Port
$client.Dispose()
"$port"
