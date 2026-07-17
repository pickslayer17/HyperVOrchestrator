$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$proc = Get-Process sing-box -ErrorAction SilentlyContinue
if ((Test-Path (Join-Path "@@paths.guestSingboxDir@@" ".singbox")) -and $proc) {
    Write-Host "sing-box already running."
    exit 2
}
Write-Host "sing-box not running."
exit 0
