$ScriptTarget = "Host"
$ErrorActionPreference = "Stop"

$vmName     = "@@state.vm.name@@"
$vmUser     = "@@credentials.user@@"
$vmPassword = "@@credentials.password@@"
$binDir     = "@@paths.singboxArtifacts@@"
$exeSource  = Join-Path $binDir "sing-box.exe"
$dllSource  = Join-Path $binDir "wintun.dll"

if (-not (Test-Path $exeSource)) { throw "sing-box.exe not found: $exeSource" }
if (-not (Test-Path $dllSource)) { throw "wintun.dll not found: $dllSource" }

$credential = New-Object System.Management.Automation.PSCredential($vmUser, (ConvertTo-SecureString $vmPassword -AsPlainText -Force))
$session = New-PSSession -VMName $vmName -Credential $credential

$guestDir = "@@paths.guestSingboxDir@@"
Invoke-Command -Session $session -ArgumentList $guestDir -ScriptBlock { param($d) New-Item -ItemType Directory -Path $d -Force | Out-Null }
Copy-Item -ToSession $session -Path $exeSource -Destination (Join-Path $guestDir "sing-box.exe") -Force
Copy-Item -ToSession $session -Path $dllSource -Destination (Join-Path $guestDir "wintun.dll") -Force

Remove-PSSession $session
Write-Host "sing-box.exe + wintun.dll copied to $guestDir."
