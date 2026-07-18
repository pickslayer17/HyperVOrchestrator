$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestSingboxDir@@"
$configPath = Join-Path $guestDir "config.json"
if (-not (Test-Path $configPath)) {
	[pscustomobject]@{ proxyAddress = ""; dnsAddress = ""; running = $false } | ConvertTo-Json -Compress
	exit 0
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$proxy = $config.outbounds | Where-Object { $_.type -eq "socks" } | Select-Object -First 1
$dns = $config.dns.servers | Select-Object -First 1
if (-not $proxy -or -not $proxy.server -or -not $proxy.server_port) { throw "SingBox SOCKS outbound is missing or invalid." }
if (-not $dns -or -not $dns.server -or -not $dns.server_port) { throw "SingBox DNS server is missing or invalid." }

[pscustomobject]@{
	proxyAddress = "$($proxy.server):$($proxy.server_port)"
	dnsAddress = "$($dns.server):$($dns.server_port)"
	running = [bool](Get-Process sing-box -ErrorAction SilentlyContinue)
} | ConvertTo-Json -Compress
