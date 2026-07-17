$ScriptTarget = "VM"
$RootPriviledges = $true
$ErrorActionPreference = "Stop"

$guestDir   = "@@paths.guestSingboxDir@@"
$exePath    = Join-Path $guestDir "sing-box.exe"
$configPath = Join-Path $guestDir "config.json"

Get-Process sing-box -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $exePath
$psi.Arguments = "run -c `"$configPath`""
$psi.WorkingDirectory = $guestDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
[System.Diagnostics.Process]::Start($psi) | Out-Null

Start-Sleep -Seconds 3
$proc = Get-Process sing-box -ErrorAction SilentlyContinue
if (-not $proc) { throw "sing-box did not start." }

New-Item -ItemType File -Path (Join-Path $guestDir ".singbox") -Force | Out-Null
Write-Host "sing-box started detached (pid $($proc.Id))."
