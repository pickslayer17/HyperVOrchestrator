$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$dnsServer = "@@network.dnsServer@@"
$socksPort = "@@network.singboxSocksPort@@"
$hostIp    = "@@network.defaultNatHostIp@@"
$guestDir  = "@@paths.guestSingboxDir@@"
$logPath   = (Join-Path $guestDir "sing-box.log") -replace '\\','/'
$exePath   = Join-Path $guestDir "sing-box.exe"
$configPath = Join-Path $guestDir "config.json"

$config = @"
{
  "log": {
    "level": "info",
    "output": "$logPath"
  },
  "dns": {
    "servers": [
      { "type": "udp", "tag": "remote", "server": "$dnsServer", "detour": "socks-out" }
    ],
    "strategy": "ipv4_only"
  },
  "route": {
    "rules": [
      { "action": "hijack-dns", "port": 53 }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "address": ["172.19.0.1/30"],
      "auto_route": true,
      "strict_route": true,
      "stack": "gvisor"
    }
  ],
  "outbounds": [
    {
      "type": "socks",
      "tag": "socks-out",
      "server": "$hostIp",
      "server_port": $socksPort,
      "version": "5"
    }
  ]
}
"@

[System.IO.File]::WriteAllText($configPath, $config, (New-Object System.Text.UTF8Encoding($false)))

& $exePath check -c $configPath
if ($LASTEXITCODE -ne 0) { throw "sing-box config check failed with exit $LASTEXITCODE" }
Write-Host "config.json written and validated."
