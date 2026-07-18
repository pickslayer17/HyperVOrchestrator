$RootPriviledges = $true
$ErrorActionPreference = "Stop"

$guestDir = "@@paths.guestSingboxDir@@"
$exePath = Join-Path $guestDir "sing-box.exe"
$configPath = Join-Path $guestDir "config.json"
if (-not (Test-Path $exePath)) { throw "sing-box.exe not found: $exePath. Run Setup VM first." }
if (-not (Test-Path $configPath)) { throw "SingBox config not found: $configPath." }

Get-Process sing-box -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exePath
$psi.Arguments = "run -c `"$configPath`""
$psi.WorkingDirectory = $guestDir
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
[Diagnostics.Process]::Start($psi) | Out-Null

Start-Sleep -Seconds 3
if (-not (Get-Process sing-box -ErrorAction SilentlyContinue)) { throw "sing-box did not start." }
