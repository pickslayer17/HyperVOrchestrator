param(
	[string]$HostIp,
	[int]$SocksPort,
	[int]$DnsPort,
	[string]$Template
)
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestSingboxDir@@"
$exePath = Join-Path $guestDir "sing-box.exe"
$configPath = Join-Path $guestDir "config.json"
if (-not (Test-Path $exePath)) { throw "sing-box.exe not found: $exePath. Run Setup VM first." }

$logPath = (Join-Path $guestDir "sing-box.log") -replace '\\','/'
$config = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Template))
$config = $config.Replace("{{HOST_IP}}", $HostIp).Replace('"{{SOCKS_PORT}}"', "$SocksPort").Replace('"{{DNS_PORT}}"', "$DnsPort").Replace("{{LOG_PATH}}", $logPath)
$existing = if (Test-Path $configPath) { [IO.File]::ReadAllText($configPath) } else { $null }
if ($existing -cne $config) {
	[IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
}

& $exePath check -c $configPath
if ($LASTEXITCODE -ne 0) { throw "sing-box config check failed with exit $LASTEXITCODE" }
