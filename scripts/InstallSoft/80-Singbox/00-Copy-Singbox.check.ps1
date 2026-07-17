$ScriptTarget = "VM"
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestSingboxDir@@"
if ((Test-Path (Join-Path $guestDir "sing-box.exe")) -and (Test-Path (Join-Path $guestDir "wintun.dll"))) {
    Write-Host "sing-box binaries already on VM."
    exit 2
}
Write-Host "sing-box binaries not on VM."
exit 0
